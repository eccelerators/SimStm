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
00000000 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
00000001 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
00000002 00000001 0000000A 00000002 0000000B 7FFFFFFF 80000000 FFFFFFFF 
Check if file is readable, which doesn't exist 
STATUS_NAME_ERROR
Check if file is writeable, which doesn't exist 
STATUS_OK
Check if file is appendable, which doesn't exist 
STATUS_OK
Main test finished
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
