//Simulation TestBench, successor to TestCore.

//Global timescale
`timescale 10ns/100ps

`include "RiscCpu.v"

module TestBench( );

	wire gclk;
	reg PowerOn;
	wire MemWriteFlag;
	
	wire [ `WORD_WIDTH-1:0 ] MemReadData;
	wire [ `WORD_WIDTH-1:0 ] MemWriteData;
	wire [ `WORD_WIDTH-1:0 ] MemReadAddr;
	wire [ `WORD_WIDTH-1:0 ] MemWriteAddr; 
	
	ClockGen clk( .clk(gclk) ); //Clock generator
	
	//Main memory
	defparam Memory.WORD_WIDTH = `RAMREAD_WIDTH;
	defparam Memory.ADDR_WIDTH = `RAMADDR_WIDTH;
	SyncRam Memory(
		.gclk( gclk ),
		.WriteEnable( MemWriteFlag ), 
		.WriteAddr( MemWriteAddr ),
		.WriteData( MemWriteData ),
		.ReadAddr( MemReadAddr ),
		.ReadData( MemReadData )
	);
	
	RiscCpu CPU (
		.gclk( gclk ),
		.PowerOn( PowerOn ),
		
		.MemWriteFlag( MemWriteFlag ),
		.MemReadData( MemReadData ),
		.MemWriteData( MemWriteData ),
		.MemReadAddr( MemReadAddr ),
		.MemWriteAddr( MemWriteAddr )
	);
	
	integer i;
	integer file;
	
	//Dump contents of CPU registers
	task DumpRegState;
	begin
		for(i=0; i<32; i=i+4) begin
			$display( "|%d| |%d| |%d| |%d|",
				CPU.RF.RegData[ i+0 ],
				CPU.RF.RegData[ i+1 ],
				CPU.RF.RegData[ i+2 ],
				CPU.RF.RegData[ i+3 ]
			);
		end
	end
	endtask
	
	initial begin
		
		//Load test loop to memory
		Memory.data[ 0 ] <= 0;
		Memory.data[ 1 ] <= 16'h00C2;//LDI	R3, 1                             
		Memory.data[ 2 ] <= 16'h0001;//
		Memory.data[ 3 ] <= 16'h0002;//LDI	R0, F
		Memory.data[ 4 ] <= 16'h000F;//
		Memory.data[ 5 ] <= 16'h1008;//SUB R0,R2
		Memory.data[ 6 ] <= 16'h0110;//JZS PC+2 (PC+4-2)
		Memory.data[ 7 ] <= 16'h0045;//16'h0884;//ST (R1:R2), R2
		Memory.data[ 8 ] <= 16'h1886;//ADD R2,R3         
		Memory.data[ 9 ] <= 16'h0458;//JMPS PC-8 (PC-6-2)
		Memory.data[ 10] <= 16'h0118;//JMPS PC-2 (PC-0-2)
		Memory.data[ 11] <= 16'hFFFF;
		Memory.data[ 12] <= 16'h0;
		Memory.data[ 13] <= 16'h0;
		Memory.data[ 14] <= 16'h0;
		Memory.data[ 15] <= 16'h0;                        
		Memory.data[ 16] <= 16'h0;
		Memory.data[ 17] <= 16'h0;
		Memory.data[ 18] <= 16'h0;
		Memory.data[ 19] <= 16'h0;
		
		//Dump variables to .vcd file for viewing. 
		$dumpfile("TestCore.vcd");
		$dumpvars;
	    
		//Monitor loop register
		$monitor( "R2 = |%d|", RF.RegData[ 2 ]);
		
	    //Create PowerOn signal (begin core init)
	    PowerOn <= 1;
		#2
		PowerOn <= 0;
		
		//Wait for sim to process
		#512
		
		//Dump registers
		DumpRegState();
		
		$finish;
		
	end
endmodule
