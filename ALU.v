//`include "CoreHeader.v"

//Arithmetic-logic unit.
//TODO: jumps (conditional)
module ALU(
	input wire gclk,
	input wire stall,
	
	//Data bus
	input wire [ `IDDB_WIDTH-1:0 ] InDataBus,
	output reg [ `MEMDB_WIDTH-1:0 ] OutDataBus,
	output reg [ `MEMDB_WIDTH-1:0 ] AsyncOutDataBus,
	
	//Control bus
	input wire [ `CBUS_WIDTH-1:0 ] InControlBus,
	output reg [ `CBUS_WIDTH-1:0 ] OutControlBus,
	output wire [ `CBUS_WIDTH-1:0 ] AsyncOutControlBus,
	
	//Status register, as separate bits
	output wire CurrentAluEnable,
	output reg CurrentZeroFlag,
	output reg CurrentCarryFlag,
	output reg SavedZeroFlag,
	output reg SavedCarryFlag
);
	//Exract Alu control bus from main control bus
	wire [ `ALUCB_WIDTH-1:0 ] AluControlBus = InControlBus[ `ALUCB_MSB:`ALUCB_LSB ];
	
	//Extract current operation MODE from ALU controlbus
	wire [ `ALU_MODE_WIDTH-1:0 ] AluMode = AluControlBus[ `ALU_MODE_MSB:`ALU_MODE_LSB ];
	
	//Extract ALU_ENABLE flag from ALU control bus
	wire AluEnable = AluControlBus [ `ALU_ENABLE ];
	//Connect AluEnable to CurrentAluEnable for jump sake
	assign CurrentAluEnable = AluEnable;
	
	//Split doubleword input databus to two words - input A and input B
	wire [ (`WORD_WIDTH-1):0 ] AluInA;
	wire [ (`WORD_WIDTH-1):0 ] AluInB;	
	assign {AluInB,AluInA} = InDataBus;
	//Grow ALU inputs by 1 bit, resulting in wide alu inputs for carry sake.
	//Carry is initialized with 0, so carry can be set in WideAluResult only in case of overflow.
	wire [ (`WORD_WIDTH-1)+1:0 ] WideInA = {1'b0, AluInA};
	wire [ (`WORD_WIDTH-1)+1:0 ] WideInB = {1'b0, AluInB};
	
	//Variable to store result of ALU operation, is of word size + 1 to store carry
	reg	[ (`WORD_WIDTH-1)+1:0 ] WideAluResult;
	wire [ `WORD_WIDTH-1:0 ] AluResult = WideAluResult[ `WORD_WIDTH-1:0 ];
	
	//Asyncronous signals needed for correct opertaion of Hazard Detector (shuffler)
	//AsyncOutDataBus always equals OutDataBus, but contains more recent value
	assign AsyncOutControlBus = InControlBus;
			
	//Pass forward control bus and result of ALU operations.
	always @( posedge gclk ) begin
		if( stall == 0 ) begin
			//TODO: implement JumpFlag, now simply pass 0 to it
			//JumpFlag <= 0;
			//Always pass control signals forward
			OutControlBus <= InControlBus;
			
			//Pass DataBusForth
			OutDataBus <= AsyncOutDataBus;
		end
	end
	
	//Pass Alu result forward only if Alu is Enabled, else pass forth value of AluInA
	always @(*) begin
		if ( AluEnable )
			AsyncOutDataBus <= AluResult;
		else
			AsyncOutDataBus <= AluInA;
	end
		
	//Process Zero and Carry flags, syncronous and asyncronous
	
	//Save flags only on clock edge and if there was ALU-instruction
	always @( posedge gclk ) begin
		if ( AluEnable == 1 ) begin
			SavedCarryFlag <= WideAluResult[ `WORD_WIDTH ];
			SavedZeroFlag <= (AluResult == 0);
		end
	end
	
	always @(*) begin
		//Put result's carry bit to CarryFlag
		CurrentCarryFlag <= WideAluResult[ `WORD_WIDTH ];
		//If word's value is zero, then put 1 to ZeroFlag
		CurrentZeroFlag <= (AluResult == 0);
	end
	
	//Alu logic (controlled by ControlBus)
	always @(*) begin
		case ( AluMode )
			//Simple logic operations
			`ALU_NOT:	WideAluResult <= ~WideInA;
			`ALU_AND:	WideAluResult <= WideInA & WideInB;
			`ALU_OR:	WideAluResult <= WideInA | WideInB;
			`ALU_XOR:	WideAluResult <= WideInA ^ WideInB;
			//Operations which can set carry (arithmetic)
			`ALU_ADD:	WideAluResult <= WideInA + WideInB;
			`ALU_SUB:	WideAluResult <= WideInA - WideInB;
			`ALU_ADC:	WideAluResult <= WideInA + WideInB + SavedCarryFlag;
			`ALU_SUBC:	WideAluResult <= WideInA - WideInB - SavedCarryFlag;
			//Rotation through carry operations
			`ALU_ROL:	WideAluResult <= (WideInA << 1) | SavedCarryFlag;
			`ALU_ROR:	WideAluResult <= (WideInA[ `LSB ] << `WORD_WIDTH) | (WideInA >> 1) | (SavedCarryFlag << `WORD_WIDTH-1);
			//Jump operations' behavior is described in separate process
			default:	WideAluResult <= WideInA;
		endcase
	end
endmodule
