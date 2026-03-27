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

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_limits_pkg.all;

package tb_base_pkg is
    
    constant TRACE_EXECUTED_LINES : integer := 0;
    constant TRACE_INSTRUCTIONS : integer := 1;
    constant TRACE_VARIABLES : integer := 2;
    constant TRACE_FILES : integer := 3;
    constant TRACE_IF_TREES : integer := 4;
    constant TRACE_CALLS : integer := 5;
    constant TRACE_INTERRUPTS : integer := 6;
    constant TRACE_STACK : integer := 7;
    
    type base is (bin, oct, hex, dec);  
    type state_register is array (7 downto 0) of boolean;
    type int_array is array (1 to 128) of integer;
    type loop_nested_int_array is array (0 to 127) of integer;
    type boolean_array is array (0 to 127) of boolean;
    type interrupt_array is array (0 to 127) of integer;

    subtype text_field is string(1 to max_field_len);
    type text_field_ptr is access text_field;
    subtype text_line is string(1 to max_str_len);
    subtype stm_text is string(1 to c_stm_text_len);
    type stm_text_ptr is access stm_text;
    
    type unmerged_token_text_field_array is array (1 to 9) of text_field;
    type token_text_field_array is array (1 to 7) of text_field;
    type parameter_text_field_array is array (1 to 6) of text_field;
    type parameter_index_array is array (1 to 6) of integer;
    type parameter_value_array is array (natural range <>) of unsigned;

    type stack_text_line_array is array (31 downto 0) of text_line;
    type stack_numbers_array is array (31 downto 0) of integer;

    type stm_value is array (natural range <>) of unsigned;
    type stm_values_ptr is access stm_value;
    
    type slice is record
         left :integer;
         right :integer;
    end record;
    
    type src_locator is record
         file_name : text_field;
         file_line :integer;
    end record;
    
    type file_def_element;
    type file_def_element_ptr is access file_def_element;
    type file_def_element is record
        slc : src_locator;
        absolute_file_name : text_line;
        file_name : text_field;
    end record;
    type file_def_element_ptrs is array (0 to max_num_of_file_def_elements - 1) of file_def_element_ptr; 
    type file_def_list is record
        element_ptrs : file_def_element_ptrs;
        last_element_num : integer;
    end record; 

    type inst_def_element;
    type inst_def_element_ptr is access inst_def_element;
    type inst_def_element is record
        inst : text_field;
        inst_len : integer;
        num_of_params : integer;
    end record;
    type inst_def_element_ptrs is array (0 to max_num_of_inst_def_elements - 1) of inst_def_element_ptr;    
    type inst_def_list is record
        element_ptrs : inst_def_element_ptrs;
        last_element_num : integer;
    end record;

    type inst_arguments is record
        par_text_fields : parameter_text_field_array;
        txt : stm_text_ptr;
        txt_enclosing_quote : character;    
    end record;
   
    type inst_element;
    type inst_element_ptr is access inst_element;
    type inst_element is record
        slc : src_locator;
        inst : text_field;
        inst_len : integer;
        inst_args : inst_arguments;
    end record;
    type inst_element_ptrs is array (0 to max_num_of_inst_elements - 1) of inst_element_ptr;
    type inst_sequence is record
        element_ptrs : inst_element_ptrs;
        last_element_num : integer;
    end record; 

    type stm_array is array (natural range <>) of unsigned;
    type stm_array_ptr is access stm_array;

    type stm_line_type is (T_LINE_TEXT,
        T_LINE_ARRAY
    );

    type stm_line;
    type stm_line_ptr is access stm_line;
    type stm_line is record
        line_number : integer;
        line_content : line;
        line_type : stm_line_type;
        array_size : integer;
        next_line_ptr : stm_line_ptr;
    end record;

    type stm_lines;
    type stm_lines_ptr is access stm_lines;
    type stm_lines is record
        line_list : stm_line_ptr;
        size : integer;
        next_lines_ptr : stm_lines_ptr;
    end record;

    type stm_var_type is (
        T_VALUE,
        T_CONST,
        T_TEXT,
        T_ARRAY,
        T_LINES,
        T_BUS,
        T_SIGNAL,
        T_LABEL,
        T_NO_VAR
    );

    type stm_code_section is (
        NONE,
        PROC_BODY,
        PROC_PARAMS,
        CALL_PARAMS
    );

    type stm_inst_initial_context is record
        is_var_declaration : boolean;
        code_section : stm_code_section;
        namespace_name : text_field;
        proc_name : text_field;
        called_proc_name : text_field;
    end record;
    
    type stm_call_process_state is (
        IN_NONE,
        IN_PROC_PARAMS,
        IN_PROC_BODY,
        IN_CALL_PARAMS
    );
    
    type stm_runtime_context is record
        call_process_state : stm_call_process_state;  
        ien_of_call : integer;
        ien_of_proc_params_end : integer;
        ien_of_called_proc : integer; 
        loop_num : integer;
        loop_if_enter_level : integer;
        curr_loop_count : loop_nested_int_array;
        term_loop_count : loop_nested_int_array;
        loop_line: loop_nested_int_array;
    end record;
    
    type stm_array_of_runtime_context is array (max_num_of_stack_elements downto 0) of stm_runtime_context; 

    type var_element;
    type var_element_ptr is access var_element;
    type var_element is record
        slc : src_locator;
        name : text_field;
        values : stm_values_ptr;
        values_org : stm_values_ptr;
        label_proc_ref : text_field_ptr;
        label_proc_ref_org : text_field_ptr;
        typ : stm_var_type;
        txt : stm_text_ptr;
        txt_enclosing_quote : character;
        txt_org : stm_text_ptr;
        txt_enclosing_quote_org : character;
        arr : stm_array_ptr;
        arr_org : stm_array_ptr;
        lines : stm_lines_ptr;
        lines_org : stm_lines_ptr;
    end record;
    type var_element_ptrs is array ( 0 to max_num_of_var_elements - 1) of var_element_ptr;    
    type var_pool_ordered is record
        element_ptrs : var_element_ptrs;
        last_element_num : integer;
    end record;
    
    type proc_element;
    type proc_element_ptr is access proc_element;
    type proc_element is record
        slc : src_locator;
        name : text_field;
        pointer_to_ien : integer;
    end record;
    type proc_element_ptrs is array ( 0 to max_num_of_proc_elements - 1) of proc_element_ptr;
    type proc_pool_ordered is record
        element_ptrs : proc_element_ptrs;
        last_element_num : integer;
    end record;
    
    procedure init_inst_def_list(
        variable inst_defs : inout inst_def_list
    );    
    
    procedure init_file_def_list(
        variable files : inout file_def_list
    );
    
    procedure init_inst_sequence(
        variable insts : inout inst_sequence
    );
    
    procedure init_var_pool_ordered(
        variable vars : inout var_pool_ordered
    );
    
    procedure init_proc_pool_ordered(
        variable procs : inout proc_pool_ordered
    );
            
    procedure init_inst_initial_context(
        variable iic : inout stm_inst_initial_context
    );
    
    procedure init_runtime_context(
        variable rc : inout stm_runtime_context
    );
    
    function var_type_to_string( 
        vt :stm_var_type
    ) return string;
        
    procedure append_inst(
        variable insts : inout inst_sequence;
        variable ie : inst_element;
        constant debug : boolean 
    );
    
    procedure append_code_file(
        variable slc : src_locator;
        variable code_files : inout file_def_list;
        constant stimulus_path : in string;
        variable stimulus_file : in string
    );
    
    function combine_to_absolute_file_name(
        path_name : in string; 
        file_name : in string
    ) return text_line;
        
    function extract_parameters(
        ts : token_text_field_array
    ) return parameter_text_field_array;
 
    function bin2integer(
        slc : src_locator;
        bin_number : text_field
    ) return integer;

    function bin2stm_value(
        slc : src_locator;
        bin_number : text_field;
        machine_value_width : integer
    ) return unsigned;

    function c2int(
        c : character
    ) return integer;

    function c2std_vec(
        c : character
    ) return std_logic_vector;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field
    ) return stm_text;

    procedure ew_str_cat_ptr(
        variable s1 : in stm_text;
        variable s2_ptr : in text_field_ptr;
        variable so : out stm_text
    );

    function textfield_cat(
        s1 : text_field;
        s2 : text_field
    ) return text_field;

    function cat_var_name_local_scope(
        s1 : text_field;
        s2 : text_field
    ) return text_field;
    
    function cat_namespace_var_name_local_scope(
        s1 : text_field;
        s2 : text_field;
        s3 : text_field
    )  return text_field;
    
    function textfield_truncate_text_after_second_dot(
        s : text_field
    ) return text_field;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field;
        s3 : integer
    ) return stm_text;

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field;
        s3 : integer;
        s4 : character
    ) return stm_text;

    function ew_to_char(
        int : integer
    ) return character;

    function ew_to_text_field(
        int : integer;
        b : base
    ) return text_field;

    function ew_to_text_field(
        stmvalue : unsigned;
        b : base
    ) return text_field;

    function fld_equal(
        s1 : in text_field;
        s2 : in text_field
    ) return boolean;
    
    procedure fld_order(
        s1 : in text_field;
        s2 : in text_field;
        is_equ : out boolean;
        is_less : out boolean
    );
    
    function order_is_less_than_failure_on_equal(
        slc : src_locator;
        s1 : text_field;
        s2 : text_field
    ) return boolean;

    function fld_len(
        s : text_field
    ) return integer;

    procedure get_line_from_str(
        variable s : in string;
        variable std_line : inout line
    );

    procedure get_stm_text_ptr_from_line(
        variable std_line : inout line;
        variable var_stm_text_ptr : inout stm_text_ptr
    );

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable rand : out real
    );

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable lowestvalue : in integer;
        variable utmostvalue : in integer;
        variable rand : out integer
    );

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable rand : out unsigned
    );

    procedure random(
        variable seed1 : inout positive;
        variable seed2 : inout positive;
        variable lowestvalue : in unsigned;
        variable utmostvalue : in unsigned;
        variable rand : out unsigned
    );

    function hex2integer(
        slc : src_locator;
        hex_number : text_field 
    ) return integer;

    function hex2stm_value(
        slc : src_locator;
        hex_number : text_field;
        machine_value_width : integer
    ) return unsigned;

    function is_digit(
        constant c : character
    ) return boolean;

    function is_txt_var_first_character(
        constant c : character
    ) return boolean;

    function is_space(
        constant c : character
    ) return boolean;

    procedure init_text_field(
        variable sourcestr : in string;
        variable destfield : out text_field
    );

    procedure init_const_text_field(
        constant sourcestr : in string;
        variable destfield : out text_field
    );

    procedure print(
        s : in string
    );

    function std_vec2c(
        vec : in std_logic_vector(3 downto 0)
    ) return character;

    function stim_to_integer(
        slc : src_locator;
        field : text_field
    ) return integer;

    function stim_to_stm_value(
        slc : src_locator;
        field : text_field;
        machine_value_width : integer
    ) return unsigned;
    
    procedure stm_user_file_open(
        variable slc : in src_locator;   
        file file_handle : text;        
        variable user_file_path_string : in stm_text;
        open_kind : in file_open_kind
    );

    procedure stm_file_append(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable file_path : in stm_text_ptr
    );

    procedure stm_file_appendable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    procedure stm_file_read_all(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable file_path : in stm_text_ptr
    );

    procedure stm_file_readable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    function stm_file_status(
        v_stat : file_open_status
    ) return integer;

    procedure stm_file_write(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable file_path : in stm_text_ptr
    );

    procedure stm_file_writeable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable std_line : in line
    );

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer
    );

    procedure stm_lines_append(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable var_stm_text : in stm_text_ptr
    );

    procedure stm_lines_delete(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer
    );

    procedure stm_lines_get(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable position : in integer;
        variable std_line : out line
    );

    procedure stm_lines_get(
        variable slc : src_locator;
        variable stm_lines : in stm_lines_ptr;
        variable position : in integer;
        variable stm_array : inout stm_array_ptr;
        variable number_found : out integer;
        constant machine_value_width : in integer
    );

    procedure stm_lines_insert(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr
    );

    procedure stm_lines_insert(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : integer;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer
    );

    procedure stm_lines_print(
        variable stm_lines : in stm_lines_ptr
    );

    procedure stm_lines_set(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr
    );

    procedure stm_lines_set(
        variable slc : src_locator;
        variable stm_lines : inout stm_lines_ptr;
        variable position : integer;
        variable stm_array : in stm_array_ptr;
        constant machine_value_width : in integer);

    function stm_text_crop(
        txt : stm_text
    ) return string;

    function stm_text_len(
        s : stm_text
    ) return integer;

    procedure stm_text_ptr_to_line(
        variable var_stm_text : in stm_text_ptr;
        variable line_out : out line
    );

    procedure stm_text_ptr_truncate_trailing_quote(
        variable si : stm_text_ptr;
        variable so : inout stm_text_ptr
    );

    function str2integer(
        str : string
    ) return integer;

    function str2stm_value(
        str : string;
        machine_value_width : integer
    ) return unsigned;

    function text_line_crop(
        txt : text_line
    ) return string;
    
    function crop(
        s : string
    ) return string;

    function text_line_len(
        s : text_line
    ) return integer;

    procedure txt_print(
        variable ptr : in stm_text_ptr
    );

    procedure txt_ptr_copy(
        variable ptr : in stm_text_ptr;
        variable ptr_o : out stm_text_ptr;
        variable txt_str : in stm_text
    );

    procedure txt_to_string(
        variable ptr : in stm_text_ptr;
        variable str : out stm_text
    );

    procedure text_field_ptr_to_text_field(
        variable ptr : in text_field_ptr;
        variable field : out text_field
    );

    procedure text_field_to_text_field_ptr(
        variable field : in text_field;
        variable ptr : inout text_field_ptr
    );

    function text_field_to_string(
        tf : text_field
    ) return string;
    
    function string_to_text_field(
        s : string
    ) return text_field;

    procedure stm_text_copy_to_ptr(
        variable ptr : inout stm_text_ptr;
        variable txt_str : in stm_text
    );

    function to_text_field_hex(
        int : integer
    ) return text_field;

    function to_text_field(
        int : integer
    ) return text_field;

    function to_text_field_hex(
        stmvalue : unsigned
    ) return text_field;

    function to_text_field(
        stmvalue : unsigned
    ) return text_field;
    
    procedure dump_text_line(
        variable tl : in text_line;
        constant prefix : in string
    );
    
end package;
