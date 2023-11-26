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
# enter if
# enter if
# enter if
# enter else
# enter else
# enter elsif
# enter if
# enter if
# enter if
# enter else
# enter elsif
# enter if
# enter else
# enter elsif
# enter if
# enter if
# enter if
# enter if
# enter else
# enter elsif
# enter if
# enter if
# enter else
# enter elsif
# enter if
# enter if
# enter if
# enter if
# enter if
# enter else
# enter elsif
# test multi if (1)
# enter multi if 1
# enter multi if 2
# enter multi if 3
# enter multi if 4
# test multi if (2)
# enter multi if 1
# test multi if (3)
# enter multi if 1
# test multi if (4)
# enter multi else 1
# test multi if (5)
# enter multi else 1
# enter multi else 2
EOF
)
out_not_contain="No enter if"

if [[ $return_value == 0 ]] &&
   [[ ! "$error" =~ "$error_not_contain" ]] &&
   [[ ! "$out" =~ "$out_not_contain" ]] &&
   [[ "$out" =~ "$out_expected" ]] ; then
    echo -e "$test_name -> ${GREEN}successfull${NC}"
    exit 0
else
    echo -e "$test_name -> ${RED}error${NC}"
    exit 1
fi
