#!/usr/bin/bash

set -e

WorkingDir=$(pwd)
TbDir=$WorkingDir/..
TbSrcDir=$TbDir/../../../src
TbSrcCustDir=$TbDir/../../../src_to_customize
IpDir=$TbDir/../../../ip

rm -f user_data_out.dat

echo "analyze testbench"
ghdl -a --std=08 $TbSrcDir/tb_base_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_base_pkg_body.vhd
ghdl -a --std=08 $TbSrcDir/tb_instructions_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_interpreter_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_interpreter_pkg_body.vhd
ghdl -a --std=08 $TbSrcDir/tb_bus_avalon_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_bus_axi4lite_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_bus_wishbone_pkg.vhd
ghdl -a --std=08 $TbSrcCustDir/tb_bus_pkg.vhd
ghdl -a --std=08 $TbSrcCustDir/tb_signals_pkg.vhd
ghdl -a --std=08 $TbSrcDir/tb_simstm.vhd

echo "analyze user files"
ghdl -a --std=08 $IpDir/wb_ram.vhd

echo "analyze toplevel"
ghdl -a --std=08 $TbDir/tb_top.vhd

echo "elaborate"
ghdl -e --std=08 tb_top

echo "start simulation"
./tb_top --stop-time=1000000ns
