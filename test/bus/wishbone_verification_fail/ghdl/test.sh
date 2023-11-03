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
wb addr:0 32bit: 0x55555555
wb addr:0 32bit: 0x55555555
wb addr:0 32bit: 0x55555555
EOF
)
out_expected_2="line 19, bus_verify: address=0x00000008, read=0x55555555, expected=0x00000000, mask=0xFFFFFFFF"
out_expected_3="simulation failed"


if [[ ! $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] &&
   [[ "$out" =~ "$out_expected_2" ]] &&
   [[ "$out" =~ "$out_expected_3" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
