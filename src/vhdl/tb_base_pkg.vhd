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

package tb_base_pkg is

    -- constants
    constant max_str_len : integer := 512;
    constant max_field_len : integer := 128;
    constant c_stm_text_len : integer := 500;
    constant max_num_of_inst_elements : integer := 1000000;

    -- file handles
    file stimulus : text; -- file main file



    type base is (bin, oct, hex, dec);  
    type state_register is array (7 downto 0) of boolean;
    type int_array is array (1 to 128) of integer;
    type stack_int_array is array (0 to 127) of integer;
    type stack_int_array_array is array (0 to 15) of stack_int_array;
    type boolean_array is array (0 to 127) of boolean;
    type interrupt_array is array (0 to 127) of integer;

    subtype text_field is string(1 to max_field_len);
    type text_field_ptr is access text_field;
    subtype text_line is string(1 to max_str_len);
    subtype stm_text is string(1 to c_stm_text_len);
    type stm_text_ptr is access stm_text;

    type unmerged_token_text_field_array is array (1 to 9) of text_field;
    type token_text_field_array is array (1 to 7) of text_field;
    type parameter_scope_text_field_array is array (1 to 6) of text_field;
    type parameter_text_field_array is array (1 to 6) of text_field;
    type parameter_index_array is array (1 to 6) of integer;
    type parameter_value_array is array (natural range <>) of unsigned;

    type stack_array_of_parameter_scope_text_field_array is array (31 downto 0) of parameter_scope_text_field_array;
    type stack_text_line_array is array (31 downto 0) of text_line;
    type stack_numbers_array is array (31 downto 0) of integer;

    type t_stm_value is array (natural range <>) of unsigned;
    type t_stm_value_ptr is access t_stm_value;
    
    type slice is record
         left :integer;
         right :integer;
    end record;
    
    type src_locator is record
         file_name : text_line;
         file_line :integer;
    end record;
   
    type inst_def_element;
    type inst_def_element_ptr is access inst_def_element;
    type inst_def_element is record
        inst : text_field;
        inst_len : integer;
        num_of_params : integer;
    end record;
    type inst_def_element_ptrs is array (0 to max_num_of_inst_def_elements - 1) of inst_def_element;    
    type inst_def_list is record
        element_ptrs : inst_def_element_ptrs;
        last_element_num : integer;
    end record;    

    type file_def_element;
    type file_def_element_ptr is access file_def_element;
    type file_def_element is record
        absolute_file_name : text_line;
    end record;
    type file_def_list is record
        element_ptrs : file_def_element_ptrs;
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
        src_loc : src_locator;
        inst : text_field;
        inst_args : inst_arguments;
    end record;
    type inst_element_ptrs is array (0 to max_num_of_inst_elements - 1) of inst_element;
    type inst_sequence is record
        element_ptrs : inst_element_ptrs;
        last_element_num : integer;
    end record; 

    type t_stm_array is array (natural range <>) of unsigned;
    type t_stm_array_ptr is access t_stm_array;

    type t_stm_line_type is (STM_LINE_TEXT_TYPE,
        STM_LINE_ARRAY_TYPE
    );

    type t_stm_line;
    type t_stm_line_ptr is access t_stm_line;
    type t_stm_line is record
        line_number : integer;
        line_content : line;
        line_type : t_stm_line_type;
        array_size : integer;
        next_stm_line : t_stm_line_ptr;
    end record;

    type t_stm_lines;
    type t_stm_lines_ptr is access t_stm_lines;
    type t_stm_lines is record
        stm_line_list : t_stm_line_ptr;
        size : integer;
        next_stm_lines : t_stm_lines_ptr;
    end record;

    type t_stm_var_type is (
        STM_VALUE,
        STM_CONST,
        STM_TEXT,
        STM_ARRAY,
        STM_LINES,
        STM_BUS,
        STM_SIGNAL,
        STM_PROC,
        STM_LABEL,
        STM_NO_VAR
    );

    type stm_inst_initial_context is record
        in_namespace : boolean;
        in_proc_parameters : boolean;
        in_proc_body : boolean;
        in_call_parameters : boolean;
        in_call_label_parameters : boolean;
        in_namespace_name : text_field;
        in_proc_name : text_field;
        in_called_proc_name : text_field;
    end record;
    
    type stm_call_process_state_type is (
        NONE,
        IN_PROC_PARAMS,
        IN_CALL_PARAMS
    );

    type stm_runtime_context is record
        inst_element_number_to_return_to_after_call : integer;
        inst_element_number_of_called_proc : integer;
        inst_element_number_of_called_proc_params_end : integer;
        inst_element_number_of_call_params : integer;
        call_process_state : t_stm_call_process_state_type;    
        called_proc_name : text_field;
        called_in_file_line : integer;
        called_in_file_name : text_line;    
        par_scopes : parameter_scope_text_field_array;  
        loop_num : integer;
        curr_loop_count : stack_int_array;
        term_loop_count : stack_int_array;
        loop_line: stack_int_array;
        loop_if_enter_level : integer;
    end record;
    
    type stm_array_of_runtime_context is array (31 downto 0) of t_stm_runtime_context; 

    -- define the variables element and pointer
    type var_element;
    type var_element_ptr is access var_element;
    type var_element is record
        var_src_loc : src_locator;
        var_name : text_field;
        var_scope : text_field;
        var_value : t_stm_value_ptr;
        var_org_value : t_stm_value_ptr;
        var_label_proc_ref : text_field_ptr;
        var_org_label_proc_ref : text_field_ptr;
        var_stm_type : t_stm_var_type;
        var_stm_text : stm_text_ptr;
        var_stm_text_enclosing_quote : character;
        var_org_stm_text : stm_text_ptr;
        var_org_stm_text_enclosing_quote : character;
        var_stm_array : t_stm_array_ptr;
        var_org_stm_array : t_stm_array_ptr;
        var_stm_lines : t_stm_lines_ptr;
        var_org_stm_lines : t_stm_lines_ptr;
        next_rec : var_field_ptr;
    end record;
    type var_element_ptrs is array ( 0 to max_num_of_var_elements - 1) of var_element_ptr;    
    type var_pool_ordered is record
        element_ptrs : var_element_ptrs;
        last_element_num : integer;
    end record;
    
    -- define the proc element and pointer
    type proc_element;
    type proc_element_ptr is access proc_element;
    type proc_element is record
        proc_src_loc : src_locator;
        proc_name : text_field;
        proc_element_num : integer;
        proc_inst_element_num : integer;
    end record;
    type proc_element_ptrs is array ( 0 to max_num_of_proc_elements - 1) of proc_field_ptr;
    type proc_pool_ordered is record
        element_ptrs : proc_element_ptrs;
        last_element_num : integer;
    end record;
    
    procedure set_var_type(
        variable inst : in text_field;
        variable var_type : out t_stm_var_type
    );
 
    procedure insert_proc_element(
        variable procs : inout proc_pool_ordered;
        variable pe : proc_field_ptr
    );
    
    procedure init_inst_sequence(
        variable insts : inout inst_sequence
    );

    procedure init_inst_initial_context(
        variable ipc : inout stm_inst_initial_context
    );

    -- bin2integer    convert bin stimulus field to integer
    --          inputs :  string of type text_field containing only binary numbers
    --          return :  integer value
    function bin2integer(
        bin_number : in text_field;
        file_name : in text_line;
        file_line : in integer
    ) return integer;

    -- bin2t_stm_value    convert bin stimulus field to t_stm_value
    --          inputs :  string of type text_field containing only binary numbers
    --          return :  unsigned value
    function bin2stm_value(
        bin_number : in text_field;
        file_name : in text_line;
        file_line : in integer;
        stm_value_width : in integer
    ) return unsigned;

    function c2int(
        c : in character
    ) return integer;

    -- convert character to 4 bit vector
    --   input    character
    --   output   std_logic_vector  4 bits
    function c2std_vec(
        c : in character
    ) return std_logic_vector;

    procedure check_presence_inst_file_name(
        variable file_list : inout file_def_ptr;
        variable file_name : in text_line;
        variable present : out boolean
    );

    function ew_str_cat(
        s1 : stm_text;
        s2 : text_field
    ) return stm_text;

    procedure ew_str_cat_ptr(
        variable s1 : in stm_text;
        variable s2_ptr : in text_field_ptr;
        variable so : out stm_text
    );

    function textfield_dot_cat(
        s1 : text_field;
        s2 : text_field
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

    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_text_field(
        int : integer;
        b : base
    ) return text_field;

    --  to_str function  with base parameter
    --     convert t_stm_value to number base
    function ew_to_text_field(
        stmvalue : unsigned;
        b : base
    ) return text_field;

    -- fld_equal  check text field for equality
    --          inputs :  text field s1 and s2
    --          return :  true if text fields are equal; false otherwise.
    function fld_equal(
        s1 : in text_field;
        s2 : in text_field
    ) return boolean;
    
    function fld_order_less_than(
        s1 : in text_field;
        s2 : in text_field
    ) return boolean;

    -- fld_len    field length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function fld_len(
        s : in text_field
    ) return integer;

    procedure get_inst_file_name(
        variable file_list : inout file_def_ptr;
        variable file_idx : integer;
        variable file_name : inout text_line
    );

    -- procedure to get a line from a string
    procedure get_line_from_str(
        variable s : in string;
        variable std_line : inout line
    );

    -- procedure to get stm_text pointer from a line
    procedure get_stm_text_ptr_from_line(
        variable std_line : inout line;
        variable var_stm_text_ptr : inout stm_text_ptr
    );

    --  get a random intetger number
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

    -- hex2integer    convert hex stimulus field to integer
    --          inputs :  string of type text_field containing only hex numbers
    --          return :  integer value
    function hex2integer(
        hex_number : in text_field;
        file_name : in text_line;
        file_line : in integer
    ) return integer;

    -- hex2integer    convert hex stimulus field to t_stm_value
    --          inputs :  string of type text_field containing only hex numbers
    --          return :  t_stm_value value
    function hex2stm_value(
        hex_number : in text_field;
        file_name : in text_line;
        file_line : in integer;
        stm_value_width : in integer
    ) return unsigned;

    function is_digit(
        constant c : in character
    ) return boolean;

    function is_txt_var_first_character(
        constant c : in character
    ) return boolean;

    function is_space(
        constant c : in character
    ) return boolean;

    procedure init_text_field(
        variable sourcestr : in string;
        variable destfield : out text_field
    );

    procedure init_const_text_field(
        constant sourcestr : in string;
        variable destfield : out text_field
    );

    -- procedure to print loggings to stdout
    procedure print(
        s : in string
    );

    --  std_vec2c  convert 4 bit std_vector to a character
    --     input  std_logic_vector 4 bits
    --     output  character
    function std_vec2c(
        vec : in std_logic_vector(3 downto 0)
    ) return character;

    -- stim_to_integer    convert stimulus field to integer
    --          inputs :  string of type text_field "stimulus format of number"
    --          return :  integer value
    function stim_to_integer(
        field : in text_field;
        file_name : in text_line;
        file_line : in integer
    ) return integer;

    -- stim_to_integer    convert stimulus field to t_stm_value
    --          inputs :  string of type text_field "stimulus format of number"
    --          return :  t_stm_value value
    function stim_to_stm_value(
        field : in text_field;
        file_name : in text_line;
        file_line : in integer;
        stm_value_width : in integer
    ) return unsigned;

    procedure stm_file_append(
        variable stm_lines : in t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer
    );

    procedure stm_file_appendable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    procedure stm_file_read_all(
        variable stm_lines : inout t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer
    );

    procedure stm_file_readable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    function stm_file_status(
        v_stat : file_open_status
    ) return integer;

    procedure stm_file_write(
        variable stm_lines : in t_stm_lines_ptr;
        variable file_path : in stm_text_ptr;
        variable valid : out integer
    );

    procedure stm_file_writeable(
        variable file_path : in stm_text_ptr;
        variable status : out integer
    );

    procedure stm_lines_append(
        variable stm_lines : inout t_stm_lines_ptr;
        variable std_line : in line;
        variable valid : out integer
    );

    procedure stm_lines_append(
        variable stm_lines : inout t_stm_lines_ptr;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer;
        constant stm_value_width : in integer
    );

    procedure stm_lines_append(
        variable stm_lines : inout t_stm_lines_ptr;
        variable var_stm_text : in stm_text_ptr;
        variable valid : out integer
    );

    procedure stm_lines_delete(
        variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable valid : out integer
    );

    procedure stm_lines_get(
        variable stm_lines : in t_stm_lines_ptr;
        variable position : in integer;
        variable std_line : out line;
        variable valid : out integer
    );

    procedure stm_lines_get(
        variable stm_lines : in t_stm_lines_ptr;
        variable position : in integer;
        variable stm_array : inout t_stm_array_ptr;
        variable number_found : out integer;
        variable valid : out integer;
        constant stm_value_width : in integer
    );

    procedure stm_lines_insert(
        variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr;
        variable valid : out integer
    );

    procedure stm_lines_insert(
        variable stm_lines : inout t_stm_lines_ptr;
        variable position : integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer;
        constant stm_value_width : in integer
    );

    procedure stm_lines_print(
        variable stm_lines : in t_stm_lines_ptr;
        variable valid : out integer
    );

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
        variable position : in integer;
        variable var_stm_text : in stm_text_ptr;
        variable valid : out integer);

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
        variable position : integer;
        variable stm_array : in t_stm_array_ptr;
        variable valid : out integer;
        constant stm_value_width : in integer);

    --  function short text_line (remove 'nul')
    function stm_text_crop(
        txt : in stm_text
    ) return string;

    -- stm_text_len    stm_text length
    --          inputs :  string of type stm_text
    --          out :  integer number of non 'nul' chars
    function stm_text_len(
        s : in stm_text
    ) return integer;

    --  procedure to get line of the txt pointer
    procedure stm_text_ptr_to_line(
        variable var_stm_text : in stm_text_ptr;
        variable line_out : out line
    );

    -- stm_text_ptr_truncate_trailing_quote
    --          inputs :  stm_text pointer
    --          inout :  adjusted stm_text
    procedure stm_text_ptr_truncate_trailing_quote(
        variable si : stm_text_ptr;
        variable so : inout stm_text_ptr
    );

    -- str2integer   convert a string to integer number.
    --   inputs  :  string
    --   output  :  int value
    function str2integer(
        str : in string
    ) return integer;

    -- str2integer   convert a string to integer number.
    --   inputs  :  string
    --   output  :  stm_value
    function str2stm_value(
        str : in string;
        stm_value_width : in integer
    ) return unsigned;

    --  function short text_line (remove 'nul')
    function text_line_crop(
        txt : in text_line
    ) return string;

    -- text_line_len    text_line length
    --          inputs :  string of type text_line
    --          return :  integer number of non 'nul' chars
    function text_line_len(
        s : in text_line
    ) return integer;

    --  procedure to print to the stdout the txt pointer
    procedure txt_print(
        variable ptr : in stm_text_ptr
    );

    --  procedure copy text into an existing pointer
    procedure txt_ptr_copy(
        variable ptr : in stm_text_ptr;
        variable ptr_o : out stm_text_ptr;
        variable txt_str : in stm_text
    );

    --  procedure to get string of the txt pointer
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

    -- function to get string of the txt field
    function txt_field_to_string(
        s : in text_field
    ) return string;

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

end package;
