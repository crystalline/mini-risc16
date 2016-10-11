#A Simple 16-bit RISC CPU ISA & implementation  
This is an example of how one could approach design and implementation of a reduced instruction set computer with custom ISA. 16 bit RISC design presented here is implemented in Verilog HDL. The CPU can be simulated using open-source Icarus Verilog simulator. Results can be viewed in GtkWave waveform viewer.  

#How to run it  
Clone the repo:  
```bash
git clone https://github.com/crystalline/mini-risc16`
cd mini-risc16
```

If you are using debian-like linux distro (e.g. ubuntu) you can install dependencies with apt:  
`sudo apt-get install iverilog gtkwave`

Run the simulation of RISC CPU executing a simple loop:  
`iverilog TestCore.v -o sim && vvp sim`

View the waveforms dumped by the simulation:  
`gtkwave TestCore.vcd`

Now you can inspect the state of the CPU by appending variables to "Signals" list in GTKWave GUI:
![Waveforms](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/gtkwave.png "Waveforms")

###ISA summary (in russian)
![ISA](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/isa.png "ISA")
###Opcode format (in russian)
![Opcodes](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/opcode.png "Opcodes")
###Pipeline architecture (in russian)
![Pipeline](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/pipeline.png "Pipeline")
