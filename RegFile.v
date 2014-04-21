//`include "CoreHeader.v"

//TODO: Split this implementation to two different modules/files

/*
//Register file with two asyncronous read ports and one write port.
`define REG_NUM 32
module RegFile_2R_1W(
	//Module interface
	input wire gclk,		//Clock
	input wire PowerOn,		//PowerOn reset
	input wire WriteFlag,	//WriteFLag which enables writing to RegFile
	//Adress buses
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrReadA,	//Adress Read A
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrReadB,	//Adress Read B
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrWrite,	//Write adress
	//Data buses
	output wire [ `WORD_WIDTH-1:0 ]	ReadA,	//Read output A (asyncronous)
	output wire [ `WORD_WIDTH-1:0 ]	ReadB,	//Read output B (asyncronous)
	input wire [ `WORD_WIDTH-1:0 ]	Write	//Data to write
);
	//Internal registers are verilog's "memory"
	reg [ `WORD_WIDTH-1:0 ] RegData [ `REG_NUM-1:0 ];
	
	//Read operation are asyncronous, so continuos assigment does the work
	assign ReadA = RegData[ AddrReadA ];
	assign ReadB = RegData[ AddrReadB ];
	
	`ifdef SIM
	//Initialisation TODO: think about other way
	always @( PowerOn ) begin
		if (PowerOn) begin
			RegData[ 0 ] <= 0;
			RegData[ 1 ] <= 0;
			RegData[ 2 ] <= 0;
			RegData[ 3 ] <= 0;
			RegData[ 4 ] <= 0;
			RegData[ 5 ] <= 0;
			RegData[ 6 ] <= 0;
			RegData[ 7 ] <= 0;
			RegData[ 8 ] <= 0;
			RegData[ 9 ] <= 0;
			RegData[ 10 ] <= 0;
			RegData[ 11 ] <= 0;             
			RegData[ 12 ] <= 0;
			RegData[ 13 ] <= 0;
			RegData[ 14 ] <= 0;
			RegData[ 15 ] <= 0;
			RegData[ 16 ] <= 0;
			RegData[ 17 ] <= 0;
			RegData[ 18 ] <= 0;
			RegData[ 19 ] <= 0;
			RegData[ 20 ] <= 0;
			RegData[ 21 ] <= 0;
			RegData[ 22 ] <= 0;
			RegData[ 23 ] <= 0;
			RegData[ 24 ] <= 0;
			RegData[ 25 ] <= 0;                                
			RegData[ 26 ] <= 0;
			RegData[ 27 ] <= 0;
			RegData[ 28 ] <= 0;
			RegData[ 29 ] <= 0;
			RegData[ 30 ] <= 0;
			RegData[ 31 ] <= 0;
		end
	end
	`endif
	
	//Write operations are syncronus, requireing write flag to be set
	always @( posedge gclk ) begin
		if( WriteFlag ) RegData[ AddrWrite ] <= Write;	
	end
endmodule
*/

//Register file with three asyncronous read ports and one write port.
`define REG_NUM 32
module RegFile_3R_1W(
	//Module interface
	input wire gclk,		//Clock
	input wire PowerOn,		//PowerOn reset
	input wire WriteFlag,	//WriteFLag which enables writing to RegFile
	//Adress buses
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrReadA,	//Adress Read A
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrReadB,	//Adress Read B
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrReadC,	//Adress Read C
	input wire [ `REG_ADDR_WIDTH-1:0 ]	AddrWrite,	//Write adress
	//Data buses
	output wire [ `WORD_WIDTH-1:0 ]	ReadA,	//Read output A (asyncronous)
	output wire [ `WORD_WIDTH-1:0 ]	ReadB,	//Read output B (asyncronous)
	output wire [ `WORD_WIDTH-1:0 ]	ReadC,	//Read output C (asyncronous)
	input wire [ `WORD_WIDTH-1:0 ]	Write	//Data to write
);
	//Internal registers are verilog's "memory"
	reg [ `WORD_WIDTH-1:0 ] RegData [ `REG_NUM-1:0 ];
	
	//Read operation are asyncronous, so continuos assigment does the work
	assign ReadA = RegData[ AddrReadA ];
	assign ReadB = RegData[ AddrReadB ];
	assign ReadC = RegData[ AddrReadC ];
	
	
	//Initialisation TODO: think about other way
	initial begin
		RegData[ 0 ] <= 0;
		RegData[ 1 ] <= 0;
		RegData[ 2 ] <= 0;
		RegData[ 3 ] <= 0;
		RegData[ 4 ] <= 0;
		RegData[ 5 ] <= 0;
		RegData[ 6 ] <= 0;
		RegData[ 7 ] <= 0;
		RegData[ 8 ] <= 0;
		RegData[ 9 ] <= 0;
		RegData[ 10 ] <= 0;
		RegData[ 11 ] <= 0;             
		RegData[ 12 ] <= 0;
		RegData[ 13 ] <= 0;
		RegData[ 14 ] <= 0;
		RegData[ 15 ] <= 0;
		RegData[ 16 ] <= 0;
		RegData[ 17 ] <= 0;
		RegData[ 18 ] <= 0;
		RegData[ 19 ] <= 0;
		RegData[ 20 ] <= 0;
		RegData[ 21 ] <= 0;
		RegData[ 22 ] <= 0;
		RegData[ 23 ] <= 0;
		RegData[ 24 ] <= 0;
		RegData[ 25 ] <= 0;                                
		RegData[ 26 ] <= 0;
		RegData[ 27 ] <= 0;
		RegData[ 28 ] <= 0;
		RegData[ 29 ] <= 0;
		RegData[ 30 ] <= 0;
		RegData[ 31 ] <= 0;
	end
	
	//Write operations are syncronus, requireing write flag to be set
	always @( posedge gclk ) begin
		if( WriteFlag ) RegData[ AddrWrite ] <= Write;	
	end
endmodule
