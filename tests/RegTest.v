// File        : RegTest.v
// Generated   : Sat Dec  5 18:13:57 2009
// By          : Itf2Vhdl ver. 1.21
//Simple clock generator (Debug only, non-synthsible)
`timescale 10ns/100ps

`include "../CoreHeader.v"

`define DELAY 1
module ClockGen( output reg clk);
	initial begin
		clk <= 0;
	end
	always begin
		#`DELAY clk <= ~clk;
	end
endmodule

module RegTestBench();
	//Register file wires.
	reg  RFWriteFlag;
	reg	 [ `REG_ADDR_WIDTH-1:0 ]	RF_AddrReadA; //Adress Read A.
	reg  [ `REG_ADDR_WIDTH-1:0 ]	RF_AddrReadB; //Adress Read B.
	reg  [ `REG_ADDR_WIDTH-1:0 ]	RF_AddrWrite; //Write adress.
	wire [ `WORD_WIDTH-1:0 ]		RF_ReadA; //Read output A (asyncronous).
	wire [ `WORD_WIDTH-1:0 ]		RF_ReadB; //Read output B (asyncronous).
	reg  [ `WORD_WIDTH-1:0 ]		RF_Write; //Data to write, input.	 
	
	ClockGen clk( .clk(gclk) ); //Clock generator
	
	//Register file	
	RegFile RF(
		.gclk( gclk ),
		.PowerOn( PowerOn ),
		.AddrReadA( RF_AddrReadA ),
		.AddrReadB( RF_AddrReadB ),
		
		.AddrWrite( RF_AddrWrite ),
		.ReadA( RF_ReadA ),
		.ReadB( RF_ReadB ),
		.Write( RF_Write )
	);
	
	initial begin
		RF_Write <= 16'hFFFF;
		RF_AddrWrite <= 1;
		#2
		RF_AddrReadA <= 1;
		#2
		RF_AddrReadA <= 1;
		#2
		$finish;
	end
endmodule
