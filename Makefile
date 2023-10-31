PWD=$(shell pwd)

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

test: test_array
