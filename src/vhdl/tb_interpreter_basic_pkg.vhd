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

package tb_interpreter_basic_pkg is

    procedure track_inst_context(
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable var_list : inout var_field_ptr;
        variable inst_context : inout t_stm_inst_context
    );

    procedure add_var_on_constant_declaration(
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    );

    procedure add_var_on_non_local_variable_declaration(
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    );

    procedure add_inst(
        variable inst_list : inout inst_element_ptr;
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable file_idx : in integer;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    );

    procedure add_var(
        variable var_list : inout var_field_ptr;
        variable var_scope : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : in integer;
        variable file_line : in integer;
        variable file_name : in text_line;
        constant var_stm_type : in stm_var_type;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer;
        variable assigned_index : out integer
    );
    
    procedure insert_proc_element(
        variable file_name : in text_line;
        variable file_line : in integer;
        variable procs : inout proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_inst_element_num : in integer
    );
    
    procedure insert_var_element(
        variable file_name : in text_line;
        variable file_line : in integer;
        variable vars : inout var_pool_ordered;
        variable var_scope : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        constant var_stm_type : in stm_var_type;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer
    );

end package;
