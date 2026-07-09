-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Original work derived from VHDL-Test-Bench (Ken Campbell)
--   - Subsequent modifications: Eccelerators
--
-- Description:
--   Interpreter utility types and helper subprogram declarations.
--
-- Upstream reference:
--   https://github.com/sckoarn/VHDL-Test-Bench
-------------------------------------------------------------------------------

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
        variable txt_obj : out text_object;
        variable ovalid : out integer
    );

    procedure format(
        variable ie : in inst_element_ptr;
        variable procs : in proc_pool_ordered;
        variable vars : in var_pool_ordered;
        variable rcs : in stm_array_of_runtime_context;
        variable sp : in integer;
        variable txt_obj_ptr : in text_object_ptr;
        variable txt_formatted : out stm_text;
        constant machine_value_width : in integer
    );

    procedure access_inst_par_index(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        constant par_num : in integer;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable ven : out integer
    );

    procedure access_inst_par_value(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        constant par_num : in integer;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable found : out boolean;
        variable val : out unsigned
    );

    procedure access_var_index(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        constant is_fqn : in boolean;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable ven : out integer
    );

    procedure access_var_value(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        constant is_fqn : in boolean;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable found : out boolean;
        variable val : out unsigned
    );

    procedure access_proc_prepend_namespace(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable namespace : in text_field;
        variable proc_element_num : out integer
    );
    
    procedure access_proc_fqn(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_element_num : out integer
    );

    procedure index_var_value(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    );

    procedure index_var_values_ptr(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value_ptr : out stm_values_ptr
    );

    procedure index_var_txt(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : out text_object_ptr
    );

    procedure index_var_arr(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : out stm_array_ptr
    );

    procedure index_var_label(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : out text_field_ptr
    );

    procedure index_var_lines(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : out stm_lines_ptr
    );
    
    procedure init_var_value(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value : in unsigned;
        constant machine_value_width : integer
    );    
    
    procedure update_var_value(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : in unsigned
    );

    procedure update_var_values_ptr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value_ptr : in stm_values_ptr
    );

    procedure init_var_txt(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : in text_object_ptr
    );

    procedure update_var_txt(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : in text_object_ptr
    );

    procedure init_var_arr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr_len : in unsigned;
        constant machine_value_width : integer
    );

    procedure update_var_arr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : in stm_array_ptr
    );

    procedure init_var_label(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable par_text_field : in text_field
    );

    procedure update_var_label(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    );

    procedure init_var_label_ptr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    );
    
    procedure init_var_lines(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    );

    procedure update_var_lines(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    );

    procedure print_inst_element(
        variable insts : in inst_sequence;
        variable inst_element_num : in integer
    );

    procedure dump_inst_sequence(
        variable insts : in inst_sequence
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

    procedure dump_proc_pool_ordered(
        variable procs : in proc_pool_ordered
    );

    procedure dump_proc_element(
        variable procs : in proc_pool_ordered;
        variable proc_element_num : in integer
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
        variable rc : in stm_runtime_context;
        constant prefix_lines : string
    );

    procedure search_var_element_number(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable ien : out integer
    );

    procedure search_proc_element_number(
        variable procs : in proc_pool_ordered;
        variable proc_fqn : in text_field;
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
        variable slc : in src_locator;
        variable ts : in token_text_field_array;
        variable vars : in var_pool_ordered;
        variable iic : inout stm_inst_initial_context
    );

    procedure insert_proc_element(
        variable slc : in src_locator;
        variable procs : inout proc_pool_ordered;
        variable proc_namespace : in text_field;
        variable proc_name : in text_field;
        constant debug : boolean;
        variable pen : out integer
    );

    procedure insert_var_element(
        variable slc : in src_locator;
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable inst_args : inst_arguments;
        constant var_type : in stm_var_type;
        constant machine_value_width : in integer;
        constant debug : in boolean;
        variable ven : out integer
    );

end package;
