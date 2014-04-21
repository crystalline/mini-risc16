//`include "CoreHeader.v"

//Synchronous RAM module for simulation
module SynchRam(
	//Clock and WriteFlag
	input wire	gclk,
	input wire	WriteEnable,
	//Adress/Data register
	input wire	[ `ADDR_WIDTH-1:0 ] ReadAddr,
	input wire	[ `ADDR_WIDTH-1:0 ] WriteAddr,
	input wire	[ `WORD_WIDTH-1:0 ] WriteData,
	output reg	[ `WORD_WIDTH-1:0 ] ReadData
);
	parameter WORD_WIDTH = 8;
	parameter ADDR_WIDTH = 8;
	parameter RAM_DEPTH = 1 << ADDR_WIDTH;
	
	//Actual variable containing memory array
	reg [ WORD_WIDTH-1:0 ] data [ 0:RAM_DEPTH ];
	
	//Syncronous read/write
	always @( posedge gclk ) begin
		//Read data every clock
		ReadData <= data[ ReadAddr ];
		//Write data only if WriteEnable flag is set
		if (WriteEnable) data[ WriteAddr ] <= WriteData;
	end
endmodule
