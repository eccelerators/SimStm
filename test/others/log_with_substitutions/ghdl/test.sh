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
test_variable_1: 0xA1
test_variable_1: 0xA1 test_variable_2: 0xB2
test_variable_1: 0xA1 test_variable_2: 0xB2 test_variable_3: 0xB2
test_variable_1: 0xA1 test_variable_2: 0xB2 test_variable_3: 0xC3 test_variable_4: 0xE4
test_variable_1: 0xA1 test_variable_2: 0xB2 test_variable_3: 0xC3 test_variable_4: 0xE4 test_variable_5: 0xF5
0xA10xB20xC30xE40xF5
test_variable_2: 0xB2
test_variable_3: 0xC3
test_variable_4: 0xE4
test_variable_5: 0xF5
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
