-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
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

package tb_interpreter_pkg is

    --  add_instruction
    --    this is the procedure that adds the instruction to the linked list of
    --    instructions.  also variable addition are called and or handled.
    --    the instruction sequence link list.
    --     inputs:
    --               stim_line_ptr   is the pointer to the instruction list
    --               inst            is the instruction token
    --               p1              paramitor one, corrisponds to field one of stimulus
    --               p2              paramitor one, corrisponds to field two of stimulus
    --               p3              paramitor one, corrisponds to field three of stimulus
    --               p4              paramitor one, corrisponds to field four of stimulus
    --               p5              paramitor one, corrisponds to field three of stimulus
    --               p6              paramitor one, corrisponds to field four of stimulus
    --               str_ptr         pointer to string for print instruction
    --               token_num       the number of tokens, including instruction
    --               sequ_num        is the stimulus file line referance  ie program line number
    --               line_num        line number in the text file
    --     outputs:
    --               none.  error will terminate sim
    procedure add_instruction(variable inst_list : inout stim_line_ptr;
                              variable var_list : inout var_field_ptr;
                              variable inst : in text_field;
                              variable p1 : in text_field;
                              variable p2 : in text_field;
                              variable p3 : in text_field;
                              variable p4 : in text_field;
                              variable p5 : in text_field;
                              variable p6 : in text_field;
                              variable str_ptr : in stm_text_ptr;
                              variable sequ_num : inout integer;
                              variable line_num : in integer;
                              variable file_name : in text_line;
                              variable file_idx : in integer);

    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_stm_type : in t_stm_var_type;
                           variable str_ptr : in stm_text_ptr);

    --  access_variable
    --     inputs:
    --               text field containing variable
    --     outputs:
    --               value  $var  returns value of var
    --               value  var   returns index of var
    --
    --               valid is 1, not valid is 0
    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var : in text_field;
                              variable value : out integer;
                              variable valid : out integer);

    -- access_inst_sequ
    --   this procedure retreeves an instruction from the sequence of instructions.
    --   based on the line number you pass to it, it returns the instruction with
    --   any variables substituted as integers.
    --  inputs:   inst_sequ  link list of instructions from stimulus
    --            var_list   link list of variables
    --            file_list  link list of file names
    --            sequ_num   the sequence number to recover
    --
    --  outputs:  inst  instruction text
    --            p1    parameter 1 in integer form
    --            p2    parameter 2 in integer form
    --            p3    parameter 3 in integer form
    --            p4    parameter 4 in integer form
    --            p5    parameter 5 in integer form
    --            p6    parameter 6 in integer form
    --            txt   pointer to any text string of this sequence
    --            inst_len  the lenth of inst in characters
    --            fname  file name this sequence came from
    --            file_line  the line number in fname this sequence came from
    --
    procedure access_inst_sequ(variable inst_sequ : in stim_line_ptr;
                               variable var_list : in var_field_ptr;
                               variable file_list : in file_def_ptr;
                               variable sequ_num : in integer;
                               variable inst : out text_field;
                               variable p1 : out integer;
                               variable p2 : out integer;
                               variable p3 : out integer;
                               variable p4 : out integer;
                               variable p5 : out integer;
                               variable p6 : out integer;
                               variable txt : out stm_text_ptr;
                               variable inst_len : out integer;
                               variable fname : out text_line;
                               variable file_line : out integer;
                               variable last_num : inout integer;
                               variable last_ptr : inout stim_line_ptr);

    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug**
    procedure dump_inst_sequ(variable inst_sequ : in stim_line_ptr; file_list : inout file_def_ptr);

    -- dump all variables
    procedure dump_variables(variable var_list : in var_field_ptr);

    procedure dump_file_defs(file_list : inout file_def_ptr);

    procedure dump_var_field(variable ptr : var_field_ptr);
        
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
                             variable value : out integer;
                             variable valid : out integer);

    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable stm_text
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_stm_text : out stm_text_ptr;
                             variable valid : out integer);

    --  index_stm_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_array
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer);

    --  index_stm_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               stm_lines
    --               valid is 1, not valid is 0
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer);

    procedure print_file_def(file_list : inout file_def_ptr; index : in integer);

    -- procedure to print instruction records to stdout  *for debug*
    procedure print_inst(variable inst_sequ : in stim_line_ptr; v_line : in integer; file_list : inout file_def_ptr);
    
    -- procedure to get parameter 1 instruction text which is the called label in case of a call instrucution
    procedure get_inst_field_1(variable inst_sequ : in stim_line_ptr; v_line : in integer; inst_field_1 : out text_field); 
    
    procedure read_include_file(constant path_name : string;
                                variable name : text_line;
                                variable sequ_numb : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_sequ : inout stim_line_ptr;
                                variable status : inout integer);
                                
    -- read_instruction_file
    --  this procedure reads the instruction file, name passed throught file_name.
    --  pointers to records are passed in and out.  a table of variables is created
    --  with variable name and value (converted to integer).  the instructions are
    --  parsesed into the inst_sequ list.  instructions are validated against the
    --  inst_set which must have been set up prior to loading the instruction file.
    procedure read_instruction_file(constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_sequ : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr);

    procedure stm_text_substitude_wvar(variable var_list : in var_field_ptr;
                                       variable ptr : in stm_text_ptr;
                                       variable stack_ptr : integer;
                                       variable stack_called_files : stack_text_line_array;
                                       variable stack_called_file_line_numbers: stack_numbers_array;
                                       variable stack_called_labels : stack_text_field_array;
                                       variable stm_text_substituded : out stm_text);

    procedure test_inst_sequ(variable inst_sequ : in stim_line_ptr;
                             variable file_list : in file_def_ptr;
                             variable var_list : in var_field_ptr);

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
                            variable ovalid : out integer);

    --procedure print stim txt sub variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable ptr : in stm_text_ptr;
                             variable stack_ptr : integer;
                             variable stack_called_files : stack_text_line_array;
                             variable stack_called_file_line_numbers: stack_numbers_array;
                             variable stack_called_labels : stack_text_field_array);

    --  update_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in integer;
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
                              
end package;
