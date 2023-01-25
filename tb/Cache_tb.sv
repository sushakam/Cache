// Cache.sv Testbench

`include "rtl/Cache.sv"



module Cache_tb;

	logic clock;
	logic reset;
	logic [31:0] address;
	logic hit;
	logic search_cache;
	logic search_done;
	logic [63:0] cache_data_out;
	logic [27:0] tag_out;

	
	/* Fake main memory */
	logic [63:0] RAM [512*(2^20)];
	logic [63:0] RAM_address;
	logic [63:0] main_memory_data;


	Cache Cache(.clock(clock), .reset(reset), .search_cache(search_cache),
				.address(address), .main_memory_data(main_memory_data), .hit(hit), 
				.search_done(search_done), .data(cache_data_out), .tag_out(tag_out), 
				.RAM_address(RAM_address)
				);

    initial begin
        $dumpfile("vcdDumpFiles/cache.vcd");
        $dumpvars;
    end

	/*initialize 4096B RAM*/
	initial begin
		for(integer i = 0; i < 4096; i=i+1) begin
			RAM[i]=i*i;
		end
	end

	/*Assume combinational memory*/
	assign main_memory_data=RAM[RAM_address];


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


	


	/*sample test cases*/
	initial begin
	
			
		$display("\n\nCache is \"warmed\" with tags from 0->511 and data that is the square of the tag.");
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

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, cache_data_out, hit);
		

		/**MISS (Compulsory)**/
		search_cache<=1'b1;
		address<=32'd16;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (8) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, tag_out, cache_data_out, hit);


		/**HIT (Just loaded)**/
		search_cache<=1'b1;
		address<=32'd16;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, Cache.tag[address>>3], cache_data_out, hit);


		/**MISS (Compulsory)**/
		search_cache<=1'b1;
		address<=32'd24;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (8) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, Cache.tag[address>>3], cache_data_out, hit);


		/**HIT (Just loaded)**/
		search_cache<=1'b1;
		address<=32'd24;
		
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		repeat (2) @(posedge clock);	//wait for cache...

		$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d", address, Cache.tag[address>>3], cache_data_out, hit);
	end



endmodule
