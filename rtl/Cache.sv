////////////////////////////////////////////////////////////////////////
//================= An 8-way set-associative cache====================//
//  __  __                    ____    _                               //
// |  \/  |   __ _    ___    |  _ \  (_)  ___    ___          __   __ //
// | |\/| |  / _` |  / __|   | |_) | | | / __|  / __|  _____  \ \ / / //
// | |  | | | (_| | | (__    |  _ <  | | \__ \ | (__  |_____|  \ V /  //
// |_|  |_|  \__,_|  \___|   |_| \_\ |_| |___/  \___|           \_/   //
//====================================================================//                                                                 
////////////////////////////////////////////////////////////////////////


/*		Specifications
	*
	*	Main Memory Size = 2 GB 
	*	
	*	Cache Size = 64 kB
	*	Set size = 8
	*	Block size = 16 bytes
	*	Word size = 64 bits
	*
	*	Therefore: 
	*	Lines = 512 lines
	*	Since 512 lines * 8 ways (blocks per line) * 4 words per block * 4 bytes per word = 64kB of data
	*	
*/



module Cache(
	input clock,
	input reset,
	input search_cache,				//Flag to leave idle and search memory
	input [31:0] address,		
	input [63:0] main_memory_data,	//Input from main memory 
	output logic hit,
	output logic search_done,		//Flag indicating completion of cache search. Data is ready when high	TODO: rename to data_ready
	output logic [63:0] data,
	output logic [31:0] RAM_address	

);

initial
	$display("\nCache running!\n");


//===========Configurable Parameters==============//
parameter word_size=64;	//64 bit words			  //
parameter block_size=4;	//4 words per block		  //
parameter cache_capacity = 64*2^10;				  //
parameter ways = 8;								  //
parameter line_count = 512; 					  //
//================================================//


//================================Cache declaration===============================//
logic valid[line_count:0][ways-1:0];							//Valid bit 	  //
logic [26:0] tag[line_count-1:0];								//Block tag 	  //
logic [word_size] cache[line_count:0][ways-1:0][block_size];	//Data array	  //
//================================================================================//


//=====================================Helpful Regs===============================//
logic [63:0] cache_line_word_buf [3:0];		//Used when writing block to cache	  //
logic [63:0] RAM_address_buffer;			//used for updating tag after fetch   //
//================================================================================//



//===================================Cache addressing====================================//
logic [2:0] request_byte_offset;								//TODO: remove/fix		 //
assign request_byte_offset = address[2:0];												 //
																						 //
logic [1:0] request_block;																 //
assign request_block = address[4:3];													 //
																						 //
logic [7:0] request_set;																 //
assign request_set = address[13:5];														 //
																						 //
logic [17:0] request_tag;																 //
assign request_tag = address[31:14]; 													 //
																						 //
//	Address: 0000.0000 0000.0000 0000.0000 0000.0000									 //
//	                                             000 => Byte offset (8 bytes per word)   //
//	                                          0.0___ => Block (block size of 4)			 //
//	                               00.0000 000_.____ => Set (512 lines in the cache)     //
//	         0000.0000 0000.0000 00__.____ ____.____ => Tag                      		 //
//=======================================================================================//

assign block_offset=address[1:0];	



enum logic [3:0] {
	CACHE_IDLE,
	CACHE_CHECK_TAGS,
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
		RAM_address<=32'd0;
		RAM_address_buffer<=63'd0;
		CACHE_STATE<=CACHE_IDLE;
	end else begin
		
		case(CACHE_STATE)

			//State 0
			CACHE_IDLE: begin	
				//Wait for cache request
				
				if(search_cache==1'b1) begin
					CACHE_STATE<=CACHE_CHECK_TAGS;
				end else begin
					CACHE_STATE<=CACHE_IDLE;
				end
				hit<=1'b0;
				search_done<=1'b0;
			end

			//State 1
			CACHE_CHECK_TAGS: begin	
				//Check cache for data
				if(tag[request_set] == request_tag && valid[request_set][0]==1'b1) begin	//Check if the tag exists in the cache
					data<=cache[request_set][0][request_block];
					hit<=1'b1;
					search_done<=1'b1;
					CACHE_STATE<=CACHE_IDLE;
				end else
					CACHE_STATE<=CACHE_MISS_READ_MEM;
			end

			
			/*****Handle a cache miss******/
			//State 2
			CACHE_MISS_READ_MEM: begin
				//Set the main memory address to the address the CPU is 
				//requesting from the cache
				RAM_address<=address;
				RAM_address_buffer<=address;	//Save initial address for later
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK0;
			end

			//State 3
			CACHE_MISS_WRITE_BLOCK0: begin
				RAM_address<=RAM_address+32'd1;
				cache_line_word_buf[2]<=main_memory_data;
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK1;

			end

			//State 4
			CACHE_MISS_WRITE_BLOCK1: begin
				RAM_address<=RAM_address+32'd1;
				cache_line_word_buf[1]<=main_memory_data;
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK2;

			end

			//State 5
			CACHE_MISS_WRITE_BLOCK2: begin
				RAM_address<=RAM_address+32'd1;
				cache_line_word_buf[0]<=main_memory_data;
				CACHE_STATE<=CACHE_MISS_WRITE_BLOCK3;

			end

			//State 6
			CACHE_MISS_WRITE_BLOCK3: begin
				
				cache[request_set][0][0]<=cache_line_word_buf[2];
				cache[request_set][0][1]<=cache_line_word_buf[1];
				cache[request_set][0][2]<=cache_line_word_buf[0];
				cache[request_set][0][3]<=main_memory_data;
				tag[request_set]<=request_tag;
				valid[request_set][0]<=1'b1;

				search_done<=1'b1;
				CACHE_STATE<=CACHE_IDLE;

			end

		endcase
	end
end




always_ff @ (posedge clock, negedge reset) begin

	if(reset==1'b0) begin

		for(integer i = 0; i<line_count; i=i+1) begin
			//init with mem skipping by 2s
			valid[i][0]<=1'b0;
			tag[i]<=27'd0;
			cache[i][0][3]<=27'd0;
			cache[i][0][2]<=27'd0;
			cache[i][0][1]<=27'd0;
			cache[i][0][0]<=27'd0;
		end

	end else begin

		//data<=cache[request_set][0][request_block];

	end
end







	


endmodule
