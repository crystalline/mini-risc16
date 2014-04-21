//Hazard detection and prevention module

//`include "CoreHeader.v"

module HazardDetect(
	//Clock is needed for storing previous register adresses
	//Though the module itself isn'y synchronous - just MUXes and control logic
	input wire gclk,
	//Interface to ID stage
	output reg [ `WORD_WIDTH-1:0 ] ID_RegDstData,
	output reg [ `WORD_WIDTH-1:0 ] ID_RegSrcData,
	output reg [ `WORD_WIDTH-1:0 ] ID_RegExtData,
	input wire [ `REG_ADDR_WIDTH-1:0 ] ID_RegDstAddr,
	input wire [ `REG_ADDR_WIDTH-1:0 ] ID_RegSrcAddr,
	input wire [ `REG_ADDR_WIDTH-1:0 ] ID_RegExtAddr,
	
	//Interface to RegFile
	input wire [ `WORD_WIDTH-1:0 ] RF_RegDstData,
	input wire [ `WORD_WIDTH-1:0 ] RF_RegSrcData,
	input wire [ `WORD_WIDTH-1:0 ] RF_RegExtData,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegDstAddr,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegSrcAddr,
	output wire [ `REG_ADDR_WIDTH-1:0 ] RF_RegExtAddr,
	
	//Interface to control buses of ALU, MEM and WB modules
	input wire	[ `CBUS_WIDTH-1:0 ] ALU_ControlBus, 
	input wire	[ `CBUS_WIDTH-1:0 ] MEM_ControlBus,
	input wire	[ `CBUS_WIDTH-1:0 ] WB_ControlBus,
	
	//Interface to databuses of ALU, MEM and WB
	input wire	[ `MEMDB_WIDTH-1:0 ] ALU_DataBus,
	input wire	[ `WBDB_WIDTH-1:0 ] MEM_DataBus,
	input wire	[ `WBDB_WIDTH-1:0 ] WB_DataBus
);
	//Extract information about register write requests from control buses,
	//particulary from it's part, related to WB stage
	
	//Extracting data from ALU bus:
	//WriteBack Control Bus
	wire [ `WBCB_WIDTH-1:0 ] ALU_WbControlBus = ALU_ControlBus[ `WBCB_MSB:`WBCB_LSB ];
	
	//WriteBack enable flag
	wire ALU_WbEnable = ALU_WbControlBus[ `WB_ENABLE ];
	
	//WriteBack adress
	wire [ `REG_ADDR_WIDTH-1:0 ] ALU_WriteAddr = ALU_WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ];
	
	//Same with MEM
	wire [ `WBCB_WIDTH-1:0 ] MEM_WbControlBus = MEM_ControlBus[ `WBCB_MSB:`WBCB_LSB ];
	wire MEM_WbEnable = MEM_WbControlBus[ `WB_ENABLE ];
	wire [ `REG_ADDR_WIDTH-1:0 ] MEM_WriteAddr = MEM_WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ];
	
	//And with WB
	wire [ `WBCB_WIDTH-1:0 ] WB_WbControlBus = WB_ControlBus[ `WBCB_MSB:`WBCB_LSB ];
	wire WB_WbEnable = WB_WbControlBus[ `WB_ENABLE ];
	wire [ `REG_ADDR_WIDTH-1:0 ] WB_WriteAddr = WB_WbControlBus[ `WB_ADDR_MSB:`WB_ADDR_LSB ];
	
	//Connect ID register adress buses to RF R.A.Bs to provide default data source
	//(If there is no need of shuffling data which hasn't been writen to RF yet)
	assign RF_RegDstAddr = ID_RegDstAddr;
	assign RF_RegSrcAddr = ID_RegSrcAddr;
	assign RF_RegExtAddr = ID_RegExtAddr;
	
	
	//According to this information, either connect ID to RF,
	//or to data that isn't written to RF yet and is somewhere in the pipeline

	//Get ID_RegDstRead
	always @(*) begin
		if ((ALU_WbEnable==1) && (ID_RegDstAddr == ALU_WriteAddr)) begin
			ID_RegDstData <= ALU_DataBus;
		end
		else if ((MEM_WbEnable==1) && (ID_RegDstAddr == MEM_WriteAddr)) begin
			ID_RegDstData <= MEM_DataBus;
		end
		else if ((WB_WbEnable==1) && (ID_RegDstAddr == WB_WriteAddr)) begin
			ID_RegDstData <= WB_DataBus;
		end
		else begin
			ID_RegDstData <= RF_RegDstData;
		end
	end
	
	//Get ID_RegSrcRead
	always @(*) begin
		if ((ALU_WbEnable==1) && (ID_RegSrcAddr == ALU_WriteAddr)) begin
			ID_RegSrcData <= ALU_DataBus;
		end
		else if ((MEM_WbEnable==1) && (ID_RegSrcAddr == MEM_WriteAddr)) begin
			ID_RegSrcData <= MEM_DataBus;
		end
		else if ((WB_WbEnable==1) && (ID_RegSrcAddr == WB_WriteAddr)) begin
			ID_RegSrcData <= WB_DataBus;
		end
		else begin
			ID_RegSrcData <= RF_RegSrcData;
		end
	end
	
	//Get ID_RegExtRead
	always @(*) begin
		if ((ALU_WbEnable==1) && (ID_RegExtAddr == ALU_WriteAddr)) begin
			ID_RegExtData <= ALU_DataBus;
		end
		else if ((MEM_WbEnable==1) && (ID_RegExtAddr == MEM_WriteAddr)) begin
			ID_RegExtData <= MEM_DataBus;
		end
		else if ((WB_WbEnable==1) && (ID_RegExtAddr == WB_WriteAddr)) begin
			ID_RegExtData <= WB_DataBus;
		end
		else begin
			ID_RegExtData <= RF_RegExtData;
		end
	end
endmodule
