 //Global timescale
`timescale 10ns/100ps

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

//TODO: Top level test file.
//Top level file for testing
module TestCore();
	
`ifdef SIM
	integer i;
	integer file;
	
	//Dump contents of CPU registers
	task DumpRegState;
	begin
		for(i=0; i<32; i=i+4) begin
			$display( "|%d| |%d| |%d| |%d|",
				RF.RegData[ i+0 ],
				RF.RegData[ i+1 ],
				RF.RegData[ i+2 ],
				RF.RegData[ i+3 ]
			);
		end
	end
	endtask
`endif
	
	//Global clock
	wire gclk;
	//Global PowerOn signal
	reg PowerOn;
	
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
	wire MEM_WriteEnable;
	
	//MBP is declared upper
	wire [ `WORD_WIDTH-1:0 ] Mem_IFBypassData;
	
	wire [ `WORD_WIDTH-1:0 ]	MEM_ReadAddr;
	wire [ `WORD_WIDTH-1:0 ]	MEM_ReadData;
	wire [ `WORD_WIDTH-1:0 ]	MEM_WriteAddr;
	wire [ `WORD_WIDTH-1:0 ]	MEM_WriteData;
	
	wire [ `WBDB_WIDTH-1:0 ] MEM_OutDataBus;
	wire [ `CBUS_WIDTH-1:0 ] MEM_OutControlBus;
	
	//WB
	wire [ `WBDB_WIDTH-1:0 ] WB_DataBus;
	wire [ `CBUS_WIDTH-1:0 ] WB_ControlBus;
//---------------------------------------------------------------------------------------//
	ClockGen clk( .clk(gclk) ); //Clock generator
	
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
	
	//Instruction memory
	defparam InstructionMem.WORD_WIDTH = `RAMREAD_WIDTH;
	defparam InstructionMem.ADDR_WIDTH = `RAMADDR_WIDTH;
	SyncRam InstructionMem(
		.gclk( gclk ),
		.WriteEnable( MEM_WriteEnable ), 
		.WriteAddr( MEM_WriteAddr ),
		.WriteData( MEM_WriteData ),
		.ReadAddr( IM_ReadAddr ),
		.ReadData( IM_ReadData )
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
	
	
	/*
	//Arithmetic-Logic-Unit ( connected to HD, not ID )
	ALU EXEC(
		.gclk( gclk ),
		.InDataBus( HD_to_ALU_DataBus ),
		.OutDataBus( ALU_OutDataBus ),
		.InControlBus( ID_OutControlBus ),
		.OutControlBus( ALU_OutControlBus ),
		.JumpFlag( ALU_JumpFlag )
	);
	*/
	
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
	
	//Initialisation
	initial begin
		//Load memory: $readmemh("file_name", mem_array, start_addr, stop_addr);
		//$readmemh("TestImage.txt", InstructionMem.data, 0, 7);
		//Simply load memory in-place instead
		
		/*
		InstructionMem.data[ 5 ] <= 16'h1047;//ADD	R1, R2
		InstructionMem.data[ 6 ] <= 16'h024E;//JZ, PC-4
		InstructionMem.data[ 7 ] <= 16'h02D6;//JMP, PC-5
		InstructionMem.data[ 1 ] <= 16'h0042;//LDI	R1, 3                      
		InstructionMem.data[ 2 ] <= 16'h0000;//
		InstructionMem.data[ 3 ] <= 16'h0082;//LDI	R2, 0
		InstructionMem.data[ 4 ] <= 16'h0000;//
		*/
		
		/* Cycle example */
		
		InstructionMem.data[ 0 ] <= 0;
		InstructionMem.data[ 1 ] <= 16'h00C2;//LDI	R3, 1                             
		InstructionMem.data[ 2 ] <= 16'h0001;//
		InstructionMem.data[ 3 ] <= 16'h0002;//LDI	R0, F
		InstructionMem.data[ 4 ] <= 16'h000F;//
		InstructionMem.data[ 5 ] <= 16'h1008;//SUB R0,R2
		InstructionMem.data[ 6 ] <= 16'h0110;//JZS PC+2 (PC+4-2)
		InstructionMem.data[ 7 ] <= 16'h0045;//16'h0884;//ST (R1:R2), R2
		InstructionMem.data[ 8 ] <= 16'h1886;//ADD R2,R3         
		InstructionMem.data[ 9 ] <= 16'h0458;//JMPS PC-8 (PC-6-2)
		InstructionMem.data[ 10] <= 16'h0118;//JMPS PC-2 (PC-0-2)
		InstructionMem.data[ 11] <= 16'hFFFF;
		InstructionMem.data[ 12] <= 16'h0;
		InstructionMem.data[ 13] <= 16'h0;
		InstructionMem.data[ 14] <= 16'h0;
		InstructionMem.data[ 15] <= 16'h0;                        
		InstructionMem.data[ 16] <= 16'h0;
		InstructionMem.data[ 17] <= 16'h0;
		InstructionMem.data[ 18] <= 16'h0;
		InstructionMem.data[ 19] <= 16'h0;
		
		
		/*
		InstructionMem.data[ 0 ] <= 16'h8000;
		InstructionMem.data[ 1 ] <= 16'h0;                             
		InstructionMem.data[ 2 ] <= 16'h0;
		InstructionMem.data[ 3 ] <= 16'h0;
		InstructionMem.data[ 4 ] <= 16'h0;
		InstructionMem.data[ 5 ] <= 16'h45;
		InstructionMem.data[ 6 ] <= 16'h1000;
		InstructionMem.data[ 7 ] <= 16'h2000;
		InstructionMem.data[ 8 ] <= 16'h3000;
		InstructionMem.data[ 9 ] <= 16'h4000;
		InstructionMem.data[ 10] <= 16'h0158;//JMPS PC-2 (PC-0-2)
		InstructionMem.data[ 11] <= 16'h0;
		InstructionMem.data[ 12] <= 16'h0;
		InstructionMem.data[ 13] <= 16'h0;
		InstructionMem.data[ 14] <= 16'h0;
		InstructionMem.data[ 15] <= 16'h0;                        
		InstructionMem.data[ 16] <= 16'h0;
		InstructionMem.data[ 17] <= 16'h0;
		InstructionMem.data[ 18] <= 16'h0;
		InstructionMem.data[ 19] <= 16'h0;
		*/
		
		/*
		InstructionMem.data[ 0 ] <= 16'h0;
		InstructionMem.data[ 1 ] <= 16'h00C2;//LDI	R3, 1                             
		InstructionMem.data[ 2 ] <= 16'h0001;//
		InstructionMem.data[ 3 ] <= 16'h0158;
		InstructionMem.data[ 4 ] <= 16'h0;
		InstructionMem.data[ 5 ] <= 16'h0;
		InstructionMem.data[ 6 ] <= 16'h0;
		InstructionMem.data[ 7 ] <= 16'h0;
		InstructionMem.data[ 8 ] <= 16'h0;
		InstructionMem.data[ 9 ] <= 16'h0;
		InstructionMem.data[ 10] <= 16'h0;//JMPS PC-2 (PC-0-2)
		*/
		
		`ifdef SIM
		//Dump variables to .vcd file for viewing. 
		$dumpfile("TestCore.vcd");
	    $dumpvars;
	    
	    //Create PowerOn signal (begin core init)
	    PowerOn <= 1;
		#2
		PowerOn <= 0;
	    `endif
		//Monitor interesting variables
		
		//WriteBack tests
		//$monitor( "ID.TempDataBus=|%d|\n", ID.TempDataBus);
	    //$monitor( "IF.MemAddr=|%d|\n", IF.MemAddr );
	    //$monitor( "ID.OutControlBus=|%d|\n", ID.OutControlBus );
		//$monitor( "WB.WbEnable=|%d|\n", WB.WbEnable);
		//$monitor( "WB.Addr=|%d|\n", WB.ControlAddr);
		//$monitor( "WB.Data=|%d|\n", WB.InDataBus);
		
		//$monitor( "RF.Write=|%d|\n", RF.Write);
		//$monitor( "RF.WriteFlag=|%d|\n", RF.WriteFlag);
		
		//$monitor( "[DataMem[ F ] =  %h]", DataMem.data[ 15 ] );
		$monitor( "R2 = |%d|", RF.RegData[ 2 ]);
	    //Wait
		#512
		
		DumpRegState();
		
		//Write memory contents dump
		//integer i;
		//integer file;
		/*
		file = $fopen("MemDump.txt");
		
		for(i=0; i<20; i=i+1) begin
			$fdisplay(file, "[%d][%d]", i, Instruction.data[ i ]);
		end
		
		$fclose( file );
		*/
		//Exit simulation
		$finish;
	end
endmodule
