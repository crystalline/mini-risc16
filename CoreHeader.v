/*Core processor module
**Caution: design principle is following: if there should be register between Modules,
**then it should be integrated into output of first module.
*/

//Microprocessor options:
//Include ST (R:R)+ R and such instructions (post inc/dec modes)
//`define CONFIG_ST_LD_INC_DEC


// !UNUSED! Define SIM if design should be simulated (includes non-synthesible constructions)
`define SIM 1

//Important processor definitions. (Instruction layout).
`define WORD_WIDTH		16 //Width of single machine word.
`define ADDR_WIDTH		32 //Width of machine adress bus.
`define MSB `WORD_WIDTH-1
`define LSB 0
//Fields widths 
`define OPCODE_WIDTH	6
`define REG_ADDR_WIDTH	5
`define CONST_WIDTH	`WORD_WIDTH
`define REL_ADDR_WIDTH `WORD_WIDTH + (`WORD_WIDTH - `OPCODE_WIDTH) - 1 //Note that -1 is because of sign
`define REL_ADDR_SHORT_WIDTH `WORD_WIDTH - `WORD_WIDTH - `OPCODE_WIDTH - 1

//Fields Offsets
`define OPCODE_OFFSET	0
`define REG_DST_OFFSET		`OPCODE_WIDTH + `OPCODE_OFFSET
`define REG_SRC_OFFSET		`REG_ADDR_WIDTH + `REG_DST_OFFSET
`define CONST_OFFSET		`REG_ADDR_WIDTH + `REG_SRC_OFFSET
`define REL_ADDR_OFFSET	`OPCODE_WIDTH + 1
`define ADDR_SIGN_OFFSET `OPCODE_WIDTH

//Memory buses widths. TODO: get rid of this macros
//DEPREACATED: subject to deprecation
`define RAMADDR_WIDTH `WORD_WIDTH
`define RAMREAD_WIDTH `WORD_WIDTH//`WORD_WIDTH*2
`define RAMWRITE_WIDTH `WORD_WIDTH

//Databus width( data flows through pipeline in this bus )
`define IFDB_WIDTH	`WORD_WIDTH*2
`define IDDB_WIDTH	`WORD_WIDTH*2
`define ALUDB_WIDTH	`WORD_WIDTH
`define MEMDB_WIDTH	`WORD_WIDTH
`define WBDB_WIDTH	`WORD_WIDTH

//Memory operation modes (LOAD/STORE)
`define MEM_LOAD 0
`define MEM_STORE 1

//Misc flag definitions
`define JUMP_FAR 1
`define JUMP_NEAR 0

//ALU MODES.
//Note that instead of a flag for every ALU operation,
//(as only one flag can be set at a time), the can be coded as number, and this is done.
//It simplifies design and implementation.
//Current operation, which alu does with operands is called MODE.
`define ALU_MODE_WIDTH 4	//16 possible operations - more than enough.
`define ALU_ADD 0			//Start of possible values of ALU operation modes
`define ALU_SUB 1
`define ALU_ADC 2
`define ALU_SUBC 3
`define ALU_NOT 4
`define ALU_AND 5
`define ALU_OR  6
`define ALU_XOR 7
`define ALU_ROL 8
`define ALU_ROR 9

//Control buses widths and flags.
//Main bus consists from three parts: ALU, MEM and WB - {WBCB, MEMCB, ALUCB}
`define ALUCB_WIDTH		1 + `ALU_MODE_WIDTH
`define MEMCB_WIDTH		1 + 1 + `ADDR_WIDTH
`define WBCB_WIDTH		1 + `REG_ADDR_WIDTH

`define CBUS_WIDTH	`ALUCB_WIDTH + `MEMCB_WIDTH + `WBCB_WIDTH
`define ALUCB_LSB	0
`define ALUCB_MSB	`ALUCB_LSB + `ALUCB_WIDTH-1 
`define MEMCB_LSB	`ALUCB_MSB+1
`define MEMCB_MSB	`MEMCB_LSB + `MEMCB_WIDTH-1
`define WBCB_LSB	`MEMCB_MSB+1
`define WBCB_MSB	`WBCB_LSB + `WBCB_WIDTH-1
//ALU control bus.
//|ALU_MODE|ALU_EN|
//|5------1|0----0| = 9
`define ALU_ENABLE		0
`define ALU_MODE_LSB	1
`define ALU_MODE_MSB `ALU_MODE_LSB+(`ALU_MODE_WIDTH-1)
//MEM control bus.
//|MEM_ADDR|MEM_LS|MEM_EN|
//|17-----2|1----1|0----0| = 18
`define MEM_ENABLE		0
`define MEM_LOADSTORE	1
`define MEM_ADDR_LSB	2
`define MEM_ADDR_MSB `MEM_ADDR_LSB+(`ADDR_WIDTH-1)
//WB control bus.
//|WB_ADDR|WB_EN|
//|5-----1|0---0| = 6
`define WB_ENABLE	0
`define WB_ADDR_LSB	1
`define WB_ADDR_MSB `WB_ADDR_LSB+(`REG_ADDR_WIDTH-1)

//Opcodes definitions
`define CONST_NOP 0
//Data transfer operations
`define OP_NOP	0
`define OP_LDI	2
`define OP_MOV	3
//Memory instructions. Note that they aren't implemented in hardware like "ST R+K,R and LD R,R+K" as
//It would require two big adders instead of one in current configuration to add address from register with
//offset. So these are ops unaffected by rule "Destination to the right, source to the left".
`define OP_ST	4	//ST (R:R), R
`define OP_LD	5	//LD R, (R:R)
//Arithmetical operations
//TODO: ADC, SUBC
`define OP_ADD	6
`define OP_ADC	7
`define OP_SUB	8
`define OP_SUBC	9
//Logical operations
`define OP_NOT  10
`define OP_AND	11
`define OP_OR	12
`define OP_XOR	13
//Shift/rotation operations
`define OP_ROL	14
`define OP_ROR	15
//Jump operations
`define OP_JZS	16
`define OP_JZL	17
`define OP_JCS	18
`define OP_JCL	19
`define OP_JNZS	20
`define OP_JNZL	21
`define OP_JNCS	22
`define OP_JNCL	23
`define OP_JMPS	24
`define OP_JMPL	25
`define OP_JMPR	26
