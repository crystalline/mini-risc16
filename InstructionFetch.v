//`include "CoreHeader.v"

//Instruction fetcher module; Works with ram and loads machine words.
module InstructionFetch(
	//Global clock
	input wire gclk,
	input wire stall,
	input wire PowerOn,
	
	//Main RAM connection.
	input wire	[ `RAMREAD_WIDTH-1:0 ] MemRead, //Memory read register
	output wire	[ `RAMADDR_WIDTH-1:0 ] MemAddr, //Memory address register
	
	//Program counter related controls.
	input wire JumpFlag,		//Flag which causes jump
	input wire JumpTypeFlag,	//Type of jump: relative or absolute
	input wire JumpAddrSign,
	input wire [ `ADDR_WIDTH-1:0 ] JumpAddr,	//Address(for absolute jump) or Offset(for relative jump)
	
	//Output data bus. Must handle single- and double-word ops to the decoder
	output reg [ `IFDB_WIDTH-1:0 ] OutDataBus
);
	/*! Internal variables. !*/
	reg [ `ADDR_WIDTH-1:0 ] ProgramCounter;	//Register which holds current adress to fetch instruction
	//Connect ProgramCounter to Memory adress
	assign MemAddr = ProgramCounter[ `RAMREAD_WIDTH-1:0 ];
	/*
	always @( posedge gclk ) begin
		MemAddr <= ProgramCounter[ `RAMREAD_WIDTH-1:0 ];
	end
	*/
	
	//Current opcode from memory
	wire [ `OPCODE_WIDTH-1:0 ] OpCode = MemRead[ `OPCODE_WIDTH-1:`OPCODE_OFFSET ];
	
	//StateMachine register
	reg [ 1:0 ] state;
	
	//Possible states
	`define ST_NORMAL 2'd0
	`define ST_LONG 2'd1
	`define ST_JMP_BEGIN 2'd2
	`define ST_JMP_END 2'd3
		
	//Temp Register to save first half of 2-word instruction
	reg [ `WORD_WIDTH-1:0 ] TempWord;
	
	//Sign of constant adress
	wire TempAddrSign = TempWord[ `ADDR_SIGN_OFFSET ];
	
	//Most significiant part of jump adress
	wire [ `WORD_WIDTH-1-`OPCODE_WIDTH-1:0 ] TempAddrHighPart = TempWord[ `WORD_WIDTH-1:`OPCODE_WIDTH+1 ];
	
	//Initialisation
	//TODO: Decide way of init: always@( PowerOn ) or initial
	initial begin
			state <= `ST_NORMAL;
			ProgramCounter <= 0;
	end
	
	//Calculate length of instruction asyncronously
	reg OpLength;
	always @(*) begin
		if( OpCode == `OP_LDI	||
			OpCode == `OP_JZL	||
			OpCode == `OP_JNZL	||
			OpCode == `OP_JCL	||
			OpCode == `OP_JNCL	||
			OpCode == `OP_JMPL	) begin
			OpLength <= 1;
		end
		else begin
			OpLength <= 0;
		end
	end
		
	
	/* Loader StateMachine serves three purposes:
	** 1. Loading ordinary 1-word size instructions
	** 2. Loading 2-word sized instructions
	** 3. Serving Jumps: changing ProgramCounter and flushing wrong instructions,
	**    (By simply not passing them forth)
	*/
	
	always @( posedge gclk ) begin
		//If stall flag is zero continue normal operation
		if( stall == 0 ) begin
			//Decide, do jump or continue normal operation.
			if( JumpFlag ) begin
				
				//Begin jump procedure
				state <= `ST_JMP_BEGIN;
				
				//Out NOP forth
				OutDataBus <= 0;
				
				//Decide, if jump is direct (far) or relative.
				if(JumpTypeFlag == `JUMP_FAR)
					ProgramCounter <= JumpAddr;
				else begin
					if( JumpAddrSign == 1 ) begin
						ProgramCounter <= ProgramCounter - JumpAddr;
					end
					else begin
						ProgramCounter <= ProgramCounter + JumpAddr;
					end
				end
			end
			else begin
				//StateMachine for fetching 1-word and 2-word instructions
				case( state )
				//State NORMAL: expect 1-word op or 2-word op
				`ST_NORMAL: begin
					
					//Increment PC, anyway
					ProgramCounter <= ProgramCounter + 1;
					
					//If just 1-word operation
					if( OpLength == 0 ) begin
						//Simply pass it forth
						OutDataBus <= MemRead;
						//Next state: normal
						state <= `ST_NORMAL;
					end
					
					//If 2-word op
					else begin
						//Change state to LONG state
						state <= `ST_LONG;
						//Out NOP to databus, as we wait for second word
						OutDataBus <= 0;
						//Save current memory word to temp location
						TempWord <= MemRead;
					end
				end
				
				//State: LONG - wait for second word of long op
				`ST_LONG: begin
					//Return to normal state
					state <= `ST_NORMAL;
					//Out full 2-word instruction
					OutDataBus <= {MemRead,TempWord};
					//Increment PC
					ProgramCounter <= ProgramCounter + 1;
				end
				
				//Begin jump procedure
				`ST_JMP_BEGIN: begin
					//Switch to end jump state
					state <= `ST_NORMAL;
					//Out NOP
					OutDataBus <= 0;
					//Increment PC
					ProgramCounter <= ProgramCounter + 1;
				end
				
				//Begin jump procedure
				`ST_JMP_END: begin
					//Switch to end jump state
					state <= `ST_NORMAL;
					//Out NOP
					OutDataBus <= 0;
					//Increment PC
					ProgramCounter <= ProgramCounter + 1;
				end
				
				endcase
			end
		end
	end
endmodule
