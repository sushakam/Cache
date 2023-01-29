`include "rtl/Cache.sv"



module Cache_tb;

	logic clock;
	logic reset;
	logic [31:0] address;
	logic hit;
	logic search_cache;
	logic search_done;
	logic [63:0] cache_data_out;
	logic [26:0] tag_out;

	
	/* Fake main memory */
	parameter address_count=512*(2**10);
	logic [31:0] RAM [address_count];	//Technically supports up to 2GB. Obviously cannot allocate an arr that big
	logic [63:0] main_memory_data;	//Output wire to cache
	logic [31:0] RAM_address;		


	task generate_cache_request(int tag, int set, int block);
		address<=((tag<<14) | (set<<5) | (block<<3));
		search_cache<=1'b1;	//Start cache search
		$write("Requesting cache from Tag: %0d, Set: %0d, Block: %0d ", 0, 0, 1);
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		@(posedge search_done);	//wait for cache...
		$display("Hit: %0d", hit);
		//$display("Address: %0d, Tag: %0d, Data: %0d, hit: %0d\n\n", address, Cache.tag[Cache.request_set],
		//		 Cache.cache[Cache.request_set][0][Cache.request_block], hit);
	 endtask

	Cache Cache(.clock(clock), .reset(reset), .search_cache(search_cache),
				.address(address), .main_memory_data(main_memory_data), .hit(hit), 
				.search_done(search_done), .data(cache_data_out), .RAM_address(RAM_address)
				);

    initial begin
        $dumpfile("vcdDumpFiles/cache.vcd");
        $dumpvars;
    end

	/*initialize 512 MB RAM*/
	initial begin
		for(integer i = 0; i < address_count; i=i+1) begin
			RAM[i]=i;
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

		
		$display("\nCache conatins 512 lines. Each line contains 4 words.");
		$display("With 8 ways, the cache totals 512*4*8 words.");
		$display("Below are a few hardcoded testcases that demonstrate functionality\n\n");



		repeat (15) @(posedge clock);	//wait for resets, inits, etc...


		/*********EXAMPLE HITS AND MISSES************/

		generate_cache_request(1,1,1);

		generate_cache_request(1,1,1);


	
	end

endmodule
