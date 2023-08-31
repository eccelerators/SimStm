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
wb addr:0 32bit: 0x55555555
wb addr:0 32bit: 0x55555555
wb addr:0 32bit: 0x55555555
EOF
)
out_expected_2="test finished with no errors!!"

if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] &&
   [[ "$out" =~ "$out_expected_2" ]]; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
