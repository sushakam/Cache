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
	output logic hit,
	output logic search_done,
	output logic [63:0] data,
	output logic [27:0] tag_out

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
logic [word_size*block_size:0] cache[line_count:0];


enum logic [1:0] {
	CACHE_IDLE,
	CACHE_CHECK_TAGS,
	CACHE_DONE
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

				CACHE_STATE<=CACHE_DONE;
			end

			CACHE_DONE: begin
				hit<=1'b0;
				search_done<=1'b1;
				CACHE_STATE<=CACHE_IDLE;
			end

		endcase
	end
end




always_ff @ (posedge clock, negedge reset) begin

	if(reset==1'b0) begin

		for(integer i = 0; i<line_count; i=i+1) begin
			valid[i]<=1'b0;
			tag[i]<=i[26:0];
			cache[i]<=i*i;
		end

	end else begin

		data<=cache[address];
		tag_out<=tag[address];

	end
end







	


endmodule
