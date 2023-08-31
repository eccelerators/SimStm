#!/usr/bin/bash

set -e

WorkingDir=$(pwd)
TbDir=$WorkingDir/..
TbSrcDir=$TbDir/../../../src
IpDir=$TbDir/../../../ip

echo "analyze testbench"
while read p; do
  ghdl -a --std=08 $TbSrcDir/$p
done <./../../../inputorder.txt

echo "analyze user files"
ghdl -a --std=08 $IpDir/wb_ram.vhd

echo "analyze toplevel"
ghdl -a --std=08 $TbDir/tb_top.vhd

echo "elaborate"
ghdl -e --std=08  --std=08 tb_top

echo "start simulation"
./tb_top --stop-time=1000000ns
