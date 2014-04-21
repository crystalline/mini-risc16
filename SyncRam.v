//`include "CoreHeader.v"

/*Synchronous RAM module for simulation
**Note that it has Verilog-1993-style port declaration,
**as Aldec AHDL v7.2 didn't parse parameters with 2001-style declaration
**(though icarus verilog did)
*/
module SyncRam(
	//Clock and WriteFlag
	gclk,
	WriteEnable,
	//Adress/Data register
	ReadAddr,
	WriteAddr,
	WriteData,
	ReadData
);	
	input wire gclk;
	input wire WriteEnable;

	parameter WORD_WIDTH = 8;
	parameter ADDR_WIDTH = 8;
	`define RAM_DEPTH (1 << ADDR_WIDTH)
	
	input wire	[ ADDR_WIDTH-1:0 ] ReadAddr;
	input wire	[ ADDR_WIDTH-1:0 ] WriteAddr;
	input wire	[ WORD_WIDTH-1:0 ] WriteData;
	output reg	[ WORD_WIDTH-1:0 ] ReadData;
	
	reg [ ADDR_WIDTH-1:0 ] TempReadAddr;
	
	//Actual variable containing memory array
	reg [ WORD_WIDTH-1:0 ] data [ 0:`RAM_DEPTH ];
	
	//Syncronous read/write
	always @( posedge gclk ) begin
		//Read data every clock
		//TempReadAddr <= ReadAddr;
		ReadData <= data[ ReadAddr ];
		//Write data only if WriteEnable flag is set
		if (WriteEnable) data[ WriteAddr ] <= WriteData;
	end
	
	//assign ReadData = data[ TempReadAddr ];
	
endmodule
