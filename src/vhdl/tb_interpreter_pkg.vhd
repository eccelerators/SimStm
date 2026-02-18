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

package tb_interpreter_pkg is

    --  add_instruction
    --    this is the procedure that adds the instruction to the linked list of
    --    instructions.  also variable addition are called and or handled.
    --    the instruction sequence link list.
    --     inputs:
    --               stim_line_ptr        is the pointer to the instruction list
    --               inst                 is the instruction token
    --               p1                   paramitor one, corrisponds to field one of stimulus
    --               p2                   paramitor one, corrisponds to field two of stimulus
    --               p3                   paramitor one, corrisponds to field three of stimulus
    --               p4                   paramitor one, corrisponds to field four of stimulus
    --               p5                   paramitor one, corrisponds to field three of stimulus
    --               p6                   paramitor one, corrisponds to field four of stimulus
    --               str_ptr              pointer to string for print instruction
    --               txt_enclosing_quote  enclosing quote of text string of this sequence
    --               token_num            the number of tokens, including instruction
    --               sequ_num             is the stimulus file line referance  ie program line number
    --               line_num             line number in the text file
    --     outputs:
    --               none.  error will terminate sim
    procedure add_instruction(variable pass : in integer;
                              variable inst_list : inout stim_line_ptr;
                              variable var_list : inout var_field_ptr;
                              variable scope : in text_field;
                              variable scope_left : in text_field;
                              variable inst : in text_field;
                              variable p1 : in text_field;
                              variable p2 : in text_field;
                              variable p3 : in text_field;
                              variable p4 : in text_field;
                              variable p5 : in text_field;
                              variable p6 : in text_field;
                              variable str_ptr : in stm_text_ptr;
                              variable txt_enclosing_quote : in character;
                              variable sequ_num : inout integer;
                              variable line_num : in integer;
                              variable file_name : in text_line;
                              variable file_idx : in integer;
                              constant stm_value_width : in integer);

    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable scope : in text_field;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_stm_type : in t_stm_var_type;
                           variable label_ptr : in text_field_ptr;
                           variable str_ptr : in stm_text_ptr;
                           variable txt_enclosing_quote : in character;
                           constant stm_value_width : in integer;
                           variable assigned_index : out integer);

    -- access_inst_sequ
    --   this procedure retrieves an instruction from the sequence of instructions.
    --   based on the line number you pass to it, it returns the instruction with
    --   any variables substituted as integers.
    --  inputs:   inst_sequ  link list of instructions from stimulus
    --            var_list   link list of variables
    --            file_list  link list of file names
    --            sequ_num   the sequence number to recover
    --
    --  outputs:  inst                 instruction text
    --            p1                   parameter 1 in unsigned form
    --            p2                   parameter 2 in unsigned form
    --            p3                   parameter 3 in unsigned form
    --            p4                   parameter 4 in unsigned form
    --            p5                   parameter 5 in unsigned form
    --            p6                   parameter 6 in unsigned form
    --            txt                  pointer to any text string of this sequence
    --            txt_enclosing_quote  enclosing quote of text string of this sequence
    --            inst_len             the lenth of inst in characters
    --            fname                file name this sequence came from
    --            file_line            the line number in fname this sequence came from
    --
    procedure access_inst_sequ(variable inst_sequ : in stim_line_ptr;
                               variable var_list : in var_field_ptr;
                               variable file_list : in file_def_ptr;
                               variable sequ_num : in integer;
                               variable inst : out text_field;
                               variable scope : out text_field;
                               variable scope_left : out text_field;  
                               variable p1_index : out integer;
                               variable p2_index : out integer;
                               variable p3_index : out integer;
                               variable p4_index : out integer;
                               variable p5_index : out integer;
                               variable p6_index : out integer;
                               variable p1 : out unsigned;
                               variable p2 : out unsigned;
                               variable p3 : out unsigned;
                               variable p4 : out unsigned;
                               variable p5 : out unsigned;
                               variable p6 : out unsigned;
                               variable txt : out stm_text_ptr;
                               variable txt_enclosing_quote : out character;
                               variable inst_len : out integer;
                               variable fname : out text_line;
                               variable file_line : out integer;
                               variable last_num : inout integer;
                               variable last_ptr : inout stim_line_ptr);
                               
    procedure read_include_file(variable pass : in integer;
                                constant path_name : string;
                                variable name : text_line;
                                variable sequ_numb : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_sequ : inout stim_line_ptr;
                                variable status : inout integer;
                                constant stm_value_width : in integer);

    -- read_instruction_file
    --  this procedure reads the instruction file, name passed throught file_name.
    --  pointers to records are passed in and out.  a table of variables is created
    --  with variable name and value (converted to integer).  the instructions are
    --  parsesed into the inst_sequ list.  instructions are validated against the
    --  inst_set which must have been set up prior to loading the instruction file.
    procedure read_instruction_file(variable pass : in integer;
                                    constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_sequ : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr;
                                    constant stm_value_width : in integer);
                                    
    procedure test_inst_sequ(variable inst_sequ : in stim_line_ptr;
                             variable file_list : in file_def_ptr;
                             variable var_list : in var_field_ptr;
                             constant stm_value_width : in integer);

end package;
