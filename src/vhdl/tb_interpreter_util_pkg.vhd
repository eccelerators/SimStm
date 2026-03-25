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

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;

package tb_interpreter_util_pkg is

    procedure file_read_line(
        file file_name : text;
        variable file_line : out text_line
    );

    procedure tokenize_inst_line(
        variable itext_line : in text_line;
        variable otokens : out token_text_field_array;
        variable txt_ptr : out stm_text_ptr;
        variable txt_enclosing_quote : out character;
        variable ovalid : out integer
    );

    procedure txt_print_wvar(
        variable slc : in src_locator;
        variable insts : in inst_sequence;
        variable vars : in var_pool_ordered;
        variable rcs : in stm_array_of_runtime_context;
        variable txt_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable sp : in integer;
        constant machine_value_width : in integer
    );

    procedure stm_text_substitude_wvar(
        variable slc : in src_locator;
        variable insts : in inst_sequence;
        variable vars : in var_pool_ordered;
        variable rcs : in stm_array_of_runtime_context;
        variable txt_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable sp : in integer;    
        variable stm_text_substituded : out stm_text;
        constant machine_value_width : in integer
    );

    procedure access_inst_par_value_global(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable val : out unsigned
    );
        
    procedure access_inst_par_value_local(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable val : out unsigned
    );
    
    procedure access_inst_par_value_prefer_local(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable val : out unsigned
    );
      
    procedure access_inst_par_index_global(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable ven : out integer        
    );    
    
    procedure access_inst_par_index_local(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable ven : out integer 
    );    
    
    procedure access_inst_par_index_prefer_local(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable ven : out integer 
    );    
    
    procedure access_inst_par_index_global(
        variable ie : in inst_element;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable ven : out integer        
    );    
    
    procedure access_inst_par_index_local(
        variable ie : in inst_element;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable ven : out integer 
    );    
    
    procedure access_inst_par_index_prefer_local(
        variable ie : in inst_element;
        variable vars : in var_pool_ordered;
        variable par_num : in integer;
        variable called_proc_name : in text_field;
        variable ven : out integer 
    ); 
    
    procedure access_proc(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_element_num : out integer
    );
    
     procedure access_proc(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name_ptr : in text_field_ptr;
        variable proc_element_num : out integer
    );

    procedure access_var(
        variable slc : in src_locator;
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer
    );

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    );

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    );

    procedure index_var_values_ptr(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value_ptr : out stm_values_ptr
    );

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : out stm_text_ptr;
        variable var_txt_enclosing_quote : out character
    );

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : out stm_text_ptr;
        variable var_txt_enclosing_quote : out character
    );

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : out stm_array_ptr
    );

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : out stm_array_ptr
    );
                          
    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : out text_field_ptr
    );

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : out text_field_ptr
    );

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : out stm_lines_ptr
    );

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : out stm_lines_ptr
    );

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : in unsigned
    );

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value : in unsigned
    );

    procedure update_var_values_ptr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value_ptr : in stm_values_ptr
    );

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : in stm_text_ptr
    );

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : in stm_text_ptr
    );

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : in stm_array_ptr
    );

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : in stm_array_ptr
    );

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    );

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    );

    procedure init_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    );

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    );

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    );

    procedure print_inst_element(
        variable insts : in inst_sequence;
        variable inst_element_num : in integer;
        variable code_files : in file_def_list
    );

    procedure dump_inst_sequence(
        variable insts : in inst_sequence;
        variable code_files : in file_def_list
    );

    procedure dump_var_pool_ordered(
        variable vars : in var_pool_ordered;
        constant machine_value_width : in integer
    );

    procedure dump_var_element(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        constant machine_value_width : in integer
    );
    
    procedure print_file_def_element(
        variable files : in file_def_list;
        variable file_element_num : in integer
    );
    
    procedure dump_file_defs(
        variable files : in file_def_list
    );

    procedure print_initial_instruction_context(
        variable iic : in stm_inst_initial_context
    );
    
    procedure print_runtime_context(
        variable rc : in stm_runtime_context
    );
    
    procedure search_var_element_number(
        variable slc : in src_locator;
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable ien : out integer
    );
    
    procedure search_proc_element_number( 
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable pen : out integer
    );
    
    procedure set_var_type(
        variable inst : in text_field;
        variable inst_len : in integer;
        variable var_type : out stm_var_type
    );
    
    procedure set_proc_type(
        variable inst : in text_field;
        variable inst_len : in integer;
        variable proc_type : out boolean
    );
    
    procedure track_inst_initial_context(
        variable ie : inst_element;
        variable vars : in var_pool_ordered;
        variable procs : in proc_pool_ordered; 
        variable iic : inout stm_inst_initial_context
    );
    
    procedure insert_proc_element(
        variable slc : in src_locator;
        variable procs : inout proc_pool_ordered;
        variable proc_name : in text_field;
        variable debug : boolean;
        variable pen  : out integer
    );
    
    procedure insert_var_element(
        variable slc : in src_locator;
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable inst_args : inst_arguments;
        constant var_type : in stm_var_type;
        constant machine_value_width : in integer;
        variable debug : in boolean;
        variable ven  : out integer
    );
    
end package;
