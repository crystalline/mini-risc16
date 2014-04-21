//Risc CPU module with interface to memory, clock and reset.
//Is used in simulation and synthesis toplevels
//Note: in synthesis revision of project decision was made to have RiscCpu
//and SimTestBench instead of TestCore to facilate sim, and synth.

//Note: needs including of other files

//Include files from processor project
`include "CoreHeader.v"
`include "RegFile.v"
`include "SyncRam.v"
`include "MemBypasser.v"
`include "InstructionFetch.v"
`include "InstructionDecode.v"
`include "HazardDetect.v"
`include "ALU.v"
`include "Memory.v"
`include "WriteBack.v"
`include "ClockGen.v"

module RiscCpu(
	input wire gclk,
	input wire PowerOn,
	
	output wire MemWriteFlag,
	input wire [ `WORD_WIDTH-1:0 ] MemReadData,
	output wire [ `WORD_WIDTH-1:0 ] MemWriteData,
	output wire [ `WORD_WIDTH-1:0 ] MemReadAddr,
	output wire [ `WORD_WIDTH-1:0 ] MemWriteAddr
);                                           
	
	
	//Register file wires.
	wire WB_to_RF_WriteFlagA;
	wire [ `REG_ADDR_WIDTH-1:0 ]	HD_to_RF_ReadAddrA; //Adress Read A.
	wire [ `REG_ADDR_WIDTH-1:0 ]	HD_to_RF_ReadAddrB; //Adress Read B.
	wire [ `REG_ADDR_WIDTH-1:0 ]	HD_to_RF_ReadAddrC; //Adress Read C.
	wire [ `REG_ADDR_WIDTH-1:0 ]	WB_to_RF_WriteAddrA; //Write adress.
	wire [ `WORD_WIDTH-1:0 ]	RF_to_HD_ReadDataA; //Read output A (asyncronous).
	wire [ `WORD_WIDTH-1:0 ]	RF_to_HD_ReadDataB; //Read output B (asyncronous).
	wire [ `WORD_WIDTH-1:0 ]	RF_to_HD_ReadDataC; //Read output C (asyncronous).
	wire [ `WORD_WIDTH-1:0 ]	WB_to_RF_WriteDataA; //Data to write, input.
	
	//Instruction memory
	wire IM_WriteEnable;
	wire [ `RAMADDR_WIDTH-1:0 ]		IM_ReadAddr;
	wire [ `RAMREAD_WIDTH-1:0 ]		IM_ReadData;

	//MemBypasser
	wire MBP_RAMAddrSel;
	wire MBP_IFDataSel;
	
	//Note: jump wires are declared in IF, ID and ALU
	
	//Instruction Fetch
	wire [ `IFDB_WIDTH-1:0 ] IF_OutDataBus;
	wire [ `RAMADDR_WIDTH-1:0 ]		IF_MemReadAddr;
	wire [ `RAMREAD_WIDTH-1:0 ]		IF_MemReadData;
		
	//Memory wires are declared upper
	
	//Instruction Decode
	wire [ `IFDB_WIDTH-1:0 ] ID_InDataBus;
	wire [ `IDDB_WIDTH-1:0 ] ID_OutDataBus;
	wire [ `CBUS_WIDTH-1:0 ] ID_OutControlBus;
	wire [ `ADDR_WIDTH-1:0 ] ID_JumpAddr;
	
	wire ID_JumpFlag;
	wire ID_JumpType;
	wire ID_JumpAddrSign;
	
	wire [ `WORD_WIDTH-1:0 ] HD_to_ID_RegDstData;
	wire [ `WORD_WIDTH-1:0 ] HD_to_ID_RegSrcData;
	wire [ `WORD_WIDTH-1:0 ] HD_to_ID_RegExtData;
	wire [ `REG_ADDR_WIDTH-1:0 ] ID_to_HD_RegDstAddr;
	wire [ `REG_ADDR_WIDTH-1:0 ] ID_to_HD_RegSrcAddr;
	wire [ `REG_ADDR_WIDTH-1:0 ] ID_to_HD_RegExtAddr;
	
	//Register wires are decalred upper
	
	//Hazard detect - between ID and RF
	wire [ `IDDB_WIDTH-1:0 ] HD_to_ALU_DataBus;
	
	//ALU
	wire [ `MEMDB_WIDTH-1:0 ] ALU_OutDataBus;
	wire [ `MEMDB_WIDTH-1:0 ] ALU_AsyncOutDataBus;
	wire [ `CBUS_WIDTH-1:0 ] ALU_OutControlBus;
	wire [ `CBUS_WIDTH-1:0 ] ALU_AsyncOutControlBus;
	wire ALU_JumpFlag;
	wire ALU_CurrentAluEnable;
	wire ALU_CurrentZeroFlag;
	wire ALU_CurrentCarryFlag;
	wire ALU_SavedZeroFlag;
	wire ALU_SavedCarryFlag;
	//Jump wire is declared in IF
	
	//MEM
	wire MEM_Stall;
	wire MEM_WriteEnable = MemWriteFlag;
	
	//MBP is declared upper
	wire [ `WORD_WIDTH-1:0 ] Mem_IFBypassData;
	
	wire [ `WORD_WIDTH-1:0 ]	MEM_ReadAddr = MemReadAddr;
	wire [ `WORD_WIDTH-1:0 ]	MEM_ReadData = MemReadData;
	wire [ `WORD_WIDTH-1:0 ]	MEM_WriteAddr = MemWriteAddr;
	wire [ `WORD_WIDTH-1:0 ]	MEM_WriteData = MemWriteData;
	
	wire [ `WBDB_WIDTH-1:0 ] MEM_OutDataBus;
	wire [ `CBUS_WIDTH-1:0 ] MEM_OutControlBus;
	
	//WB
	wire [ `WBDB_WIDTH-1:0 ] WB_DataBus;
	wire [ `CBUS_WIDTH-1:0 ] WB_ControlBus;
//---------------------------------------------------------------------------------------//
	
	//Register file	
	RegFile_3R_1W RF (
		.gclk( gclk ),
		.PowerOn( PowerOn ),
		.WriteFlag( WB_to_RF_WriteFlagA ),
		.AddrReadA( HD_to_RF_ReadAddrA ),
		.AddrReadB( HD_to_RF_ReadAddrB ),
		.AddrReadC( HD_to_RF_ReadAddrC ),
		.AddrWrite( WB_to_RF_WriteAddrA ),
		.ReadA( RF_to_HD_ReadDataA ),
		.ReadB( RF_to_HD_ReadDataB ),
		.ReadC( RF_to_HD_ReadDataC ),      
		.Write( WB_to_RF_WriteDataA )
	);

	//MemBypasser
	MemBypasser MB(
		.gclk( gclk ),
		.RAM_AddrSel( MBP_RAMAddrSel ),
		.IF_DataSel( MBP_IFDataSel ),
		
		.IF_ReadAddr( IF_MemReadAddr ),
		.IF_ReadData( IF_MemReadData ),
		
		.MEM_ReadAddr( MEM_ReadAddr ),
		.MEM_IFBypassData( Mem_IFBypassData ),
		
		.RAM_ReadData( IM_ReadData ),
		.RAM_ReadAddr( IM_ReadAddr )
	);
	
	//Instruction fetcher
	InstructionFetch IF(
		.gclk( gclk ),
		.stall( MEM_Stall ),
		.PowerOn( PowerOn ),
		.MemAddr( IF_MemReadAddr ),
		.MemRead( IF_MemReadData ),
		.JumpFlag( ID_JumpFlag ),
		.JumpTypeFlag( ID_JumpType ),
		.JumpAddrSign( ID_JumpAddrSign ),
		.JumpAddr( ID_JumpAddr ),
		.OutDataBus( IF_OutDataBus )
	);
	
	//Instruction decoder
	InstructionDecode ID(
		.gclk( gclk ),
		.stall( MEM_Stall ),
		.InDataBus( IF_OutDataBus ),
		.OutDataBus( ID_OutDataBus ),
		.OutControlBus( ID_OutControlBus ),
		
		//TODO: Jump controls integration
		.JumpFlag( ID_JumpFlag ),
		.JumpType( ID_JumpType ),
		.JumpAddrSign( ID_JumpAddrSign ),
		.JumpAddr( ID_JumpAddr ),
		
		.RF_RegDstData( HD_to_ID_RegDstData ),
		.RF_RegSrcData( HD_to_ID_RegSrcData ),
		.RF_RegExtData( HD_to_ID_RegExtData ),
		.RF_RegDstAddr( ID_to_HD_RegDstAddr ),
		.RF_RegSrcAddr( ID_to_HD_RegSrcAddr ),
		.RF_RegExtAddr( ID_to_HD_RegExtAddr ),
		
		.CurrentAluEnable( ALU_CurrentAluEnable ),
		.CurrentZeroFlag( ALU_CurrentZeroFlag ),
		.CurrentCarryFlag( ALU_CurrentCarryFlag ),
		.SavedZeroFlag( ALU_SavedZeroFlag ),
		.SavedCarryFlag(ALU_SavedCarryFlag )
	);
	
	
	//Hazard preventor
	HazardDetect HD(
		.gclk( gclk ),
		
		.ID_RegDstData( HD_to_ID_RegDstData ),
		.ID_RegSrcData( HD_to_ID_RegSrcData ),
		.ID_RegExtData( HD_to_ID_RegExtData ),
		.ID_RegDstAddr( ID_to_HD_RegDstAddr ),
		.ID_RegSrcAddr( ID_to_HD_RegSrcAddr ),
		.ID_RegExtAddr( ID_to_HD_RegExtAddr ),
		
		.RF_RegDstData( RF_to_HD_ReadDataA ),
		.RF_RegSrcData( RF_to_HD_ReadDataB ),
		.RF_RegExtData( RF_to_HD_ReadDataC ),
		.RF_RegDstAddr( HD_to_RF_ReadAddrA ),
		.RF_RegSrcAddr( HD_to_RF_ReadAddrB ),
		.RF_RegExtAddr( HD_to_RF_ReadAddrC ),
		
		.ALU_ControlBus( ALU_AsyncOutControlBus ), 
		.MEM_ControlBus( ALU_OutControlBus ),
		.WB_ControlBus( MEM_OutControlBus ),
		
		.ALU_DataBus( ALU_AsyncOutDataBus ),
		.MEM_DataBus( ALU_OutDataBus ),
		.WB_DataBus( MEM_OutDataBus )
	);
	
	
	
	//ALU with direct connection to ID
	ALU EXEC(
		.gclk( gclk ),
		.stall( MEM_Stall ),
		.InDataBus( ID_OutDataBus ),
		.OutDataBus( ALU_OutDataBus ),
		.AsyncOutDataBus( ALU_AsyncOutDataBus ),
		.InControlBus( ID_OutControlBus ),
		.OutControlBus( ALU_OutControlBus ),
		.AsyncOutControlBus( ALU_AsyncOutControlBus ),
		
		.CurrentAluEnable( ALU_CurrentAluEnable ),
		.CurrentZeroFlag( ALU_CurrentZeroFlag ),
		.CurrentCarryFlag( ALU_CurrentCarryFlag ),
		.SavedZeroFlag( ALU_SavedZeroFlag ),
		.SavedCarryFlag(ALU_SavedCarryFlag )
	);
	
	
	//Memory access unit
	Memory MEM(
		.gclk( gclk ),
		.stall( MEM_Stall ),
		
		.InDataBus( ALU_OutDataBus ),
		.OutDataBus( MEM_OutDataBus ),
		.InControlBus( ALU_OutControlBus ),
		.OutControlBus( MEM_OutControlBus ),
		
		.MemWriteFlag( MEM_WriteEnable ),
		.MemWriteAddr( MEM_WriteAddr ),
		.MemWriteData( MEM_WriteData ),
		
		.MemReadAddr( MEM_ReadAddr ),
		.MemReadData( IM_ReadData ),
		.MBP_RAMAddrSel( MBP_RAMAddrSel ),
		.MBP_IFDataSel( MBP_IFDataSel ),
		.Mem_IFBypassData( Mem_IFBypassData )
		
	);
	
	//WriteBack unit
	WriteBack WB(
		.gclk( gclk ),
		.InDataBus( MEM_OutDataBus ),
		.InControlBus( MEM_OutControlBus ),
		.RegWriteEnable( WB_to_RF_WriteFlagA ),
		.RegWriteAddr( WB_to_RF_WriteAddrA ),
		.RegWriteData( WB_to_RF_WriteDataA )
	);

endmodule
