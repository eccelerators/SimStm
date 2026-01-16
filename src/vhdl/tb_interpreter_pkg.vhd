-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- Author: sckoarn
--
-- Description :  The the testbench package header file.
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;
use work.tb_interpreter_basic_pkg.all;

package tb_interpreter_pkg is

    procedure search_inst_element_ptr(
        variable inst_list : in inst_element_ptr;
        variable search_for_inst_element_number : in integer;
        variable last_searched_inst_element_number : inout integer;
        variable last_searched_inst_element_ptr : inout inst_element_ptr;
        variable inst_element_ptr : out inst_element_ptr
    );

    procedure access_inst_element_ptr(
        variable inst_element_ptr : in inst_element_ptr;
        variable file_list : in file_def_ptr;
        variable inst : out text_field;
        variable inst_len : out integer;
        variable par_text_fields : out parameter_text_field_array;
        variable txt : out stm_text_ptr;
        variable txt_enclosing_quote : out character;
        variable file_line : out integer;
        variable file_name : out text_line
    );

    procedure access_inst_element_parameters(
        variable var_list : in var_field_ptr;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable par_scopes : in parameter_scope_text_field_array;
        variable par_text_fields : in parameter_text_field_array;
        variable par_indexes : out parameter_index_array;
        variable par_values : out parameter_value_array
    );

    procedure read_instruction_file(
        variable pass : in integer;
        constant path_name : string;
        constant file_name : string;
        variable inst_def_list : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_list : inout inst_element_ptr;
        variable file_list : inout file_def_ptr;
        constant stm_value_width : in integer
    );

    procedure read_include_file(
        variable pass : in integer;
        constant path_name : string;
        variable name : text_line;
        variable inst_element_num : inout integer;
        variable file_list : inout file_def_ptr;
        variable inst_def_list : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_list : inout inst_element_ptr;
        variable status : inout integer;
        constant stm_value_width : in integer
    );

end package;
