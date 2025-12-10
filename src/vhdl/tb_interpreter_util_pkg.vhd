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

package tb_interpreter_util_pkg is

    --  access_variable
    --     inputs:
    --               text field containing variable
    --     outputs:
    --               value  var  returns value of var
    --               value  var   returns index of var
    --
    --               valid is 1, not valid is 0
    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field; 
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value : out integer;
                              variable valid : out integer;
                              constant stm_value_width : in integer);

    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value : out unsigned;
                              variable valid : out integer);
                              
    procedure access_variable_value_ptr(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value_ptr : out t_stm_value_ptr;
                              variable valid : out integer);
                              
    procedure access_variable_label_ptr(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_label_ptr : out text_field_ptr;
                              variable valid : out integer);

    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug**
    procedure dump_inst_sequ(variable inst_sequ : in stim_line_ptr; file_list : inout file_def_ptr);

    -- dump all variables
    procedure dump_variables(variable var_list : in var_field_ptr;
                             constant stm_value_width : in integer);
                             
    procedure dump_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             constant stm_value_width : in integer);

    procedure dump_file_defs(file_list : inout file_def_ptr);

    procedure dump_var_field(variable ptr : var_field_ptr;
                             constant stm_value_width : in integer);

    procedure file_read_line(file file_name : text;
                             variable file_line : out text_line);

    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value : out unsigned;
                             variable valid : out integer);
                             
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value : out unsigned;
                             variable valid : out integer);
                                                          
    procedure index_variable_value_ptr(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value_ptr : out t_stm_value_ptr;
                             variable valid : out integer);

    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable stm_text
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer);
                             
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer);

    --  index_stm_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_array
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer);
                             
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer);
                             
    --  index_stm_label
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_label
    --               valid is 1, not valid is 0                             
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_label : out text_field_ptr;
                             variable valid : out integer);
                             
     procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_label : out text_field_ptr;
                             variable valid : out integer);

    --  index_stm_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_lines
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer);
                             
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer);


    procedure print_file_def(file_list : inout file_def_ptr; index : in integer);

    -- procedure to print instruction records to stdout  *for debug*
    procedure print_inst(variable inst_sequ : in stim_line_ptr; v_line : in integer; file_list : inout file_def_ptr);

    procedure stm_text_substitude_wvar(variable var_list : in var_field_ptr;
                                       variable scope : in text_field; 
                                       variable ptr : in stm_text_ptr;
                                       variable txt_enclosing_quote : in character;
                                       variable stack_ptr : integer;
                                       variable stack_called_files : stack_text_line_array;
                                       variable stack_called_file_line_numbers : stack_numbers_array;
                                       variable stack_called_labels : stack_text_field_array;
                                       variable stm_text_substituded : out stm_text;
                                       constant stm_value_width : in integer);

    --  tokenize_line
    --    this procedure takes a type text_line in and returns up to 6
    --    tokens and the count in integer valid, as well if text string
    --    is found the pointer to that is returned.
    procedure tokenize_line(variable text_line : in text_line;
                            variable otoken1 : out text_field;
                            variable otoken2 : out text_field;
                            variable otoken3 : out text_field;
                            variable otoken4 : out text_field;
                            variable otoken5 : out text_field;
                            variable otoken6 : out text_field;
                            variable otoken7 : out text_field;
                            variable txt_ptr : out stm_text_ptr;
                            variable txt_enclosing_quote : out character;
                            variable ovalid : out integer);

    --procedure print stim txt sub variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable scope : in text_field;
                             variable ptr : in stm_text_ptr;
                             variable txt_enclosing_quote : in character;
                             variable stack_ptr : integer;
                             variable stack_called_files : stack_text_line_array;
                             variable stack_called_file_line_numbers : stack_numbers_array;
                             variable stack_called_labels : stack_text_field_array;
                             constant stm_value_width : in integer);

    --  update_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in unsigned;
                              variable valid : out integer); 
                              
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in unsigned;
                              variable valid : out integer);                             
                                                 
    procedure update_variable_value_ptr(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value_ptr : in t_stm_value_ptr;
                              variable valid : out integer);
                              
    --  update_variable
    --     inputs:
    --               index:  the index of the variable being updated
    --     outputs:
    --               valid is 1, not valid is 0
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer);
                              
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer);

    --  update_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new array
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer);
                              
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer);
                              
    --  update_label
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new label
    --               valid  is 1 if valid 0 if not                              
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer);
                              
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer);

    procedure init_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer);

    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer);
                              
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer);
                              
end package;
