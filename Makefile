PWD=$(shell pwd)

ifeq ($(tool),)
	tool := ghdl
endif

test_array:
	@cd ./test/array/array_get_out_pos/${tool}/	&& ./test.sh
	@cd ./test/array/array_get/${tool}/			&& ./test.sh
	@cd ./test/array/array_pointer/${tool}/		&& ./test.sh
	@cd ./test/array/array_set_out_pos/${tool}/	&& ./test.sh
	@cd ./test/array/array_set/${tool}/			&& ./test.sh
	@cd ./test/array/array_size/${tool}/		&& ./test.sh
	@cd ./test/array/array_zero_size/${tool}/	&& ./test.sh
	@cd ./test/array/array/${tool}/				&& ./test.sh

test_basic:
	@cd ./test/basic/abort/${tool}/			&& ./test.sh
	@cd ./test/basic/const_2/${tool}/		&& ./test.sh
	@cd ./test/basic/const/${tool}/			&& ./test.sh
	@cd ./test/basic/else/${tool}/			&& ./test.sh
	@cd ./test/basic/elsif/${tool}/			&& ./test.sh
	@cd ./test/basic/finish/${tool}/		&& ./test.sh
	@cd ./test/basic/if/${tool}/			&& ./test.sh
	@cd ./test/basic/include_2/${tool}/		&& ./test.sh
	@cd ./test/basic/include/${tool}/		&& ./test.sh
	@cd ./test/basic/loop/${tool}/			&& ./test.sh
	@cd ./test/basic/var_2/${tool}/			&& ./test.sh
	@cd ./test/basic/var_3/${tool}/			&& ./test.sh
	@cd ./test/basic/var/${tool}/			&& ./test.sh

test_bus:
	@cd ./test/bus/wishbone_timeout_read/${tool}/		&& ./test.sh
	@cd ./test/bus/wishbone_timeout_write/${tool}/		&& ./test.sh
	@cd ./test/bus/wishbone_verification_fail/${tool}/	&& ./test.sh
	@cd ./test/bus/wishbone_verification/${tool}/		&& ./test.sh
	@cd ./test/bus/wishbone/${tool}/					&& ./test.sh

test_file:
	@cd ./test/file/append_array/${tool}/		&& ./test.sh
	@cd ./test/file/pointer/${tool}/			&& ./test.sh
	@cd ./test/file/read_all_array/${tool}/		&& ./test.sh
	@cd ./test/file/read_array/${tool}/			&& ./test.sh
	@cd ./test/file/statuses/${tool}/			&& ./test.sh
	@cd ./test/file/write_array/${tool}/		&& ./test.sh

test_interrupt:
	@cd ./test/interrupt/plain/${tool}/			 && ./test.sh

test_lines:
	@cd ./test/lines/append_array/${tool}/			&& ./test.sh
	@cd ./test/lines/append_text/${tool}/			&& ./test.sh
	@cd ./test/lines/delete_all_array/${tool}/		&& ./test.sh
	@cd ./test/lines/delete_array/${tool}/			&& ./test.sh
	@cd ./test/lines/get_array/${tool}/				&& ./test.sh
	@cd ./test/lines/insert_array/${tool}/			&& ./test.sh
	@cd ./test/lines/insert_text/${tool}/			&& ./test.sh
	@cd ./test/lines/pointer/${tool}/				&& ./test.sh
	@cd ./test/lines/set_array/${tool}/				&& ./test.sh
	@cd ./test/lines/set_text/${tool}/				&& ./test.sh
	@cd ./test/lines/size/${tool}/					&& ./test.sh

test_others:
	@cd ./test/others/call/${tool}/						&& ./test.sh
	@cd ./test/others/end_proc/${tool}/					&& ./test.sh
	@cd ./test/others/hello_world/${tool}/				&& ./test.sh
	@cd ./test/others/log_with_substitutions/${tool}/	&& ./test.sh
	@cd ./test/others/log/${tool}/						&& ./test.sh
	@cd ./test/others/marker/${tool}/					&& ./test.sh
	@cd ./test/others/proc/${tool}/						&& ./test.sh
	@cd ./test/others/random/${tool}/					&& ./test.sh
	@cd ./test/others/return_call/${tool}/				&& ./test.sh
	@cd ./test/others/seed/${tool}/						&& ./test.sh
	@cd ./test/others/trace/${tool}/					&& ./test.sh
	@cd ./test/others/wait/${tool}/						&& ./test.sh

test_signals:
	@cd ./test/signal/signal_read/${tool}/			&& ./test.sh
	@cd ./test/signal/signal_verify_fail/${tool}/	&& ./test.sh
	@cd ./test/signal/signal_verify/${tool}/		&& ./test.sh
	@cd ./test/signal/signal_write/${tool}/			&& ./test.sh

test_variable:
	@cd ./test/variable/add_2/${tool}/				&& ./test.sh
	@cd ./test/variable/add/${tool}/				&& ./test.sh
	@cd ./test/variable/and/${tool}/				&& ./test.sh
	@cd ./test/variable/div/${tool}/				&& ./test.sh
	@cd ./test/variable/equ_2/${tool}/				&& ./test.sh
	@cd ./test/variable/equ/${tool}/				&& ./test.sh
	@cd ./test/variable/mul/${tool}/				&& ./test.sh
	@cd ./test/variable/or/${tool}/					&& ./test.sh
	@cd ./test/variable/sub/${tool}/				&& ./test.sh
	@cd ./test/variable/xor/${tool}/				&& ./test.sh

ghdl:
	@echo "use ghdl for testing"
	@$(MAKE) test tool=ghdl

modelsim:
	@echo "use modelsim for testing"
	@$(MAKE) test tool=modelsim

ghdl_docker:
	@docker run -it -v ${PWD}:/work -w /work ghdl/ghdl:ubuntu22-llvm-11 make ghdl

test: test_array test_basic test_bus test_file test_interrupt test_lines test_others test_signals test_variable

.PHONY: $(TARGETS)
