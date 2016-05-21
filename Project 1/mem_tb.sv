module tb_memory;
	logic clk, read, busy, en;
	logic [31:0] addr, din, dout;
	logic [1:0] size;

    memory #(.benchmark("BubbleSort.x"), .depth(2**20)) mem(.clk(clk),
		.addr(addr), .data_in(din), .data_out(dout),
		.access_size(size), .rd_wr(read), .busy(busy), .enable(en));

    initial $monitor("time %3d, addr %8h, data %8h, busy %1b", $time, addr,
		dout, busy);
 
    initial begin
        clk = 0; forever #5 clk = ~clk;
    end

    initial begin
        addr = 32'h80020000; 
	size = 0; 
	read = 1; 
	en = 0;

	#10 en = 1;

	// data_out should not change here
	// as enable is set to 0
	#10 begin 
		en = 0; 
		addr = addr + 4;
	end

	// Make sure that reading pauses when
	// en is deasserted
	#10 begin
		addr = addr - 4;
		en = 1;
		size = 1;
	end
	#20 en = 0; // reading should pause
	#20 en = 1; // reading should continue

	// Make sure that changing address
	// while read doesnt affect currently
	// reading output
	// #20
	#40 addr = addr + 4;
	
	// Attempting a write during a read should
	// do nothing
	#20 addr = addr - 4;
	#10 begin
		addr = addr + 12;
		din = 'hdeaddead;
		read = 0;
	end
 	#35 $stop;  
    end

endmodule
