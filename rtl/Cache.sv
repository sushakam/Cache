// An 8-way set-associate test cache. 
// By Hakam Atassi, for the Mac-Risc-V team.


/*			Specifications
	*	
	*	Cache Size = 64 kB
	*	Set size = 8
	*	Block size = 16 bytes
	*	Word size = 64 bits
	*
	*		Therefore: 
	*	Lines = 512 lines
	*	Since 512 lines * 8 ways (blocks per line) * 4 words per block * 4 bytes per word = 64kB of data
	*	
*/


module Cache(
	input clock,
	input reset,
	input search_cache,
	input [31:0] address,
	input [63:0] main_memory_data,
	output logic hit,
	output logic search_done,
	output logic [63:0] data,
	output logic [26:0] tag_out,	//TODO: wrong size
	output logic [63:0] RAM_address

);


parameter word_size=64;	//64 bit words
parameter block_size=4;	//4 words per block
parameter cache_capacity = 64*2^10;	//
parameter ways = 8;
parameter line_count = 512; 



initial begin
	$display("\nCache running!\n");
end



logic valid[line_count:0];
logic [26:0] tag[line_count:0];
logic [word_size] cache[line_count:0][ways-1:0][block_size];

logic [63:0] cache_line_word_buf [3:0];
logic [63:0] RAM_address_buffer;

enum logic [3:0] {
	CACHE_IDLE,
	CACHE_CHECK_TAGS,
	CACHE_READ_DONE,
	CACHE_MISS_READ_MEM,
	CACHE_MISS_WRITE_BLOCK0,
	CACHE_MISS_WRITE_BLOCK1,
	CACHE_MISS_WRITE_BLOCK2,
	CACHE_MISS_WRITE_BLOCK3
} CACHE_STATE;


assign block_offset=address[1:0];

//logic for determining if address is a hit
always_ff @(posedge clock, negedge reset) begin
		
	if(reset==1'b0) begin
		hit<=1'b0;
		search_done<=1'b0;
		RAM_address_buffer<=63'd0;
		CACHE_STATE<=CACHE_IDLE;
	end else begin
		
		case(CACHE_STATE)

			CACHE_IDLE: begin	//0
				if(search_cache==1'b1) begin
					CACHE_STATE<=CACHE_CHECK_TAGS;
				end else begin
					CACHE_STATE<=CACHE_IDLE;
				end
				
				search_done<=1'b0;
			end

			CACHE_CHECK_TAGS: begin	//1
				hit<=1'b0;
				for(integer i = 0; i < line_count; i=i+1) begin
					if((tag[i]>>3) == (address[26:0]>>3)) begin
						hit<=1'b1;
						data<=cache[address>>3][0][block_offset];
					end
				end

				CACHE_STATE<=CACHE_READ_DONE;
			end

			CACHE_READ_DONE: begin	//2

				if(hit==1'b1) begin	//Cache hit. Go back to idle.
					hit<=1'b0;
					search_done<=1'b1;
					CACHE_STATE<=CACHE_IDLE;
				end else begin	//Cache miss. Fetch block from main memory. Use replacement policy (Random) 
					CACHE_STATE<=CACHE_MISS_READ_MEM;
				end
			end




			//Write back to memory using hash function
			//Set = address % 
			/*****Handle a Cache miss write back******/

			CACHE_MISS_READ_MEM: begin	//3
				//Set the main memory address to the address the CPU is 
				//requesting from the cache

				RAM_address<=address;
				RAM_address_buffer<=address;
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK0;
			end

			CACHE_MISS_WRITE_BLOCK0: begin	//4
				
				RAM_address<=RAM_address+32'd1;
				
				cache_line_word_buf[2]<=main_memory_data;

				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK1;

			end

			CACHE_MISS_WRITE_BLOCK1: begin	//5
				
				RAM_address<=RAM_address+32'd1;

				cache_line_word_buf[1]<=main_memory_data;
				
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK2;

			end

			CACHE_MISS_WRITE_BLOCK2: begin	//6
				
				RAM_address<=RAM_address+32'd1;
				
				cache_line_word_buf[0]<=main_memory_data;

				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK3;

			end

			CACHE_MISS_WRITE_BLOCK3: begin	//7
				
				
				cache[RAM_address_buffer>>3][0][0]<=cache_line_word_buf[2];
				cache[RAM_address_buffer>>3][0][1]<=cache_line_word_buf[1];
				cache[RAM_address_buffer>>3][0][2]<=cache_line_word_buf[0];
				cache[RAM_address_buffer>>3][0][3]<=main_memory_data;

				tag[RAM_address_buffer>>3]<=RAM_address_buffer[26:0];

				search_done<=1'b1;
				CACHE_STATE<=CACHE_IDLE;

			end

			/****************************************/

			
		endcase
	end
end




always_ff @ (posedge clock, negedge reset) begin

	if(reset==1'b0) begin

		for(integer i = 0; i<line_count; i=i+1) begin
			//init with mem skipping by 2s
			valid[i]<=1'b0;
			tag[i]<=27'd0;
			cache[i][0][3]<=27'd0;
			cache[i][0][2]<=27'd0;
			cache[i][0][1]<=27'd0;
			cache[i][0][0]<=27'd0;
		end

	end else begin

		//data<=cache[address][0];
		tag_out<=tag[address];

	end
end







	


endmodule
