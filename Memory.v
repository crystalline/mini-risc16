//`include "CoreHeader.v"

//Ram unit for Von-Neumann architecture - designed for direct connection witn ram, not mman.
//Memory Save/Load unit. Designed to be used with asyncronous dual port SRAM.
module Memory(
	input wire	gclk,
	
	output reg stall,	//Flag causes stall if IF, ID and ALU
	
	//Data bus
	input wire	[ `MEMDB_WIDTH-1:0 ] InDataBus,
	output reg	[ `WBDB_WIDTH-1:0 ] OutDataBus,
	
	//Control bus
	input wire	[ `CBUS_WIDTH-1:0 ] InControlBus,
	output reg	[ `CBUS_WIDTH-1:0 ] OutControlBus,
	
	//RAM write interface
	output reg MemWriteFlag,
	output wire [ `RAMADDR_WIDTH-1:0 ] MemWriteAddr,
	output reg [ `WORD_WIDTH-1:0 ] MemWriteData,
	
	//RAM read interface, also connected to MemBypasser, as read process is complex
	output reg MBP_RAMAddrSel,	//MBP->RAM adress mux selector
	output reg MBP_IFDataSel,	//MBP->IF  data mux selector
	output wire [ `RAMADDR_WIDTH-1:0 ] MemReadAddr,	//Memory adress register
	input wire [ `WORD_WIDTH-1:0 ] MemReadData,		//Memory read register
	output reg [ `WORD_WIDTH-1:0 ] Mem_IFBypassData	//MBP->IF data bypasser data
	
);
	//Extract MemControlBus form main Control Bus
	wire [ `MEMCB_WIDTH-1:0 ] MemControlBus = InControlBus[ `MEMCB_MSB:`MEMCB_LSB ];
	
	//Extract slice of MemControlBus, containing address for MEM operation...
	wire [ `ADDR_WIDTH-1:0 ] ControlAddr = MemControlBus[ `MEM_ADDR_MSB:`MEM_ADDR_LSB ];
		
	//...MemEnable flag...
	wire MemEnable = MemControlBus[ `MEM_ENABLE ];
	
	//...And MemLoadStore flag...
	wire MemLoadStore = MemControlBus[ `MEM_LOADSTORE ];
	
	// !MEMORY WIDTH!
	assign MemReadAddr  = ControlAddr[ `WORD_WIDTH-1:0 ];
	assign MemWriteAddr = ControlAddr[ `WORD_WIDTH-1:0 ];

	//Current module state
	reg NextState;
	reg CurState;
	
	//Temporary registers to store data from memory during pipeline stall 
	reg [ `WORD_WIDTH-1:0 ] TempData;

	//Start-up conditions
	initial begin
		stall <= 0;
		CurState <= 0;
		NextState <= 0;
	end
	
	always @( posedge gclk ) begin
		CurState <= NextState;
		
		OutControlBus <= InControlBus;
		
		case( CurState )
			0: begin
				OutDataBus <= InDataBus;
			end
			1: begin
				OutDataBus <= MemReadData;
			end
		endcase
		
	end
	
	always @( * ) begin
		case( CurState )
		
		0: begin
			if( MemEnable ) begin
				if( MemLoadStore == `MEM_LOAD ) begin
					NextState <= 1;
					stall <= 1;
					MBP_RAMAddrSel <= 1;
					MBP_IFDataSel <= 1;
					Mem_IFBypassData <= 16'hBEEF;
					TempData <= MemReadData;
				end
				//else begin
					//TODO: writing
				//end
			end
			else begin
				NextState <= 0;
				stall <= 0;
				MBP_RAMAddrSel <= 0;
				MBP_IFDataSel <= 0;
			end
		end
		
		1: begin
			NextState <= 0;
			stall <= 0;
			MBP_RAMAddrSel <= 0;
			MBP_IFDataSel <= 1;
			Mem_IFBypassData <= TempData;
		end
		
		endcase
	end
	
	
endmodule
