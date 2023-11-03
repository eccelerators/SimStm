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
out_expected="test finished with no errors!!"
out_expected_2="line 13"
out_expected_3="line 23"
out_not_expected="line 17"


if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ ! "$out" =~ "$out_not_expected" ]] &&
   [[ "$out" =~ "$out_expected" ]] &&
   [[ "$out" =~ "$out_expected_2" ]] &&
   [[ "$out" =~ "$out_expected_3" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
