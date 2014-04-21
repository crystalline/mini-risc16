//Simple clock generator (Debug only, non-synthsible)
`define DELAY 1
module ClockGen( output reg clk);
	initial begin
		clk <= 1;
	end
	always begin
		#`DELAY clk <= ~clk;
	end
endmodule
