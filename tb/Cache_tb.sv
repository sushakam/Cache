// Cache.sv Testbench

`include "rtl/Cache.sv"



module Cache_tb;

	logic clock;
	logic reset;
	logic [31:0] address;
	logic hit;
	logic search_cache;
	logic search_done;
	logic [63:0] data;
	logic [27:0] tag_out;

	Cache Cache(.clock(clock), .reset(reset), .search_cache(search_cache),
				.address(address), .hit(hit), .search_done(search_done), 
				.data(data), .tag_out(tag_out));


    initial begin
        $dumpfile("vcdDumpFiles/cache.vcd");
        $dumpvars;
    end


	initial begin
		$display("\nTestbench running!\n");
		$display("Triggering reset...");
		reset<=1'b1;
		address<=32'b0;


		@(posedge clock);
		reset<=1'b0;
		@(posedge clock);
		reset<=1'b1;
	end

	always begin
		clock<=1'b1; #1; 
		clock<=1'b0; #1;
	end
	

	always begin
		repeat (1500) @(posedge clock);
		$finish;
	end


	initial begin
	
			
		$display("\n\nCache is \"warmed\" with tags from 0->512 and data that is the square of the tag.");
		$display("ie: cache line 0 will contain Tag=0, Data=0*0=0");
		$display("    cache line 255 will contain Tag=255, Data=255*255=65025");
		$display("    cache line 1023 will miss, since it is not in memory (max tag is 511)\n");
		$display("    Note: each cache line actually contains words. The 4 words (64 bits each) are treated as one long word here.\n\n");



		repeat (15) @(posedge clock);	//wait for resets, inits, etc...
		/*********EXAMPLE HITS AND MISSES************/


		/**HIT (fetch address=0)**/
		search_cache<=1'b1;
		address<=32'd0;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, data, hit);
		


		/**HIT (fetch address=255)**/
		search_cache<=1'b1;
		address<=32'd255;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, data, hit);


		/**HIT (fetch address=511)**/
		search_cache<=1'b1;
		address<=32'd511;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, data, hit);

		/**MISS (fetch address=1024) **/
		search_cache<=1'b1;
		address<=32'd1023;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, data, hit);

	end


endmodule
