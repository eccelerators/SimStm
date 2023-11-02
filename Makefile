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
	@cd ./test/basic/include_2/ghdl/           && ./test.sh
	@cd ./test/basic/loop/ghdl/              && ./test.sh
	@cd ./test/basic/var_2/ghdl/             && ./test.sh
	@cd ./test/basic/var_3/ghdl/             && ./test.sh
	@cd ./test/basic/var/ghdl/               && ./test.sh

test_array:
	@cd ./test/array/array/ghdl/                && ./test.sh
	@cd ./test/array/array_get/ghdl/            && ./test.sh
	@cd ./test/array/array_get_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_pointer/ghdl/        && ./test.sh
	@cd ./test/array/array_set/ghdl/            && ./test.sh
	@cd ./test/array/array_set_out_pos/ghdl/    && ./test.sh
	@cd ./test/array/array_size/ghdl/           && ./test.sh
	@cd ./test/array/array_zero_size/ghdl/      && ./test.sh

start_ghdl_docker:
	docker run -it -v ${PWD}:/work -w /work ghdl/ghdl:ubuntu22-llvm-11

.PHONY: ghdl test $(TARGETS)

test: test_basic test_array
