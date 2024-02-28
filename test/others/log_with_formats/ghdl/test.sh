#!/usr/bin/bash

RED='\033[0;31m'
GREEN='\e[32m'
NC='\033[0;0m'

base=$PWD/../../../../
test_name=./$(dirname ${PWD#$(realpath $base)/})

# run simulation
./run.sh >out.log 2>error.log
return_value=$?
set -e

error=$(cat error.log)
error_not_contain="error"

out=$(cat out.log)
out_expected=$(cat <<EOF
start simulation
test_variable_1: 0xA1
test_variable_1: 0xA1 test_variable_2: 0xB2
test_variable_1: 0xA1 test_variable_2: 0xB2 test_variable_3: 0xB2
test_variable_1: 0xA1 test_variable_2: 0xB2 test_variable_3: 0xC3 test_variable_4: 0xE4
test_variable_1: 0xA1
test_variable_1: 0xA1 test_variable_2: 178 test_variable_3: 0o303 test_variable_4: 0b11100100
test_variable_1: 0xA1
test_variable_1: 0xA1 test_variable_2: 178 test_variable_3: 0o303 test_variable_4: 0b11100100
label: testContent
file: './../test.stm', line: '11'
file: "./../test.stm", line: "11"
file: "./../test.stm", line: "11"
file: './../test.stm', line: '11'
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
