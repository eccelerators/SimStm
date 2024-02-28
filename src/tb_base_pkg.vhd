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

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_base_pkg is

    -- constants
    constant max_str_len : integer := 256;
    constant max_field_len : integer := 128;
    constant c_stm_text_len : integer := 200;

    -- file handles
    file stimulus : text; -- file main file

    -- type def's
    type base is (bin, oct, hex, dec);
    type stack_register is array (31 downto 0) of integer;
    type state_register is array (7 downto 0) of boolean;
    type int_array is array (1 to 128) of integer;
    type stack_int_array is array (0 to 127) of integer;
    type stack_int_array_array is array (0 to 15) of stack_int_array;
    type boolean_array is array (0 to 127) of boolean;
    type interrupt_array is array (0 to 127) of integer;

    subtype text_field is string(1 to max_field_len);
    subtype text_line is string(1 to max_str_len);
    subtype stm_text is string(1 to c_stm_text_len);
    type stm_text_ptr is access stm_text;
    
    type stack_text_field_array is array(31 downto 0) of text_field;
    type stack_text_line_array is array(31 downto 0) of text_line;
    type stack_numbers_array is array(31 downto 0) of integer;
    
    -- define the stimulus line record and access
    type stim_line;
    type stim_line_ptr is access stim_line; -- pointer to stim_line record
    type stim_line is record
        instruction : text_field;
        inst_field_1 : text_field;
        inst_field_2 : text_field;
        inst_field_3 : text_field;
        inst_field_4 : text_field;
        inst_field_5 : text_field;
        inst_field_6 : text_field;
        txt : stm_text_ptr;
        txt_enclosing_quote : character;
        line_number : integer; -- sequence line
        num_of_lines : integer; -- total number of lines
        file_line : integer; -- file line number
        file_idx : integer;
        next_rec : stim_line_ptr;
    end record;

    -- define the instruction structure
    type inst_def;
    type inst_def_ptr is access inst_def;
    type inst_def is record
        instruction : text_field;
        instruction_l : integer;
        params : integer;
        next_rec : inst_def_ptr;
    end record;

    -- define the file handle record
    type file_def;
    type file_def_ptr is access file_def;
    type file_def is record
        rec_idx : integer;
        file_name : text_line;
        next_rec : file_def_ptr;
    end record;

    type t_stm_array is array (natural range <>) of integer;
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

    type t_stm_var_type is (STM_VALUE_TYPE,
                            STM_CONST_VALUE_TYPE,
                            STM_TEXT_TYPE,
                            STM_ARRAY_TYPE,
                            STM_LINES_TYPE,
                            STM_BUS_TYPE,
                            STM_SIGNAL_TYPE,
                            STM_LABEL_TYPE,
                            NO_VAR_TYPE
                           );

    -- define the variables field and pointer
    type var_field;
    type var_field_ptr is access var_field; -- pointer to var_field
    type var_field is record
        var_name : text_field;
        var_index : integer;
        var_value : integer;
        var_stm_type : t_stm_var_type;
        var_stm_text : stm_text_ptr;
        var_stm_text_enclosing_quote : character;
        var_stm_array : t_stm_array_ptr;
        var_stm_lines : t_stm_lines_ptr;
        next_rec : var_field_ptr;
    end record;

    -- bin2integer    convert bin stimulus field to integer
    --          inputs :  string of type text_field containing only binary numbers
    --          return :  integer value
    function bin2integer(bin_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer;

    function c2int(c : in character) return integer;

    -- convert character to 4 bit vector
    --   input    character
    --   output   std_logic_vector  4 bits
    function c2std_vec(c : in character) return std_logic_vector;

    procedure check_presence_instruction_file_name(file_list : inout file_def_ptr;
                                                   file_name : in string;
                                                   present : out boolean);

    function ew_str_cat(s1 : stm_text;
                        s2 : text_field) return stm_text;
                        
    function ew_str_cat(s1 : stm_text;
                        s2 : text_field;
                        s3 : integer) return stm_text;
                        
    function ew_str_cat(s1 : stm_text;
                        s2 : text_field;
                        s3 : integer;
                        s4 : character ) return stm_text;

    function ew_to_char(int : integer) return character;

    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_str(int : integer;
                       b : base) return text_field;

    -- fld_equal  check text field for equality
    --          inputs :  text field s1 and s2
    --          return :  true if text fields are equal; false otherwise.
    function fld_equal(s1 : in text_field;
                       s2 : in text_field) return boolean;

    -- fld_len    field length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function fld_len(s : in text_field) return integer;

    procedure get_instruction_file_name(file_list : inout file_def_ptr;
                                        file_idx : integer;
                                        file_name : inout text_line);

    -- procedure to get a line from a string
    procedure get_line_from_str(s : in string;
                                std_line : inout line);

    -- procedure to get stm_text pointer from a line
    procedure get_stm_text_ptr_from_line(std_line : inout line;
                                         var_stm_text_ptr : inout stm_text_ptr);

    --  get a random intetger number
    procedure getrandint(variable seed1 : inout positive;
                         variable seed2 : inout positive;
                         variable lowestvalue : in integer;
                         variable utmostvalue : in integer;
                         variable randint : out integer);

    -- hex2integer    convert hex stimulus field to integer
    --          inputs :  string of type text_field containing only hex numbers
    --          return :  integer value
    function hex2integer(hex_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer;

    function is_digit(constant c : in character) return boolean;

    function is_space(constant c : in character) return boolean;

    procedure init_text_field(variable sourcestr : in string;
                              variable destfield : out text_field);
                              
    procedure init_const_text_field(constant sourcestr : in string;
                              variable destfield : out text_field);

    -- procedure to print loggings to stdout
    procedure print(s : in string);

    --  std_vec2c  convert 4 bit std_vector to a character
    --     input  std_logic_vector 4 bits
    --     output  character
    function std_vec2c(vec : in std_logic_vector(3 downto 0)) return character;

    -- stim_to_integer    convert stimulus field to integer
    --          inputs :  string of type text_field "stimulus format of number"
    --          return :  integer value
    function stim_to_integer(field : in text_field;
                             file_name : in text_line;
                             line : in integer) return integer;

    procedure stm_file_append(variable stm_lines : in t_stm_lines_ptr;
                              variable file_path : in stm_text_ptr;
                              variable valid : out integer);

    procedure stm_file_appendable(variable file_path : in stm_text_ptr;
                                  variable status : out integer);

    procedure stm_file_read_all(variable stm_lines : inout t_stm_lines_ptr;
                                variable file_path : in stm_text_ptr;
                                variable valid : out integer);

    procedure stm_file_readable(variable file_path : in stm_text_ptr;
                                variable status : out integer);

    function stm_file_status(v_stat : file_open_status) return integer;

    procedure stm_file_write(variable stm_lines : in t_stm_lines_ptr;
                             variable file_path : in stm_text_ptr;
                             variable valid : out integer);

    procedure stm_file_writeable(variable file_path : in stm_text_ptr;
                                 variable status : out integer);

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable std_line : in line;
                               variable valid : out integer);

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable stm_array : in t_stm_array_ptr;
                               variable valid : out integer);

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable var_stm_text : in stm_text_ptr;
                               variable valid : out integer);

    procedure stm_lines_delete(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : in integer;
                               variable valid : out integer);

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
                            variable position : in integer;
                            variable std_line : out line;
                            variable valid : out integer);

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
                            variable position : in integer;
                            variable stm_array : inout t_stm_array_ptr;
                            variable number_found : out integer;
                            variable valid : out integer);

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : in integer;
                               variable var_stm_text : in stm_text_ptr;
                               variable valid : out integer);

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : integer;
                               variable stm_array : in t_stm_array_ptr;
                               variable valid : out integer);

    procedure stm_lines_print(variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer);

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
                            variable position : in integer;
                            variable var_stm_text : in stm_text_ptr;
                            variable valid : out integer);

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
                            variable position : integer;
                            variable stm_array : in t_stm_array_ptr;
                            variable valid : out integer);

    --  procedure copy stm_text into an existing pointer
    procedure stm_text_copy_to_ptr(variable ptr : inout stm_text_ptr;
                                   variable txt_str : in stm_text);

    --  function short text_line (remove 'nul')
    function stm_text_crop(txt : in stm_text) return string;

    -- stm_text_len    stm_text length
    --          inputs :  string of type stm_text
    --          out :  integer number of non 'nul' chars
    function stm_text_len(s : in stm_text) return integer;

    --  procedure to get line of the txt pointer
    procedure stm_text_ptr_to_line(variable var_stm_text : in stm_text_ptr;
                                   variable line_out : out line);

    -- stm_text_ptr_truncate_trailing_quote
    --          inputs :  stm_text pointer
    --          inout :  adjusted stm_text
    procedure stm_text_ptr_truncate_trailing_quote(variable si : stm_text_ptr;
                                                   variable so : inout stm_text_ptr);

    -- str2integer   convert a string to integer number.
    --   inputs  :  string
    --   output  :  int value
    function str2integer(str : in string) return integer;

    --  function short text_line (remove 'nul')
    function text_line_crop(txt : in text_line) return string;

    -- text_line_len    text_line length
    --          inputs :  string of type text_line
    --          return :  integer number of non 'nul' chars
    function text_line_len(s : in text_line) return integer;

    --  procedure to print to the stdout the txt pointer
    procedure txt_print(variable ptr : in stm_text_ptr);

    --  procedure copy text into an existing pointer
    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
                           variable ptr_o : out stm_text_ptr;
                           variable txt_str : in stm_text);

    --  procedure to get string of the txt pointer
    procedure txt_to_string(variable ptr : in stm_text_ptr;
                            variable str : out stm_text);

    function to_str_hex(int : integer) return string;

    function to_str(int : integer) return string;

end package;
