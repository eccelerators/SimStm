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

package body tb_instructions_pkg is

    procedure define_insts(
        variable inst_defs : inout inst_def_list
    ) is
    begin
        -- basic
        append_inst_def(inst_defs, INSTR_NAMESPACE, 1);
        append_inst_def(inst_defs, INSTR_END_NAMESPACE, 0);
        append_inst_def(inst_defs, INSTR_ABORT, 0);
        append_inst_def(inst_defs, INSTR_CONST, 2);
        append_inst_def(inst_defs, INSTR_ELSE, 0);
        append_inst_def(inst_defs, INSTR_ELSIF, 3);
        append_inst_def(inst_defs, INSTR_END_IF, 0);
        append_inst_def(inst_defs, INSTR_END_LOOP, 0);
        append_inst_def(inst_defs, INSTR_STOP, 0);
        append_inst_def(inst_defs, INSTR_FINISH, 0);
        append_inst_def(inst_defs, INSTR_IF, 3);
        append_inst_def(inst_defs, INSTR_INCLUDE, 1);
        append_inst_def(inst_defs, INSTR_LOOP, 1);
        append_inst_def(inst_defs, INSTR_VAR, 2);
        -- variable
        append_inst_def(inst_defs, INSTR_VAR_VERIFY, 3);
        append_inst_def(inst_defs, INSTR_ADD, 2);
        append_inst_def(inst_defs, INSTR_AND, 2);
        append_inst_def(inst_defs, INSTR_DIV, 2);
        append_inst_def(inst_defs, INSTR_REM, 2);
        append_inst_def(inst_defs, INSTR_EQU, 2);
        append_inst_def(inst_defs, INSTR_EQU_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_VAR_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_VAR_POINTER_COPY_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_MUL, 2);
        append_inst_def(inst_defs, INSTR_SHL, 2);
        append_inst_def(inst_defs, INSTR_SHR, 2);
        append_inst_def(inst_defs, INSTR_INV, 1);
        append_inst_def(inst_defs, INSTR_OR, 2);
        append_inst_def(inst_defs, INSTR_SUB, 2);
        append_inst_def(inst_defs, INSTR_XOR, 2);
        append_inst_def(inst_defs, INSTR_LD, 1);
        -- signal
        append_inst_def(inst_defs, INSTR_SIGNAL, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_READ, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_VERIFY, 4);
        append_inst_def(inst_defs, INSTR_SIGNAL_WRITE, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_POINTER_SET, 2);
        append_inst_def(inst_defs, INSTR_SIGNAL_POINTER_GET, 2);
        -- bus
        append_inst_def(inst_defs, INSTR_BUS, 2);
        append_inst_def(inst_defs, INSTR_BUS_READ, 4);
        append_inst_def(inst_defs, INSTR_BUS_VERIFY, 6);
        append_inst_def(inst_defs, INSTR_BUS_WRITE, 4);
        append_inst_def(inst_defs, INSTR_BUS_TIMEOUT_SET, 2);
        append_inst_def(inst_defs, INSTR_BUS_TIMEOUT_GET, 2);
        append_inst_def(inst_defs, INSTR_BUS_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_BUS_POINTER_COPY_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_BUS_POINTER_SET, 2);
        append_inst_def(inst_defs, INSTR_BUS_POINTER_GET, 2);
        -- file
        append_inst_def(inst_defs, INSTR_FILE, 1);
        append_inst_def(inst_defs, INSTR_FILE_READABLE, 2);
        append_inst_def(inst_defs, INSTR_FILE_WRITABLE, 2);
        append_inst_def(inst_defs, INSTR_FILE_APPENDABLE, 2);
        append_inst_def(inst_defs, INSTR_FILE_READ, 3);
        append_inst_def(inst_defs, INSTR_FILE_READ_END, 1);
        append_inst_def(inst_defs, INSTR_FILE_READ_ALL, 2);
        append_inst_def(inst_defs, INSTR_FILE_WRITE, 2);
        append_inst_def(inst_defs, INSTR_FILE_APPEND, 2);
        append_inst_def(inst_defs, INSTR_FILE_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_FILE_POINTER_COPY_PAR_CLOSE, 2);
        -- label
        append_inst_def(inst_defs, INSTR_LABEL, 2);
        append_inst_def(inst_defs, INSTR_LABEL_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_LABEL_POINTER_COPY_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_LABEL_EQU, 2);
        append_inst_def(inst_defs, INSTR_LABEL_EQU_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_LABEL_SET, 2);
        append_inst_def(inst_defs, INSTR_LABEL_SET_PAR_CLOSE, 2);
        -- lines
        append_inst_def(inst_defs, INSTR_LINES, 1);
        append_inst_def(inst_defs, INSTR_LINES_GET_ARRAY, 4);
        append_inst_def(inst_defs, INSTR_LINES_SET_ARRAY, 3);
        append_inst_def(inst_defs, INSTR_LINES_SET_MESSAGE, 2);
        append_inst_def(inst_defs, INSTR_LINES_DELETE, 2);
        append_inst_def(inst_defs, INSTR_LINES_DELETE_ALL, 1);
        append_inst_def(inst_defs, INSTR_LINES_INSERT_ARRAY, 3);
        append_inst_def(inst_defs, INSTR_LINES_INSERT_MESSAGE, 2);
        append_inst_def(inst_defs, INSTR_LINES_APPEND_ARRAY, 2);
        append_inst_def(inst_defs, INSTR_LINES_APPEND_MESSAGE, 1);
        append_inst_def(inst_defs, INSTR_LINES_SIZE, 2);
        append_inst_def(inst_defs, INSTR_LINES_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_LINES_POINTER_COPY_PAR_CLOSE, 2);
        -- array
        append_inst_def(inst_defs, INSTR_ARRAY, 2);
        append_inst_def(inst_defs, INSTR_ARRAY_GET, 3);
        append_inst_def(inst_defs, INSTR_ARRAY_SET, 3);
        append_inst_def(inst_defs, INSTR_ARRAY_SIZE, 2);
        append_inst_def(inst_defs, INSTR_ARRAY_POINTER_COPY, 2);
        append_inst_def(inst_defs, INSTR_ARRAY_POINTER_COPY_PAR_CLOSE, 2);
        append_inst_def(inst_defs, INSTR_ARRAY_VERIFY, 4);
        -- others
        append_inst_def(inst_defs, INSTR_PROC, 0);
        append_inst_def(inst_defs, INSTR_PROC_PAR_OPEN, 1);
        append_inst_def(inst_defs, INSTR_PROC_NOPAR, 1);
        append_inst_def(inst_defs, INSTR_CALL_PAR_OPEN, 1);
        append_inst_def(inst_defs, INSTR_CALL_NOPAR, 1);
        append_inst_def(inst_defs, INSTR_CALL_LABEL_PAR_OPEN, 1);
        append_inst_def(inst_defs, INSTR_CALL_LABEL_NOPAR, 1);
        append_inst_def(inst_defs, INSTR_PAR_CLOSE, 0);
        append_inst_def(inst_defs, INSTR_INTERRUPT_NOPAR, 1);
        append_inst_def(inst_defs, INSTR_END_PROC, 0);
        append_inst_def(inst_defs, INSTR_END_INTERRUPT, 0);
        append_inst_def(inst_defs, INSTR_RANDOM, 3);
        append_inst_def(inst_defs, INSTR_LOG_MESSAGE, 1);
        append_inst_def(inst_defs, INSTR_LOG_LINES, 2);
        append_inst_def(inst_defs, INSTR_RETURN, 0);
        append_inst_def(inst_defs, INSTR_RESUME, 1);
        append_inst_def(inst_defs, INSTR_MARKER, 2);
        append_inst_def(inst_defs, INSTR_VERBOSITY, 1);
        append_inst_def(inst_defs, INSTR_SEED, 1);
        append_inst_def(inst_defs, INSTR_TRACE, 1);
        append_inst_def(inst_defs, INSTR_WAIT, 1);
    end procedure;

    procedure token_merge_words(
        variable itokens : in unmerged_token_text_field_array;
        variable valid : in integer;
        variable otokens : out token_text_field_array;
        variable ovalid : out integer
    ) is
        variable token_merge : integer;
        variable token1_len : integer;
        variable token2_len : integer;
        variable token3_len : integer;
        variable token4_len : integer;
        variable token5_len : integer;
        variable token : text_field := itokens(1);
    begin
        if valid > 1 then
            if itokens(1)(1 to 3) = "end" then
                token1_len := 3;
                if itokens(2)(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "loop" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "proc" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 9) = "interrupt" then
                    token2_len := 9;
                    token_merge := 12;
                end if;
            elsif itokens(1)(1 to 3) = "log" then
                token1_len := 3;
                if itokens(2)(1 to 7) = "message" then
                    token2_len := 7;
                    token_merge := 12;
                elsif itokens(2)(1 to 5) = "lines" then
                    token2_len := 5;
                    token_merge := 12;
                end if;
            elsif itokens(1)(1 to 3) = "equ" then
                token1_len := 3;
                if itokens(4)(1 to 1) = ")" then
                    token4_len := 1;
                    token_merge := 14;
                end if;
            elsif itokens(1)(1 to 4) = "call" then
                token1_len := 4;
                if itokens(2)(1 to 5) = "label" then
                    token2_len := 5;
                    if itokens(4)(1 to 1) = "(" then
                        if itokens(5)(1 to 1) = ")" then
                            token4_len := 1;
                            token5_len := 1;
                            token_merge := 1245;
                        else
                            token4_len := 1;
                            token_merge := 124;
                        end if;
                    end if;
                else
                    if itokens(3)(1 to 1) = "(" then
                        if itokens(4)(1 to 1) = ")" then
                            token3_len := 1;
                            token4_len := 1;
                            token_merge := 134;
                        else
                            token3_len := 1;
                            token_merge := 13;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 4) = "proc" then
                token1_len := 4;
                if itokens(3)(1 to 1) = "(" then
                    if itokens(4)(1 to 1) = ")" then
                        token3_len := 1;
                        token4_len := 1;
                        token_merge := 134;
                    else
                        token3_len := 1;
                        token_merge := 13;
                    end if;
                end if;
            elsif itokens(1)(1 to 9) = "interrupt" then
                token1_len := 9;
                if itokens(3)(1 to 1) = "(" then
                    if itokens(4)(1 to 1) = ")" then
                        token3_len := 1;
                        token4_len := 1;
                        token_merge := 134;
                    else
                        token3_len := 1;
                        token_merge := 13;
                    end if;
                end if;
            elsif itokens(1)(1 to 4) = "file" then
                token1_len := 4;
                if itokens(2)(1 to 8) = "readable" then
                    token2_len := 8;
                    token_merge := 12;
                elsif itokens(2)(1 to 8) = "writable" then
                    token2_len := 8;
                    token_merge := 12;
                elsif itokens(2)(1 to 10) = "appendable" then
                    token2_len := 10;
                    token_merge := 12;
                elsif itokens(2)(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 12;
                elsif itokens(2)(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 12;
                    if itokens(3)(1 to 3) = "end" then
                        token3_len := 3;
                        token_merge := 123;
                    elsif itokens(3)(1 to 3) = "all" then
                        token3_len := 3;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 5) = "label" then
                token1_len := 5;
                if itokens(2)(1 to 3) = "equ" then
                    token2_len := 3;
                    token_merge := 12;
                    if itokens(3)(1 to 1) = ")" then
                        token3_len := 1;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := 12;
                    if itokens(3)(1 to 1) = ")" then
                        token3_len := 1;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 5) = "lines" then
                token1_len := 5;
                if itokens(2)(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := 12;
                    if itokens(3)(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := 12;
                    if itokens(3)(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 123;
                    elsif itokens(3)(1 to 7) = "message" then
                        token3_len := 7;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 6) = "delete" then
                    token2_len := 6;
                    token_merge := 12;
                    if itokens(3)(1 to 3) = "all" then
                        token3_len := 3;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 6) = "insert" then
                    token2_len := 6;
                    token_merge := 12;
                    if itokens(3)(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 123;
                    elsif itokens(3)(1 to 7) = "message" then
                        token3_len := 7;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := 12;
                    if itokens(3)(1 to 5) = "array" then
                        token3_len := 5;
                        token_merge := 123;
                    elsif itokens(3)(1 to 7) = "message" then
                        token3_len := 7;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 5) = "array" then
                token1_len := 5;
                if itokens(2)(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := 12;
                elsif itokens(2)(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 12;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 4) = "else" then
                token1_len := 4;
                if itokens(2)(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := 12;
                end if;
            elsif itokens(1)(1 to 3) = "var" then
                token1_len := 3;
                if itokens(2)(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 12;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    end if;
                end if;
            elsif itokens(1)(1 to 6) = "signal" then
                token1_len := 6;
                if itokens(2)(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 12;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    elsif itokens(3)(1 to 3) = "set" then
                        token3_len := 3;
                        token_merge := 123;
                    elsif itokens(3)(1 to 3) = "get" then
                        token3_len := 3;
                        token_merge := 123;
                    end if;
                end if;
            elsif itokens(1)(1 to 3) = "bus" then
                token1_len := 3;
                if itokens(2)(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := 12;
                elsif itokens(2)(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := 12;
                elsif itokens(2)(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := 12;
                elsif itokens(2)(1 to 7) = "timeout" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 3) = "set" then
                        token3_len := 3;
                        token_merge := 123;
                    elsif itokens(3)(1 to 3) = "get" then
                        token3_len := 3;
                        token_merge := 123;
                    end if;
                elsif itokens(2)(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := 12;
                    if itokens(3)(1 to 4) = "copy" then
                        if itokens(5)(1 to 1) = ")" then
                            token5_len := 1;
                            token_merge := 1235;
                        else
                            token3_len := 4;
                            token_merge := 123;
                        end if;
                    elsif itokens(3)(1 to 3) = "set" then
                        token3_len := 3;
                        token_merge := 123;
                    elsif itokens(3)(1 to 3) = "get" then
                        token3_len := 3;
                        token_merge := 123;
                    end if;
                end if;
            end if;
        end if;
        if token_merge = 134 then
            token(token1_len + 2 to token1_len + token4_len + 1) := itokens(4)(1 to token4_len);
            token(token1_len + 1) := '_';
            token(token1_len + token3_len + 3 to token1_len + token3_len + token4_len + 2) := itokens(4)(1 to token4_len);
            token(token1_len + 1 + token3_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(2);
            otokens(3) := itokens(5);
            otokens(4) := itokens(6);
            otokens(5) := itokens(7);
            otokens(6) := itokens(8);
            otokens(7) := itokens(9);
            ovalid := valid - 2;
        elsif token_merge = 13 then
            token(token1_len + 2 to token1_len + token3_len + 1) := itokens(3)(1 to token3_len);
            token(token1_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(2);
            otokens(3) := itokens(4);
            otokens(4) := itokens(5);
            otokens(5) := itokens(6);
            otokens(6) := itokens(7);
            otokens(7) := itokens(8);
            ovalid := valid - 1;
        elsif token_merge = 14 then
            token(token1_len + 2 to token1_len + token4_len + 1) := itokens(4)(1 to token4_len);
            token(token1_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(2);
            otokens(3) := itokens(3);
            otokens(4) := itokens(5);
            otokens(5) := itokens(6);
            otokens(6) := itokens(7);
            otokens(7) := itokens(8);
            ovalid := valid - 1;
        elsif token_merge = 123 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token3_len + 2) := itokens(3)(1 to token3_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(4);
            otokens(3) := itokens(5);
            otokens(4) := itokens(6);
            otokens(5) := itokens(7);
            otokens(6) := itokens(8);
            otokens(7) := itokens(9);
            ovalid := valid - 2;
        elsif token_merge = 124 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token4_len + 2) := itokens(4)(1 to token4_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(3);
            otokens(3) := itokens(5);
            otokens(4) := itokens(6);
            otokens(5) := itokens(7);
            otokens(6) := itokens(8);
            otokens(7) := itokens(9);
            ovalid := valid - 2;
        elsif token_merge = 1234 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token3_len + 2) := itokens(3)(1 to token3_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            token(token1_len + token2_len + token3_len + 4 to token1_len + token2_len + token3_len + token4_len + 3) := itokens(4)(1 to token4_len);
            token(token1_len + 1 + token2_len + 1 + token3_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(5);
            otokens(3) := itokens(6);
            otokens(4) := itokens(7);
            otokens(5) := itokens(8);
            otokens(6) := itokens(9);
            otokens(7) := (others => nul);
            ovalid := valid - 3;
        elsif token_merge = 1235 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token3_len + 2) := itokens(3)(1 to token3_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            token(token1_len + token2_len + token3_len + 4 to token1_len + token2_len + token3_len + token5_len + 3) := itokens(5)(1 to token5_len);
            token(token1_len + 1 + token2_len + 1 + token3_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(4);
            otokens(3) := itokens(6);
            otokens(4) := itokens(7);
            otokens(5) := itokens(8);
            otokens(6) := itokens(9);
            otokens(7) := (others => nul);
            ovalid := valid - 3;
        elsif token_merge = 1245 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            token(token1_len + token2_len + 3 to token1_len + token2_len + token4_len + 2) := itokens(4)(1 to token4_len);
            token(token1_len + 1 + token2_len + 1) := '_';
            token(token1_len + token2_len + token4_len + 4 to token1_len + token2_len + token4_len + token5_len + 3) := itokens(5)(1 to token5_len);
            token(token1_len + 1 + token2_len + 1 + token4_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(3);
            otokens(3) := itokens(6);
            otokens(4) := itokens(7);
            otokens(5) := itokens(8);
            otokens(6) := itokens(9);
            otokens(7) := (others => nul);
            ovalid := valid - 3;

        elsif token_merge = 12 then
            token(token1_len + 2 to token1_len + token2_len + 1) := itokens(2)(1 to token2_len);
            token(token1_len + 1) := '_';
            otokens(1) := token;
            otokens(2) := itokens(3);
            otokens(3) := itokens(4);
            otokens(4) := itokens(5);
            otokens(5) := itokens(6);
            otokens(6) := itokens(7);
            otokens(7) := itokens(8);
            ovalid := valid - 1;
        else
            otokens(1) := itokens(1);
            otokens(2) := itokens(2);
            otokens(3) := itokens(3);
            otokens(4) := itokens(4);
            otokens(5) := itokens(5);
            otokens(6) := itokens(6);
            otokens(7) := itokens(7);
            ovalid := valid;
        end if;
    end procedure;
    
    
    procedure append_inst_def(        
        variable inst_defs : inout inst_def_list;
        constant inst : in string;
        constant num_of_params : in integer
    ) is
        variable nen : integer;
        variable ne_ptr : inst_def_element_ptr;
        variable e_ptr : inst_def_element_ptr;
    begin
        assert inst'high <= max_field_len
        report "creation of instruction with length greater than max_field_len attempted, inst " & inst
        severity failure;
        nen := inst_defs.last_element_num + 1;
        ne_ptr := new inst_def_element;  
        for i in 1 to inst'high loop
            ne_ptr.inst(i) := inst(i);
        end loop;   
        ne_ptr.inst_len := inst'high;
        ne_ptr.num_of_params := num_of_params;
        for i in 0 to inst_defs.last_element_num loop
            e_ptr := inst_defs.element_ptrs(i);
            assert ne_ptr.inst /= e_ptr.inst
            report "creation of duplicate instruction attempted, inst " & ne_ptr.inst
            severity failure;            
        end loop;
        inst_defs.element_ptrs(nen) := ne_ptr;
        inst_defs.last_element_num := nen;
    end procedure;
    
    procedure check_valid_inst(
        variable slc : in src_locator;
        variable inst_defs : in inst_def_list;
        variable inst : in text_field;
        variable num_of_params : in integer
    ) is
        variable hn : integer;
        variable il : integer := 0;
    begin
        hn := -1;
        for i in 0 to inst_defs.last_element_num loop
            if inst_defs.element_ptrs(i).inst = inst then
                hn := i;
                exit;
            end if;
        end loop;
        assert hn >= 0
        report "undefined instruction found, inst " & inst & lf &
               "file " & slc.file_name & lf &
               "line " & integer'image(slc.file_line)
        severity failure;
        il := fld_len(inst);
        assert inst_defs.element_ptrs(hn).inst_len = il
        report "instruction found, inst " & inst & lf &
               "but length is wrong, should be " & integer'image(inst_defs.element_ptrs(hn).inst_len) & " but is " & integer'image(il) & lf &
               "file " & slc.file_name & lf &
               "line " & integer'image(slc.file_line)
        severity failure;       
        assert inst_defs.element_ptrs(hn).num_of_params = num_of_params
        report "instruction found, inst " & inst & lf &
               "but number of parameters is wrong, should be " & integer'image(inst_defs.element_ptrs(hn).num_of_params) & " but is " & integer'image(num_of_params) & lf &
               "file " & slc.file_name & lf &
               "line " & integer'image(slc.file_line)
        severity failure;       
    end procedure;
    
end package body;
