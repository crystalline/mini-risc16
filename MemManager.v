//This module prevents conflicts between two stages (IF and MEM) trying to use same physical resource (main memory).
//Causes stall in IF stage (inserts NOP), if MEM stage is reading memory. MEM writing should go smoothly on two-port RAM.
//Cache layer can be later integrated here.
//TODO: Byte-adressing
module LightMemManager(
	//Control flag
	input wire	ReadRequestFlag,
	
	//Interface to Instruction Fetcher stage.
	input wire	[ `RAMREAD_WIDTH-1:0 ] IFAddr,
	output reg	[ `RAMREAD_WIDTH-1:0 ] IFRead,
	
	//Interface to MEMory stage.
	input wire	[ `RAMADDR_WIDTH-1:0 ] MEMAddr,
	output reg	[ `RAMREAD_WIDTH-1:0 ] MEMRead,	
	
	//Interface to physical RAM
	input wire	[ `RAMREAD_WIDTH-1:0 ] RAMRead,	//Memory read register
	output reg	[ `RAMADDR_WIDTH-1:0 ] RAMAddr	//Memory address register
);	
	always @( ReadRequestFlag ) begin
		if ( ReadRequestFlag ) begin
			IFRead <= `CONST_NOP;
			RAMAddr <= MEMAddr;
			MEMRead <= RAMRead;
		end
		else begin
			RAMAddr <= IFAddr;
			IFRead <= RAMRead;
		end
	end
endmodule
