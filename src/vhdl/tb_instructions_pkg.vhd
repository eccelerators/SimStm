-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- Author: sckoarn
--
-- Description :  The the testbench package body file.
--
------------------------------------------------------------------------------
--  This file is part of The VHDL Test Bench Package.
--
--  Redistribution and use in source and binary forms, with or without
--  modification, are permitted provided that the following conditions are met:
--
--  1. Redistributions of source code must retain the above copyright notice,
--     this list of conditions and the following disclaimer.
--
--  2. Redistributions in binary form must reproduce the above copyright notice,
--     this list of conditions and the following disclaimer in the documentation
--     and/or other materials provided with the distribution.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------------
-- Changes:
--
-- Materially changed 2023 by Eccelerators, please diff with original at
-- https://github.com/sckoarn/VHDL-Test-Bench/blob/main/source/tb_pkg_header.vhdl
--
-- Adapt to new fix SimStm language
--
-- ----------------------------------------------------------------------------

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;

package tb_instructions_pkg is

    -- basic
    constant INSTR_NAMESPACE : string := "namespace";
    constant INSTR_END_NAMESPACE : string := "end_namespace";
    constant INSTR_ABORT : string := "abort";
    constant INSTR_CONST : string := "const";
    constant INSTR_ELSE : string := "else";
    constant INSTR_ELSIF : string := "elsif";
    constant INSTR_END_IF : string := "end_if";
    constant INSTR_END_LOOP : string := "end_loop";
    constant INSTR_FINISH : string := "finish";
    constant INSTR_STOP : string := "stop";
    constant INSTR_IF : string := "if";
    constant INSTR_INCLUDE : string := "include";
    constant INSTR_LOOP : string := "loop";
    constant INSTR_VAR : string := "var";
    constant INSTR_VAR_PAR_CLOSE : string := "var_)";

    -- variables
    constant INSTR_ADD : string := "add";
    constant INSTR_AND : string := "and";
    constant INSTR_DIV : string := "div";
    constant INSTR_REM : string := "rem";
    constant INSTR_EQU : string := "equ";
    constant INSTR_EQU_PAR_CLOSE : string := "equ_)";
    constant INSTR_VAR_POINTER_COPY : string := "var_pointer_copy";
    constant INSTR_VAR_POINTER_COPY_PAR_CLOSE : string := "var_pointer_copy_)";
    constant INSTR_MUL : string := "mul";
    constant INSTR_SHL : string := "shl";
    constant INSTR_SHR : string := "shr";
    constant INSTR_INV : string := "inv";
    constant INSTR_OR : string := "or";
    constant INSTR_SUB : string := "sub";
    constant INSTR_XOR : string := "xor";
    constant INSTR_LD : string := "ld";
    constant INSTR_VAR_VERIFY : string := "var_verify";

    -- signals
    constant INSTR_SIGNAL : string := "signal";
    constant INSTR_SIGNAL_PAR_CLOSE : string := "signal_)";
    constant INSTR_SIGNAL_READ : string := "signal_read";
    constant INSTR_SIGNAL_VERIFY : string := "signal_verify";
    constant INSTR_SIGNAL_WRITE : string := "signal_write";
    constant INSTR_SIGNAL_POINTER_COPY : string := "signal_pointer_copy";
    constant INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE : string := "signal_pointer_copy_)";
    constant INSTR_SIGNAL_POINTER_SET : string := "signal_pointer_set";
    constant INSTR_SIGNAL_POINTER_GET : string := "signal_pointer_get";

    -- bus
    constant INSTR_BUS : string := "bus";
    constant INSTR_BUS_PAR_CLOSE : string := "bus_)";
    constant INSTR_BUS_READ : string := "bus_read";
    constant INSTR_BUS_VERIFY : string := "bus_verify";
    constant INSTR_BUS_WRITE : string := "bus_write";
    constant INSTR_BUS_TIMEOUT_SET : string := "bus_timeout_set";
    constant INSTR_BUS_TIMEOUT_GET : string := "bus_timeout_get";
    constant INSTR_BUS_POINTER_COPY : string := "bus_pointer_copy";
    constant INSTR_BUS_POINTER_COPY_PAR_CLOSE : string := "bus_pointer_copy_)";
    constant INSTR_BUS_POINTER_SET : string := "bus_pointer_set";
    constant INSTR_BUS_POINTER_GET : string := "bus_pointer_get";

    -- file
    constant INSTR_FILE : string := "file";
    constant INSTR_FILE_PAR_CLOSE : string := "file_)";
    constant INSTR_FILE_READABLE : string := "file_readable";
    constant INSTR_FILE_WRITABLE : string := "file_writable";
    constant INSTR_FILE_APPENDABLE : string := "file_appendable";
    constant INSTR_FILE_READ : string := "file_read";
    constant INSTR_FILE_READ_END : string := "file_read_end";
    constant INSTR_FILE_READ_ALL : string := "file_read_all";
    constant INSTR_FILE_WRITE : string := "file_write";
    constant INSTR_FILE_APPEND : string := "file_append";
    constant INSTR_FILE_POINTER_COPY : string := "file_pointer_copy";
    constant INSTR_FILE_POINTER_COPY_PAR_CLOSE : string := "file_pointer_copy_)";

    -- label
    constant INSTR_LABEL : string := "label";
    constant INSTR_LABEL_PAR_CLOSE : string := "label_)";
    constant INSTR_LABEL_POINTER_COPY : string := "label_pointer_copy";
    constant INSTR_LABEL_POINTER_COPY_PAR_CLOSE : string := "label_pointer_copy_)";
    constant INSTR_LABEL_EQU : string := "label_equ";
    constant INSTR_LABEL_EQU_PAR_CLOSE : string := "label_equ_)";
    constant INSTR_LABEL_SET : string := "label_set";
    constant INSTR_LABEL_SET_PAR_CLOSE : string := "label_set_)";

    -- lines
    constant INSTR_LINES : string := "lines";
    constant INSTR_LINES_PAR_CLOSE : string := "lines_)";
    constant INSTR_LINES_GET_ARRAY : string := "lines_get_array";
    constant INSTR_LINES_SET_ARRAY : string := "lines_set_array";
    constant INSTR_LINES_SET_MESSAGE : string := "lines_set_message";
    constant INSTR_LINES_DELETE : string := "lines_delete";
    constant INSTR_LINES_DELETE_ALL : string := "lines_delete_all";
    constant INSTR_LINES_INSERT_ARRAY : string := "lines_insert_array";
    constant INSTR_LINES_INSERT_MESSAGE : string := "lines_insert_message";
    constant INSTR_LINES_APPEND_ARRAY : string := "lines_append_array";
    constant INSTR_LINES_APPEND_MESSAGE : string := "lines_append_message";
    constant INSTR_LINES_SIZE : string := "lines_size";
    constant INSTR_LINES_POINTER_COPY : string := "lines_pointer_copy";
    constant INSTR_LINES_POINTER_COPY_PAR_CLOSE : string := "lines_pointer_copy_)";

    -- array
    constant INSTR_ARRAY : string := "array";
    constant INSTR_ARRAY_PAR_CLOSE : string := "array_)";
    constant INSTR_ARRAY_GET : string := "array_get";
    constant INSTR_ARRAY_SET : string := "array_set";
    constant INSTR_ARRAY_SIZE : string := "array_size";
    constant INSTR_ARRAY_POINTER_COPY : string := "array_pointer_copy";
    constant INSTR_ARRAY_POINTER_COPY_PAR_CLOSE : string := "array_pointer_copy_)";
    constant INSTR_ARRAY_VERIFY : string := "array_verify";

    -- others
    constant INSTR_PROC_PAR_OPEN : string := "proc_(";
    constant INSTR_PROC_NOPAR : string := "proc_(_)";
    constant INSTR_CALL_PAR_OPEN : string := "call_(";
    constant INSTR_CALL_NOPAR : string := "call_(_)";
    constant INSTR_CALL_LABEL : string := "call_label";
    constant INSTR_CALL_LABEL_PAR_OPEN : string := "call_label_(";
    constant INSTR_CALL_LABEL_NOPAR : string := "call_label_(_)";
    constant INSTR_PAR_CLOSE : string := ")";
    constant INSTR_INTERRUPT_NOPAR : string := "interrupt_(_)";
    constant INSTR_END_PROC : string := "end_proc";
    constant INSTR_END_INTERRUPT : string := "end_interrupt";
    constant INSTR_RANDOM : string := "random";
    constant INSTR_LOG_MESSAGE : string := "log_message";
    constant INSTR_LOG_LINES : string := "log_lines";
    constant INSTR_RETURN : string := "return";
    constant INSTR_RESUME : string := "resume";
    constant INSTR_MARKER : string := "marker";
    constant INSTR_VERBOSITY : string := "verbosity";
    constant INSTR_SEED : string := "seed";
    constant INSTR_TRACE : string := "trace";
    constant INSTR_WAIT : string := "wait";

    procedure define_insts(
        variable inst_defs : inout inst_def_list
    );

    procedure token_merge_words(
        variable itokens : in unmerged_token_text_field_array;
        variable valid : in integer;
        variable otokens : out token_text_field_array;
        variable ovalid : out integer
    );

    procedure append_inst_def(        
        variable inst_defs : inout inst_def_list;
        constant inst : in string;
        constant num_of_params : in integer
    );

    procedure check_valid_inst(
        variable slc : in src_locator;
        variable inst_defs : in inst_def_list;
        variable inst : in text_field;
        variable num_of_params : in integer
    );

end package;

