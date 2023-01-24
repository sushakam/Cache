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
	output logic [27:0] tag_out,	//TODO: wrong size
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
logic [word_size*block_size:0] cache[line_count:0][ways-1:0];

logic [63:0] cache_line_word_buf [3:0];

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

//logic for determining if address is a hit
always_ff @(posedge clock, negedge reset) begin
		
	if(reset==1'b0) begin
		hit<=1'b0;
		search_done<=1'b0;
		CACHE_STATE<=CACHE_IDLE;
	end else begin
		
		case(CACHE_STATE)

			CACHE_IDLE: begin
				if(search_cache==1'b1) begin
					CACHE_STATE<=CACHE_CHECK_TAGS;
				end else begin
					CACHE_STATE<=CACHE_IDLE;
				end
				
				search_done<=1'b0;
			end

			CACHE_CHECK_TAGS: begin
				hit<=1'b0;
				for(integer i = 0; i < line_count; i=i+1) begin
					if(tag[i] == address) begin
						hit<=1'b1;
					end
				end

				CACHE_STATE<=CACHE_READ_DONE;
			end

			CACHE_READ_DONE: begin

				if(hit==1'b1) begin	//Cache hit. Go back to idle.
					hit<=1'b0;
					CACHE_STATE<=CACHE_IDLE;
					search_done<=1'b1;
				end else begin	//Cache miss. Fetch block from main memory. Use replacement policy (Random) 
					CACHE_STATE<=CACHE_MISS_READ_MEM;
				end
			end




			//Write back to memory using hash function
			//Set = address % 
			/*****Handle a Cache miss write back******/

			CACHE_MISS_READ_MEM: begin
				//Set the main memory address to the address the CPU is 
				//requesting from the cache

				RAM_address<=address;
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK0;
			end

			CACHE_MISS_WRITE_BLOCK0: begin
				
				RAM_address<=address+32'd1;
				
				cache_line_word_buf[3]<=main_memory_data;

				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK1;

			end

			CACHE_MISS_WRITE_BLOCK1: begin
				
				RAM_address<=address+32'd1;

				cache_line_word_buf[2]<=main_memory_data;
				
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK2;

			end

			CACHE_MISS_WRITE_BLOCK2: begin
				
				RAM_address<=address+32'd1;
				
				cache_line_word_buf[1]<=main_memory_data;

				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK3;

			end

			CACHE_MISS_WRITE_BLOCK3: begin
				
				cache[main_memory_data>>20][0]<={cache_line_word_buf[3], cache_line_word_buf[2], cache_line_word_buf[1], main_memory_data};
				
				CACHE_STATE<=CACHE_IDLE;

			end
			/****************************************/





			
		endcase
	end
end




always_ff @ (posedge clock, negedge reset) begin

	if(reset==1'b0) begin

		for(integer i = 0; i<line_count; i=i+1) begin
			valid[i]<=1'b0;
			tag[i]<=i[26:0];
			cache[i][0]<=i*i;
		end

	end else begin

		data<=cache[address][0];
		tag_out<=tag[address];

	end
end







	


endmodule
