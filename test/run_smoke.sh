#!/usr/bin/env sh
set -eu
veryl build
iverilog -g2012 -s smoke_tb -o target/smoke.vvp target/chrysoberyl.sv test/smoke_tb.sv
vvp target/smoke.vvp
iverilog -g2012 -s rv32i_tb -o target/rv32i.vvp target/chrysoberyl.sv test/rv32i_tb.sv
vvp target/rv32i.vvp
iverilog -g2012 -s rv32c_tb -o target/rv32c.vvp target/chrysoberyl.sv test/rv32c_tb.sv
vvp target/rv32c.vvp
