//`include "CoreHeader.v"

//Writeback module: writes data to Register File.
//Note that it is asynchronous, i.e. it doesn't require a clock
//It is connected directly to register file

module WriteBack(
	//Memory stage connection
	input wire	gclk,
	input wire	[ `WBDB_WIDTH-1:0 ] InDataBus,
	input wire	[ `CBUS_WIDTH-1:0 ] InControlBus,
	
	//Register file connection.
	output wire RegWriteEnable,
	output wire	[ `REG_ADDR_WIDTH-1:0 ] RegWriteAddr,
	output wire	[ `WORD_WIDTH-1:0 ] RegWriteData
);
	//Extract WbControlBus from ControlBus 
	wire [ `WBCB_WIDTH-1:0 ] WbControlBus = InControlBus[ `WBCB_MSB:`WBCB_LSB ];
	
	//Extract Control Adress from WbControlBus and connect it to Register Write adress
	wire [ `REG_ADDR_WIDTH-1:0 ] ControlAddr = WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ];
	assign RegWriteAddr = ControlAddr;
	
	//Extract Enable Flag from ControlBus and connect it to REgister WriteENable
	wire WbEnable = WbControlBus[ `WB_ENABLE ];
	assign RegWriteEnable = WbEnable;
	
	//Connect RegFile's WriteData register to output of databus
	assign RegWriteData = InDataBus;
endmodule

