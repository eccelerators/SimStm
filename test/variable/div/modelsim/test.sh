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
# test_variable_1: 0x01F4
# test_variable_2: 0x1388
# test_variable_1: 0x32
# test_variable_2: 0xFA
# test_variable_1: 0x0A
# test_variable_2: 0x02
EOF
)

if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
