module memory_32bit(output reg busy, output reg [31:0] data_out, input wire clk, read_write, enable, input wire [1:0] access_size, input wire [31:0] data_in, address);

	logic [31:0] memory [0:1048575];

	always_ff @ (posedge clk) 
	begin : MEM_READ
		if (enable == 1) begin
			case (read_write)
				0 : memory[address] = data_in;
				1 : data_out =  memory[address];
			endcase
		
			busy = 1;
		end
		else 
			busy = 0;
	end
endmodule

