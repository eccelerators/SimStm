#!/bin/bash

RED='\033[0;31m'
GREEN='\e[32m'
NC='\033[0;0m'

base=$PWD/../../../../
test_name=./$(dirname ${PWD#$(realpath $base)/})

ant unit_test_general.build > build.log 2>&1

# run simulation
vsim -t ps -L work tb_top -batch -do run.do > out.log 2> error.log
return_value=$?
set -e

error=$(cat error.log)
error_not_contain="error"

out=$(cat out.log)
out_expected=$(cat <<EOF
# wb addr:0 32bit: 0x55555555
# wb addr:4 32bit: 0xAAAAAAAA
# wb addr:5 32bit: 0xFFFFFFFF
# wb addr:0 8bit: 0x12
# wb addr:1 8bit: 0x34
# wb addr:1 8bit: 0x56
# wb addr:0 32bit: 0x563412
# wb addr:0 16bit: 0x1234
# wb addr:2 16bit: 0x4567
# wb addr:0 32bit: 0x45671234
# wb addr:5 16bit: 0x1234
# wb addr:4 32bit: 0x123400
EOF
)
out_expected_2="test finished with no errors!!"

if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] &&
   [[ "$out" =~ "$out_expected_2" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
