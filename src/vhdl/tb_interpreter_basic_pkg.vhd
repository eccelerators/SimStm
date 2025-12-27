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

package tb_interpreter_basic_pkg is

    procedure track_scope(
          variable inst : in text_field;
          variable par_text_fields : in parameter_text_field_array;
          variable file_name : in text_line;
          variable line_num : in integer;
          variable var_list : inout var_field_ptr;
          variable scope : inout t_stm_scope          
    );

    procedure add_on_constant_declaration(
          variable var_list : inout var_field_ptr;    
          variable inst : in text_field;
          variable par_text_fields : in parameter_text_field_array;
          variable inst_list_elment_num : inout integer;
          variable str_ptr : in stm_text_ptr;
          variable txt_enclosing_quote : in character;
          variable file_line_num : in integer;
          variable file_name : in text_line;
          variable scope : inout t_stm_scope;
          constant stm_value_width : in integer
    );

    procedure add_on_variable_declaration(
          variable var_list : inout var_field_ptr;
          variable inst : in text_field;
          variable par_text_fields : in parameter_text_field_array;
          variable inst_list_elment_num : inout integer;
          variable str_ptr : in stm_text_ptr;
          variable txt_enclosing_quote : in character;
          variable file_line_num : in integer;
          variable file_name : in text_line;
          variable scope : inout t_stm_scope;
          constant stm_value_width : in integer
    );

    --  add_instruction
    --    this is the procedure that adds the instruction to the linked list of
    --    instructions.

    procedure add_instruction(
          variable inst_list : inout stim_line_ptr;                    
          variable var_list : inout var_field_ptr;
          variable inst : in text_field;
          variable par_text_fields : in parameter_text_field_array;
          variable inst_list_elment_num : inout integer;
          variable str_ptr : in stm_text_ptr;
          variable txt_enclosing_quote : in character;
          variable file_line_num : in integer;
          variable file_name : in text_line;
          variable file_idx : in integer;
          variable scope : inout t_stm_scope;
          constant stm_value_width : in integer
    );

    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable scope : in text_field;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_stm_type : in t_stm_var_type;
                           variable str_ptr : in stm_text_ptr;
                           variable txt_enclosing_quote : in character;
                           constant stm_value_width : in integer;
                           variable assigned_index : out integer);
                          
end package;
