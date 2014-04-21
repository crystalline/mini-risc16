#Simple RISC-16 CPU
This is an example of how one could approach design and implementation of reduced instruction set computer with custom ISA.
16 bit RISC design presented here is implemented in Verilog HDL.
CPU can be simulated with Icarus Verilog, results can be viewed in GtkWave, default simulation is run by typing "make" while in project directory.
If you are using debian-like linux distro (e.g. ubuntu) you can type "sudo apt-get install iverilog gtkwave", and that's enough to run simulation right out of the box.
Happy hacking!

###ISA summary (in russian)
![ISA](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/isa.png "ISA")
###Opcode format (in russian)
![Opcodes](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/opcode.png "Opcodes")
###Pipeline architecture (in russian)
![Pipeline](https://raw.githubusercontent.com/crystalline/mini-risc16/master/docs/pipeline.png "Pipeline")
