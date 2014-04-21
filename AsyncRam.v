//`include "CoreHeader.v"

/*Asynchronous RAM module for simulation, similar in interface with Syncronous RAM
*/
module AsyncRam(
	//WriteFlag
	WriteEnable,
	//Adress/Data register
	ReadAddr,
	WriteAddr,
	WriteData,
	ReadData
);	
	input wire WriteEnable;

	parameter WORD_WIDTH = 8;
	parameter ADDR_WIDTH = 8;
	`define RAM_DEPTH (1 << ADDR_WIDTH)
	
	input wire	[ ADDR_WIDTH-1:0 ] ReadAddr;
	input wire	[ ADDR_WIDTH-1:0 ] WriteAddr;
	input wire	[ WORD_WIDTH-1:0 ] WriteData;
	output reg	[ WORD_WIDTH-1:0 ] ReadData;
		
	//Actual variable containing memory array
	reg [ WORD_WIDTH-1:0 ] data [ 0:`RAM_DEPTH ];
	
	//Note that overall simulation performance depends on this sensivity list
	//Syncronous read/write
	always @(ReadAddr or WriteAddr or WriteEnable) begin
		//Read data every clock
		ReadData <= data[ ReadAddr ];
		//Write data only if WriteEnable flag is set
		if (WriteEnable) begin
			data[ WriteAddr ] <= WriteData;
		end
	end
endmodule