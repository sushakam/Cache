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


	task generate_cache_read_request(int tag, int set, int block);
		assert(block<=3 && block>=0) else $display("Block size invalid. Only [0,3] allowed, got %0d", block);

		address<=((tag<<11) | (set<<2) | (block));

		search_cache<=1'b1;	//Start cache search
		repeat (1) @(posedge clock);
		search_cache<=1'b0;
		@(posedge data_ready);	//wait for cache...
		$display("Base address for block %0d ",  {address[31:2],2'b0});
		$display("Requesting cache from Tag: %0d, Set: %0d, Block: %0d, Hit: %0d", tag, set, block, hit);

		/*Check request results*/

		//Check correct data is read
		assert(cache_data_out==(address)) else begin
			$display("Error: expected data %0d, got %0d", address+block, cache_data_out);
			$display("Cache line at %0d is %0d %0d %0d %0d", address, Cache.cache[set][0][0], Cache.cache[set][0][1], Cache.cache[set][0][2], Cache.cache[set][0][3]);
		end
		
		//Check that a hit did not occur on invalid block
		if(hit==1'b1) begin
			assert(Cache.valid[Cache.request_set][0]==1) else
				$display("Error: Hit on invalid block V: %0d, tag: %0d, set: %0d, block: %0d\n", Cache.valid[set][0], tag, set, block );
		end

		$display("");
	
	 endtask

	Cache Cache(.clock(clock), .reset(reset), .search_cache(search_cache),
				.address(address), .main_memory_data(main_memory_data), .hit(hit), 
				.data_ready(data_ready), .data(cache_data_out), .RAM_address(RAM_address)
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


		//task generate_cache_request(int tag, int set, int block);
		
		generate_cache_read_request(1,1,1);	//MISS
		generate_cache_read_request(1,1,1);	//HIT

		generate_cache_read_request(0,0,0);	//MISS
		generate_cache_read_request(0,0,0);	//HIT

		generate_cache_read_request(1,1,1);	//HIT
		generate_cache_read_request(1,1,1);	//HIT


		generate_cache_read_request(7,7,0);	//MISS
		generate_cache_read_request(7,7,0);	//HIT
		generate_cache_read_request(7,7,1);	//HIT

		generate_cache_read_request(7,7,2);	//HIT
		generate_cache_read_request(7,7,3);	//HIT

	
	end

endmodule
