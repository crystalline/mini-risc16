//`include "CoreHeader.v"

//Instruction decoder, register fetcher and some control logic

module InstructionDecode(
	input wire gclk,
	input wire stall,
	
	input wire [ `IFDB_WIDTH-1:0 ] InDataBus,
	output reg [ `IDDB_WIDTH-1:0 ] OutDataBus,
	//Output control buses to ALU, MEM and WB.
	output reg [ `CBUS_WIDTH-1:0 ] OutControlBus,
	
	//TODO:Interface to IF jump controls; Change JumpAddr width;
	output reg JumpFlag,
	output reg JumpType,
	output wire JumpAddrSign,
	output reg [ `ADDR_WIDTH-1:0 ] JumpAddr,
	
	//Interface to register file: needed two read channels, third for extra address
	input wire [ `WORD_WIDTH-1:0 ] RF_RegDstData,
	input wire [ `WORD_WIDTH-1:0 ] RF_RegSrcData,
	input wire [ `WORD_WIDTH-1:0 ] RF_RegExtData,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegDstAddr,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegSrcAddr,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegExtAddr,
	
	//Interface to ALU status flags, and Enable flag
	input wire CurrentAluEnable,
	input wire CurrentZeroFlag,
	input wire CurrentCarryFlag,
	input wire SavedZeroFlag,
	input wire SavedCarryFlag
);                                    
	//Simple instruction-word layout.
	//..........|5B-REGSRC|5B-REGDST|6B-OPCODE| - OP R, R - 1-word (ADD,OR...)
	//|16B-CONST|5B-EMPTY |5B-REGDST|6B-OPCODE| - OP R, K - 2-word (LDI R,K)
	//|16B-CONST|5B-EMPTY |5B-EMPTY |6B-OPCODE| - OP K    - 2-word (jmp, jz, jc)
	//|16B-CONST|5B-REGSRC|5B-REGDST|6B-OPCODE| - OP R,R,K- 2-word (LD R,R+k, ST R,R+k)
	//|31-----16|15-----11|10------6|5-------0|
	
	//|31--25B-REL_ADDR--7|1B-SIGN-6|6B-OPCODE| - OP LONG_ADDR
	//|-NOT_USED|15-ADDR-7|1B-SIGN-6|6B-OPCODE| - OP SHORT_ADDR
	
	//TODO: Deprecated CurrentInst
	wire [ `IFDB_WIDTH-1:0 ] CurrentInst = InDataBus;
	
	//Internal wires, representing layout of instruction word.
	//Opcode - number which identifies instruction.
	wire [ `OPCODE_WIDTH-1:0 ] OpCode;
	assign OpCode = CurrentInst[ `OPCODE_WIDTH-1:`OPCODE_OFFSET ];
	
	//Destination register adress
	wire [ `REG_ADDR_WIDTH-1:0 ] RegDstAddr;
	assign RegDstAddr = CurrentInst[ (`REG_ADDR_WIDTH-1)+`REG_DST_OFFSET : `REG_DST_OFFSET ];
	
	//Source register adress
	wire [ `REG_ADDR_WIDTH-1:0 ] RegSrcAddr;
	assign RegSrcAddr = CurrentInst[ (`REG_ADDR_WIDTH-1)+`REG_SRC_OFFSET : `REG_SRC_OFFSET ];
	
	//Extra register adress always depends on RegSrcAddr
	//EXtra wire created to deal with carry
	//wire [ `REG_ADDR_WIDTH-1+1:0 ] ExtAddrWCarry = RegSrcAddr + 5'd1;
	wire [ `REG_ADDR_WIDTH-1:0 ] RegExtAddr = RegSrcAddr + 5'd1;
	
	//Constant, machine word.
	wire [ `CONST_WIDTH-1:0 ] Const;
	assign Const = CurrentInst[ (`CONST_WIDTH-1)+`CONST_OFFSET : `CONST_OFFSET ];
	
	//Adress jump-related wires
	wire RelAddrSign = CurrentInst[ `ADDR_SIGN_OFFSET ];
	
	assign JumpAddrSign = RelAddrSign;
	
	wire [ `REL_ADDR_WIDTH:0 ] RelAddrLong = CurrentInst[ (`REL_ADDR_WIDTH-1)-`REL_ADDR_OFFSET:`REL_ADDR_OFFSET ];
	wire [ `REL_ADDR_SHORT_WIDTH:0 ] RelAddrShort = CurrentInst[ `WORD_WIDTH-1:`REL_ADDR_OFFSET ];
	
	//Values of Src and Dst registers are loaded, even if not necessary (using continuous assigment).
	wire [ `WORD_WIDTH-1:0 ] RegDst; //Value of destination register.
	//Make RegFile register dst. read adress assigned to reg dst adress extracted from instruction.
	assign RF_RegDstAddr = RegDstAddr;
	//Make internal register value assigned to value of RegFile Read register
	assign RegDst = RF_RegDstData;
	
	//Same with source register
	wire [ `WORD_WIDTH-1:0 ] RegSrc;
	assign RF_RegSrcAddr = RegSrcAddr;
	assign RegSrc = RF_RegSrcData;
	
	//And with extra register
	wire [ `WORD_WIDTH-1:0 ] RegExt = RF_RegExtData;
	assign RF_RegExtAddr = RegExtAddr;
	
	//Divide ControlBus to three components: ALU, MEM and WB
	reg [ `ALUCB_WIDTH-1:0 ] AluControlBus;
	reg [ `MEMCB_WIDTH-1:0 ] MemControlBus;
	reg [ `WBCB_WIDTH-1:0 ]  WbControlBus;
	
	//Temporary register for databus (to make it synchronous)
	reg [ `IDDB_WIDTH-1:0 ] TempDataBus;
	
	//Put control bus components ( and databus) to out control bus by each clock
	always @( posedge gclk ) begin
		if( stall == 0 ) begin
			OutControlBus <= {WbControlBus, MemControlBus, AluControlBus};
			/*Longer but clearer(?) variant of upper expression shown below:
			**OutControlBus[ `ALUCB_MSB:`ALUCB_LSB ] <= AluControlBus;
			**OutControlBus[ `MEMCB_MSB:`MEMCB_LSB ] <= MemControlBus;
			**OutControlBus[ `WBCB_MSB:`WBCB_LSB ] <= WbControlBus;
			*/
			//Pass data to OutDatabus from TempDataBus, to make it synchronous
			OutDataBus <= TempDataBus;
		end
	end
	
	//Main decoder process - pass constant control codes to control buses, depending on instruction
	always @(*) begin
		//Data transfer ops             
		if( OpCode == `OP_NOP ) begin
			//Disable JUMP
			JumpFlag <= 0;
			//Disable all stages of pipeline
			AluControlBus	<= 0;
			MemControlBus	<= 0;
			WbControlBus	<= 0;
			TempDataBus		<= 0;
		end
		
		if( OpCode == `OP_LDI ) begin
			//Disable JUMP
			JumpFlag <= 0;
			//Disable ALU and Memory stages
			AluControlBus <= 0;
			MemControlBus <= 0;
			//Enable WriteBack stage
			WbControlBus[ `WB_ENABLE ] <= 1;
			//Set WriteBack adress to destination register adress
			WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ] <= RegDstAddr;
			//Put Constant (which should be loaded) to TempDataBus
			TempDataBus[ `WORD_WIDTH-1:0 ] <= Const;
		end
		
		if( OpCode == `OP_MOV ) begin
			//Disable JUMP
			JumpFlag <= 0;
			//Disable ALU and Memory stages
			AluControlBus <= 0;
			MemControlBus <= 0;
			//Enable WriteBack stage
			WbControlBus[ `WB_ENABLE ] <= 1;
			//Set WriteBack adress to destination register adress
			WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ] <= RegDstAddr;
			//Put content of source register (which should be loaded to dst reg) to TempDataBus
			TempDataBus[ `WORD_WIDTH-1:0 ] <= RegSrc;
		end
		
		//Memory Load/Store operations. See notes in opcodes definitions.
		//Store with adress in source reg + offset from destination register
		if( OpCode == `OP_ST ) begin
			//Disable JUMP
			JumpFlag <= 0;
			//Disable ALU and WriteBack stages
			AluControlBus <= 0;
			WbControlBus <= 0;
			//Enable memory stage
			MemControlBus[ `MEM_ENABLE ] <= 1;
			//Set memory to STORE mode
			MemControlBus[ `MEM_LOADSTORE ] <= `MEM_STORE;
			//Put adress from (source:extra) registers (H:L) to memory adress bus
			MemControlBus[ `MEM_ADDR_MSB:`MEM_ADDR_LSB ] <= {RegSrc,RegExt};
			//Push value which needs to be stored to low half of databus from destination register
			TempDataBus[ `WORD_WIDTH-1:0 ] <= RegDst;
		end
		//Load with adress in source reg + offset to destination register
		if( OpCode == `OP_LD ) begin
			//Disable JUMP
			JumpFlag <= 0;
			//Disable ALU
			AluControlBus <= 0;
			//Enable memory stage
			MemControlBus[ `MEM_ENABLE ] <= 1;
			//Set memory to LOAD mode
			MemControlBus[ `MEM_LOADSTORE ] <= `MEM_LOAD;
			//Put adress from (source:extra) registers (H:L) to memory adress bus
			MemControlBus[ `MEM_ADDR_MSB:`MEM_ADDR_LSB ] <= {RegSrc,RegExt};
			//Enable WriteBack stage, as data should be loaded from ram to register
			WbControlBus[ `WB_ENABLE ] <= 1;
			//Set destination register adress to writeback stage
			WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ] <= RegDstAddr;
			//Push nothing to databus, as we need reading from memory
			TempDataBus <= 0;
		end
		
		//Arithmetic and logic ops (ops, requiring ALU)
		if( OpCode == `OP_ADD	||
			OpCode == `OP_ADC	||
			OpCode == `OP_SUB	||
			OpCode == `OP_SUBC	||
			OpCode == `OP_NOT	||
			OpCode == `OP_AND	||
			OpCode == `OP_OR	||
			OpCode == `OP_XOR	||
			OpCode == `OP_ROL	||
			OpCode == `OP_ROR ) begin
			
			//Disable MEM
			MemControlBus <= 0;
			
			//Disable JUMP
			JumpFlag <= 0;
			
			//Enable ALU
			AluControlBus[ `ALU_ENABLE ] <= 1;
			
			//Enable WriteBack
			WbControlBus[ `WB_ENABLE ] <= 1;
			
			//Set WriteBack register adress to destination register adress
			WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ] <= RegDstAddr;
			
			//Note that in this non-blocking assignment RegDst maps to lower half of TempDataBus, and RegSrc to upper
			TempDataBus <= {RegSrc,RegDst};
		
			//Set ALU MODE according to opcode
			case( OpCode )
			`OP_ADD	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_ADD; 
			`OP_ADC	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_ADC;
			`OP_SUB	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_SUB;
			`OP_SUBC: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_SUBC;
			`OP_NOT	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_NOT;
			`OP_AND	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_AND;
			`OP_OR	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_OR;
			`OP_XOR	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_XOR;
			`OP_ROL	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_ROL;
			`OP_ROR	: AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ] <= `ALU_ROR;
			endcase
		end
		
		//TODO: Jump/Branch instructions
		if( OpCode == `OP_JZL ) begin
			//Disable MEM/WB and databus
			MemControlBus <= 0;
			WbControlBus <= 0;
			AluControlBus <=0;
			TempDataBus <= 0;
			
			//Configure jump buses
			JumpAddr <= { 7'b0, RelAddrLong};
			JumpType <= `JUMP_NEAR;
			
			//If current instruction in EXEC stage changes ALU flags
			//then Current* flag should be used, else Saved* flag should be used+
			if( CurrentAluEnable == 1 ) begin
				if( CurrentZeroFlag == 1 ) begin
					JumpFlag <= 1;
				end
				else begin
					JumpFlag <= 0;
				end
			end
			else begin
				if( SavedZeroFlag == 1 ) begin
					JumpFlag <= 1;
				end
				else begin
					JumpFlag <= 0;
				end
			end
		end
		if( OpCode == `OP_JZS ) begin
			//Disable MEM/WB and databus
			MemControlBus <= 0;
			WbControlBus <= 0;
			AluControlBus <=0;
			TempDataBus <= 0;
			
			//Configure jump buses
			JumpAddr <= { 23'b0, RelAddrShort};
			JumpType <= `JUMP_NEAR;
			
			//If current instruction in EXEC stage changes ALU flags
			//then Current* flag should be used, else Saved* flag should be used+
			if( CurrentAluEnable == 1 ) begin
				if( CurrentZeroFlag == 1 ) begin
					JumpFlag <= 1;
				end
				else begin
					JumpFlag <= 0;
				end
			end
			else begin
				if( SavedZeroFlag == 1 ) begin
					JumpFlag <= 1;
				end
				else begin
					JumpFlag <= 0;
				end
			end
		end
		
		if( OpCode == `OP_JMPS ) begin
			//Disable MEM/WB and databus
			MemControlBus <= 0;
			WbControlBus <= 0;
			AluControlBus <=0;
			TempDataBus <= 0;
			
			//Configure jump buses
			JumpAddr <= { 23'b0, RelAddrShort};
			JumpType <= `JUMP_NEAR;
			
			//Jump without doubts
			JumpFlag <= 1;
		end
		
		/*
		begin
			$display("[ Unknown opcode: %d ]", OpCode );
			MemControlBus <= 0;
			WbControlBus <= 0;
			AluControlBus <=0;
			TempDataBus <= 0;
			TempDataBus <= 0;
		end
		*/
	end
	
endmodule

