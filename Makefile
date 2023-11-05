PWD=$(shell pwd)

test_basic:
	@cd ./test/basic/abort/ghdl/             && ./test.sh
	@cd ./test/basic/const_2/ghdl/           && ./test.sh
	@cd ./test/basic/const/ghdl/             && ./test.sh
	@cd ./test/basic/elsif/ghdl/             && ./test.sh
	@cd ./test/basic/else/ghdl/              && ./test.sh
	@cd ./test/basic/finish/ghdl/            && ./test.sh
	@cd ./test/basic/if/ghdl/                && ./test.sh
	@cd ./test/basic/include/ghdl/           && ./test.sh
	@cd ./test/basic/include_2/ghdl/         && ./test.sh
	@cd ./test/basic/loop/ghdl/              && ./test.sh
	@cd ./test/basic/var_2/ghdl/             && ./test.sh
	@cd ./test/basic/var_3/ghdl/             && ./test.sh
	@cd ./test/basic/var/ghdl/               && ./test.sh
	
test_variable:
	@cd ./test/variable/add_2/ghdl/             && ./test.sh
	@cd ./test/variable/add/ghdl/               && ./test.sh
	@cd ./test/variable/and/ghdl/               && ./test.sh
	@cd ./test/variable/mul/ghdl/               && ./test.sh
	@cd ./test/variable/or/ghdl/                && ./test.sh
	@cd ./test/variable/div/ghdl/               && ./test.sh
	@cd ./test/variable/equ_2/ghdl/             && ./test.sh
	@cd ./test/variable/equ/ghdl/               && ./test.sh
	@cd ./test/variable/sub/ghdl/               && ./test.sh
	@cd ./test/variable/xor/ghdl/               && ./test.sh

test_array:
	@cd ./test/array/array/ghdl/                && ./test.sh
	@cd ./test/array/array_get/ghdl/            && ./test.sh
	@cd ./test/array/array_get_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_pointer/ghdl/        && ./test.sh
	@cd ./test/array/array_set/ghdl/            && ./test.sh
	@cd ./test/array/array_set_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_size/ghdl/           && ./test.sh
	@cd ./test/array/array_zero_size/ghdl/      && ./test.sh
	
test_others:
	@cd ./test/others/wait/ghdl/                     && ./test.sh
	@cd ./test/others/trace/ghdl/                    && ./test.sh
	@cd ./test/others/call/ghdl/                     && ./test.sh
	@cd ./test/others/proc/ghdl/                     && ./test.sh
	@cd ./test/others/return_call/ghdl/              && ./test.sh
	@cd ./test/others/end_proc/ghdl/                 && ./test.sh
	@cd ./test/others/log/ghdl/                      && ./test.sh
	@cd ./test/others/log_with_substitutions/ghdl/   && ./test.sh	
	@cd ./test/others/random/ghdl/                   && ./test.sh
	@cd ./test/others/seed/ghdl/                     && ./test.sh
	@cd ./test/others/marker/ghdl/                   && ./test.sh
	
test_signals:
	@cd ./test/signal/signal_read/ghdl/         && ./test.sh
	@cd ./test/signal/signal_write/ghdl/        && ./test.sh
	@cd ./test/signal/signal_verify/ghdl/       && ./test.sh
	@cd ./test/signal/signal_verify_fail/ghdl/  && ./test.sh
	
test_bus:
	@cd ./test/bus/wishbone/ghdl/                   && ./test.sh
	@cd ./test/bus/wishbone_verification/ghdl/      && ./test.sh
	@cd ./test/bus/wishbone_verification_fail/ghdl/ && ./test.sh
	@cd ./test/bus/wishbone_timeout_read/ghdl/      && ./test.sh
	@cd ./test/bus/wishbone_timeout_write/ghdl/     && ./test.sh
	
test_lines:
	@cd ./test/lines/append_array/ghdl/             && ./test.sh
	@cd ./test/lines/append_text/ghdl/              && ./test.sh
	@cd ./test/lines/get_array/ghdl/                && ./test.sh
	@cd ./test/lines/set_array/ghdl/                && ./test.sh
	@cd ./test/lines/set_text/ghdl/                 && ./test.sh
	@cd ./test/lines/insert_array/ghdl/             && ./test.sh
	@cd ./test/lines/insert_text/ghdl/              && ./test.sh
	@cd ./test/lines/delete_array/ghdl/             && ./test.sh
	@cd ./test/lines/delete_all_array/ghdl/         && ./test.sh
	@cd ./test/lines/size/ghdl/                     && ./test.sh
	@cd ./test/lines/pointer/ghdl/                  && ./test.sh
	
test_file:
	@cd ./test/file/write_array/ghdl/             && ./test.sh
	@cd ./test/file/read_all_array/ghdl/              && ./test.sh
	@cd ./test/file/append_array/ghdl/             && ./test.sh

start_ghdl_docker:
	docker run -it -v ${PWD}:/work -w /work ghdl/ghdl:ubuntu22-llvm-11

.PHONY: ghdl test $(TARGETS)

# test: test_basic test_variable test_array test_others test_signals test_bus test_lines
test: test_file
