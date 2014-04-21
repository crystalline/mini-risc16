//This module prevents conflicts between two stages (IF and MEM) trying to use same physical resource (main memory).
//Causes stall in IF stage (inserts NOP), if MEM stage is reading memory. MEM writing should go smoothly on two-port RAM.
//Cache layer can be later integrated here.
//TODO: Byte-adressing ?

`include "CoreHeader.v"

module MemBypasser(
	input wire gclk,
	
	//Control flags
	input wire RAM_AddrSel,	
	input wire IF_DataSel,
	
	//Interface to Instruction Fetcher stage.
	input wire	[ `RAMREAD_WIDTH-1:0 ] IF_ReadAddr,
	output reg	[ `RAMREAD_WIDTH-1:0 ] IF_ReadData,
	
	//Interface to MEMory stage.
	input wire	[ `RAMADDR_WIDTH-1:0 ] MEM_ReadAddr,
	input wire	[ `RAMREAD_WIDTH-1:0 ] MEM_IFBypassData,	
	
	//Interface to physical RAM
	input wire	[ `RAMREAD_WIDTH-1:0 ] RAM_ReadData,	//Memory read register
	output reg	[ `RAMADDR_WIDTH-1:0 ] RAM_ReadAddr		//Memory address register
);	
	//Multiplexor implementation
	
	//Adress
	always @(*) begin
		if( RAM_AddrSel == 0 ) begin
			RAM_ReadAddr <= IF_ReadAddr;
		end
		else begin
			RAM_ReadAddr <= MEM_ReadAddr;
		end
	end
	
	//Data
	always @(*) begin
		if( IF_DataSel == 0 ) begin
			IF_ReadData <= RAM_ReadData;
		end
		else begin
			IF_ReadData <= MEM_IFBypassData;
		end
	end
	
	
endmodule
