-------------------------------------------------------------------------------
--             Copyright 2007  Ken Campbell
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- $Date: 2008-02-24 01:34:11 $
--
-- $Name: not supported by cvs2svn $
--
-- $Id: tb_pkg_header.vhd,v 1.4 2008-02-24 01:34:11 sckoarn Exp $
--
-- $Source: /home/marcus/revision_ctrl_test/oc_cvs/cvs/vhld_tb/source/tb_pkg_header.vhd,v $
--
-- Description :  The the testbench package header file.
--                Initial GNU release.
--
------------------------------------------------------------------------------
--This file is part of The VHDL Test Bench.
--
--    The VHDL Test Bench is free software; you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation; either version 2 of the License, or
--    (at your option) any later version.
--
--    The VHDL Test Bench is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with The VHDL Test Bench; if not, write to the Free Software
--    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
-------------------------------------------------------------------------------
-- Revision History:
-- $Log: not supported by cvs2svn $
-- Revision 1.3  2007/09/02 04:04:04  sckoarn
-- Update of version 1.2 tb_pkg
-- See documentation for details
--
-- Revision 1.2  2007/08/21 02:43:14  sckoarn
-- Fix package definition to match with body
--
-- Revision 1.1.1.1  2007/04/06 04:06:48  sckoarn
-- Import of the vhld_tb
--
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

use work.tb_pkg_basics.all;

package tb_pkg is

    ---*****************************************************************************
    -- function declaration
    -- function str_len(line: text_line) return text_field;
    function fld_len(s : in text_field) return integer;
    function line_len(s : in text_line) return integer;
    function c2std_vec(c : in character) return std_logic_vector;

    --------------------------------------------------------------------------------
    -- procedure declarations
    --------------------------------------------------------------------------
    -- define_instruction
    --    inputs     file_name  the file to be read from
    --
    --    output     file_line  a line of text from the file
    procedure define_instruction(variable inst_set : inout inst_def_ptr;
                                 constant inst : in string;
                                 constant args : in integer);

    --------------------------------------------------------------------------------
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

    --------------------------------------------------------------------------------
    --  index_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               array
    --               valid  is 1 if valid 0 if not
    procedure index_array(variable var_list : in var_field_ptr;
                          variable index : in integer;
                          variable array_object_ptr : out t_array_object_ptr;
                          variable valid : out integer);

    --------------------------------------------------------------------------------
    --  index_file
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               file record
    --               valid  is 1 if valid 0 if not
    procedure index_file(variable var_list : in var_field_ptr;
                         variable index : in integer;
                         variable file_object : out text_field;
                         variable valid : out integer);

    --------------------------------------------------------------------------------                         
    --  index_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               lines object
    --               valid  is 1 if valid 0 if not
    procedure index_lines(variable var_list : in var_field_ptr;
                         variable index : in integer;
                         variable lines_object_ptr : out t_lines_object_ptr;
                         variable valid : out integer);

    --------------------------------------------------------------------------------
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


    --------------------------------------------------------------------------------
    --  update_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new array
    --               valid  is 1 if valid 0 if not
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable array_object_ptr : in t_array_object_ptr;
                           variable valid : out integer);
                           
    --------------------------------------------------------------------------------
    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid  is 1 if valid 0 if not
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable lines_object_ptr : in t_lines_object_ptr;
                           variable valid : out integer);

    -------------------------------------------------------------------------------
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

    ------------------------------------------------------------------------------
    -- access_inst_sequ
    --   this procedure retreeves an instruction from the sequence of instructions.
    --   based on the line number you pass to it, it returns the instruction with
    --   any variables substituted as integers.
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
                               variable last_ptr : inout stim_line_ptr
                              );

    ------------------------------------------------------------------------
    --  access_variable
    --    accesses a variable.
    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var : in text_field;
                              variable value : out integer;
                              variable valid : out integer);

    ------------------------------------------------------------------------
    -- takes a source string of type string and initializes a field of type
    -- text_field that is primarly used by the open corse test bench.
    procedure init_text_field(variable sourcestr : in string;
                              variable destfield : out text_field);
    ------------------------------------------------------------------------
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
    -------------------------------------------------------------------------
    -- string convertion
    function ew_to_str(int : integer; b : base) return text_field;
    function ew_to_str_len(int : integer; b : base) return text_field;
    function to_str(int : integer) return string;
    function ew_str_cat(s1 : stm_text; s2 : text_field) return stm_text;
    -------------------------------------------------------------------------
    --  procedre print
    --    print to stdout  string
    procedure print(s : in string);
    -------------------------------------------------------------------------
    --  procedure print stim txt
    procedure txt_print(variable ptr : in stm_text_ptr);
    -------------------------------------------------------------------------
    --  procedure copy text into an existing pointer
    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
                           variable ptr_o : out stm_text_ptr;
                           variable txt_str : in stm_text);
    -------------------------------------------------------------------------
    --  procedure print stim txt sub variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable ptr : in stm_text_ptr;
                             constant b : in base);
    -------------------------------------------------------------------------
    -- dump inst_sequ
    --  this procedure dumps to the simulation window the current instruction
    --  sequence.  the whole thing will be dumped, which could be big.
    --   ** intended for testbench development debug**
    --  procedure dump_inst_sequ(variable inst_sequ  :  in  stim_line_ptr);

    -------------------------------------------------------------------------
    --  function short text_line (remove 'nul')
    function txt_shorter(txt : in text_line) return string;

    -------------------------------------------------------------------------
    --  get a rundom intetger number
    procedure getrandint(variable seed1 : inout positive;
                         variable seed2 : inout positive;
                         variable lowestvalue : in integer;
                         variable utmostvalue : in integer;
                         variable randint : out integer);

end tb_pkg;

package body tb_pkg is

    -------------------------------------------------------------------------------
    -- function defs
    -------------------------------------------------------------------------------
    --  is_digit
    function is_digit(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if (c >= '0' and c <= '9') then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end is_digit;

    --------------------------------------
    -- is_space
    function is_space(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if (c = ' ' or c = ht) then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end is_space;

    ------------------------------------------------------------------------------
    --  to_char
    function ew_to_char(int : integer) return character is
        variable c : character;
    begin
        c := nul;
        case int is
            when 0 => c := '0';
            when 1 => c := '1';
            when 2 => c := '2';
            when 3 => c := '3';
            when 4 => c := '4';
            when 5 => c := '5';
            when 6 => c := '6';
            when 7 => c := '7';
            when 8 => c := '8';
            when 9 => c := '9';
            when 10 => c := 'A';
            when 11 => c := 'B';
            when 12 => c := 'C';
            when 13 => c := 'D';
            when 14 => c := 'E';
            when 15 => c := 'F';
            when others =>
                assert (false)
                report lf & "error: ew_to_char was given a non number didgit."
                severity failure;
        end case;

        return c;
    end ew_to_char;

    -------------------------------------------------------------------------------
    --  to_string function  integer
    function to_str(int : integer) return string is
    begin
        return ew_to_str(int, dec);
    end to_str;

    -------------------------------------------------------------------------------
    --  ew_str_cat
    function ew_str_cat(s1 : stm_text;
                        s2 : text_field) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sc : stm_text;
    begin
        sc := s1;
        i := 1;
        while (sc(i) /= nul) loop
            i := i + 1;
        end loop;
        j := 1;
        while (s2(j) /= nul) loop
            sc(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;

        return sc;
    end ew_str_cat;

    -------------------------------------------------------------------------------
    -- fld_len    field length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function fld_len(s : in text_field) return integer is
        variable i : integer := 1;
    begin
        while (s(i) /= nul and i /= max_field_len) loop
            i := i + 1;
        end loop;
        return (i - 1);
    end fld_len;

    -------------------------------------------------------------------------------
    -- line_len    textline length
    --          inputs :  string of type text_field
    --          return :  integer number of non 'nul' chars
    function line_len(s : in text_line) return integer is
        variable i : integer := 1;
    begin
        while (s(i) /= nul and i /= max_str_len) loop
            i := i + 1;
        end loop;
        return (i - 1);
    end line_len;

    -------------------------------------------------------------------------------
    -- fld_equal  check text field for equality
    --          inputs :  text field s1 and s2
    --          return :  true if text fields are equal; false otherwise.
    function fld_equal(s1 : in text_field;
                       s2 : in text_field) return boolean is
        variable i : integer := 0;
        variable s1_length : integer := 0;
        variable s2_length : integer := 0;
    begin
        s1_length := fld_len(s1);
        s2_length := fld_len(s2);

        if (s1_length /= s2_length) then
            return false;
        end if;

        while (i /= s1_length) loop
            i := i + 1;
            if s1(i) /= s2(i) then
                return false;
            end if;
        end loop;
        return true;
    end fld_equal;

    ------------------------------------------------------------------------------
    -- c2int   convert character to integer
    function c2int(c : in character) return integer is
        variable i : integer;
    begin
        i := -1;
        case c is
            when '0' => i := 0;
            when '1' => i := 1;
            when '2' => i := 2;
            when '3' => i := 3;
            when '4' => i := 4;
            when '5' => i := 5;
            when '6' => i := 6;
            when '7' => i := 7;
            when '8' => i := 8;
            when '9' => i := 9;
            when others =>
                assert (false)
                report lf & "error: c2int was given a non number didgit."
                severity failure;
        end case;
        return i;
    end c2int;

    -------------------------------------------------------------------------------
    -- str2integer   convert a string to integer number.
    --   inputs  :  string
    --   output  :  int value
    function str2integer(str : in string) return integer is
        variable l : integer;
        variable j : integer := 1;
        variable rtn : integer := 0;
    begin

        l := fld_len(str);

        for i in l downto 1 loop
            rtn := rtn + (c2int(str(j)) * (10 ** (i - 1)));
            j := j + 1;
        end loop;

        return rtn;
    end str2integer;

    -------------------------------------------------------------------------------
    -- hex2integer    convert hex stimulus field to integer
    --          inputs :  string of type text_field containing only hex numbers
    --          return :  integer value
    function hex2integer(hex_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer is
        variable len : integer;
        variable temp_int : integer;
        variable power : integer;
        variable int_number : integer;
    begin
        len := fld_len(hex_number);
        power := 0;
        temp_int := 0;
        for i in len downto 1 loop
            case hex_number(i) is
                when '0' =>
                    int_number := 0;
                when '1' =>
                    int_number := 1;
                when '2' =>
                    int_number := 2;
                when '3' =>
                    int_number := 3;
                when '4' =>
                    int_number := 4;
                when '5' =>
                    int_number := 5;
                when '6' =>
                    int_number := 6;
                when '7' =>
                    int_number := 7;
                when '8' =>
                    int_number := 8;
                when '9' =>
                    int_number := 9;
                when 'a' | 'A' =>
                    int_number := 10;
                when 'b' | 'B' =>
                    int_number := 11;
                when 'c' | 'C' =>
                    int_number := 12;
                when 'd' | 'D' =>
                    int_number := 13;
                when 'e' | 'E' =>
                    int_number := 14;
                when 'f' | 'F' =>
                    int_number := 15;
                when others =>
                    assert (false)
                    report lf & "error: hex2integer found non hex didgit on line "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (16 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end hex2integer;

    -------------------------------------------------------------------------------
    -- convert character to 4 bit vector
    --   input    character
    --   output   std_logic_vector  4 bits
    function c2std_vec(c : in character) return std_logic_vector is
    begin
        case c is
            when '0' => return "0000";
            when '1' => return "0001";
            when '2' => return "0010";
            when '3' => return "0011";
            when '4' => return "0100";
            when '5' => return "0101";
            when '6' => return "0110";
            when '7' => return "0111";
            when '8' => return "1000";
            when '9' => return "1001";
            when 'a' | 'A' => return "1010";
            when 'b' | 'B' => return "1011";
            when 'c' | 'C' => return "1100";
            when 'd' | 'D' => return "1101";
            when 'e' | 'E' => return "1110";
            when 'f' | 'F' => return "1111";
            when others =>
                assert (false)
                report lf & "error: c2std_vec found non hex didgit on file line "
                severity failure;
                return "XXXX";
        end case;
    end c2std_vec;

    -------------------------------------------------------------------------------
    --  std_vec2c  convert 4 bit std_vector to a character
    --     input  std_logic_vector 4 bits
    --     output  character
    function std_vec2c(vec : in std_logic_vector(3 downto 0)) return character is
    begin
        case vec is
            when "0000" => return '0';
            when "0001" => return '1';
            when "0010" => return '2';
            when "0011" => return '3';
            when "0100" => return '4';
            when "0101" => return '5';
            when "0110" => return '6';
            when "0111" => return '7';
            when "1000" => return '8';
            when "1001" => return '9';
            when "1010" => return 'A';
            when "1011" => return 'B';
            when "1100" => return 'C';
            when "1101" => return 'D';
            when "1110" => return 'E';
            when "1111" => return 'F';
            when others =>
                assert (false)
                report lf & "error: std_vec2c found non-binary didgit in vec "
                severity failure;
                return 'X';
        end case;
    end std_vec2c;

    -------------------------------------------------------------------------------
    -- bin2integer    convert bin stimulus field to integer
    --          inputs :  string of type text_field containing only binary numbers
    --          return :  integer value
    function bin2integer(bin_number : in text_field;
                         file_name : in text_line;
                         line : in integer) return integer is
        variable len : integer;
        variable temp_int : integer;
        variable power : integer;
        variable int_number : integer;
    begin
        len := fld_len(bin_number);
        power := 0;
        temp_int := 0;
        for i in len downto 1 loop
            case bin_number(i) is
                when '0' =>
                    int_number := 0;
                when '1' =>
                    int_number := 1;
                when others =>
                    assert (false)
                    report lf & "error: bin2integer found non binary didgit on line "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;

            temp_int := temp_int + (int_number * (2 ** power));
            power := power + 1;
        end loop;

        return temp_int;
    end bin2integer;

    -------------------------------------------------------------------------------
    -- stim_to_integer    convert stimulus field to integer
    --          inputs :  string of type text_field "stimulus format of number"
    --          return :  integer value
    function stim_to_integer(field : in text_field;
                             file_name : in text_line;
                             line : in integer) return integer is
        variable len : integer;
        variable value : integer := 1;
        variable temp_str : text_field;
    begin
        len := fld_len(field);

        if (field(1) = '#') then
            case field(2) is
                when 'x' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    -- assert(false)
                    -- report lf & "hex2integer: " & temp_str
                    -- severity warning;
                    value := hex2integer(temp_str, file_name, line);
                when 'b' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := bin2integer(temp_str, file_name, line);
                when 'd' =>
                    value := 3;
                    while (field(value) /= nul) loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := str2integer(temp_str);
                when others =>
                    assert (false)
                    report lf & "error: strange # found ! "
                     & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
        else
            value := str2integer(field);
        end if;
        return value;
    end stim_to_integer;

    -------------------------------------------------------------------------------
    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_str(int : integer;
                       b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable i : integer;
        variable j : integer;
        variable vec : std_logic_vector(31 downto 0);
    begin
        num := int;
        temp := (others => nul);
        case b is
            when bin =>
                radix := 2; -- depending on what
                pre := "0b";
            when oct =>
                radix := 8; -- base the number is
                pre := "0o";
            when hex =>
                radix := 16; -- to be displayed as
                pre := "0x";
            when dec =>
                radix := 10; -- choose a radix range
                pre := (others => nul);
        end case;
        -- now jump through hoops because of sign
        if (num < 0 and b = hex) then
            vec := std_logic_vector(to_unsigned(int, 32));
            temp(1) := std_vec2c(vec(31 downto 28));
            temp(2) := std_vec2c(vec(27 downto 24));
            temp(3) := std_vec2c(vec(23 downto 20));
            temp(4) := std_vec2c(vec(19 downto 16));
            temp(5) := std_vec2c(vec(15 downto 12));
            temp(6) := std_vec2c(vec(11 downto 8));
            temp(7) := std_vec2c(vec(7 downto 4));
            temp(8) := std_vec2c(vec(3 downto 0));
        else
            while num >= radix loop -- determine how many
                len := len + 1; -- characters required
                num := num / radix; -- to represent the
            end loop; -- number.
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if (pre(1) /= nul) then
            temp1 := temp;
            i := 1;
            j := 3;
            temp(1 to 2) := pre;
            while (temp1(i) /= nul) loop
                temp(j) := temp1(i);
                i := i + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end ew_to_str;

    -------------------------------------------------------------------------------
    --  to_str function  with base parameter
    --     convert integer to number base
    function ew_to_str_len(int : integer;
                           b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1; -- adjusted min. length to 2 for bytes
        variable pre : string(1 to 2);
        variable i : integer;
        variable j : integer;
        variable vec : std_logic_vector(31 downto 0);
    begin
        num := int;
        temp := (others => nul);
        case b is
            when bin =>
                radix := 2; -- depending on what
                pre := "0b";
            when oct =>
                radix := 8; -- base the number is
                pre := "0o";
            when hex =>
                radix := 16; -- to be displayed as
                pre := "0x";
            when dec =>
                radix := 10; -- choose a radix range
                pre := (others => nul);
        end case;
        -- now jump through hoops because of sign
        if (num < 0 and b = hex) then
            vec := std_logic_vector(to_signed(int, 32));
            temp(1) := std_vec2c(vec(31 downto 28));
            temp(2) := std_vec2c(vec(27 downto 24));
            temp(3) := std_vec2c(vec(23 downto 20));
            temp(4) := std_vec2c(vec(19 downto 16));
            temp(5) := std_vec2c(vec(15 downto 12));
            temp(6) := std_vec2c(vec(11 downto 8));
            temp(7) := std_vec2c(vec(7 downto 4));
            temp(8) := std_vec2c(vec(3 downto 0));
        else
            while num >= radix loop -- determine how many
                len := len + 1; -- characters required
                num := num / radix; -- to represent the
            end loop; -- number.
            if (len mod 2 > 0) then -- is odd number, add one
                len := len + 1;
            end if;
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if (pre(1) /= nul) then
            temp1 := temp;
            i := 1;
            j := 3;
            temp(1 to 2) := pre;
            while (temp1(i) /= nul) loop
                temp(j) := temp1(i);
                i := i + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end ew_to_str_len;

    -------------------------------------------------------------------------
    --  function short text_line (remove 'nul')
    function txt_shorter(txt : in text_line) return string is
        variable l : integer;
    begin
        l := line_len(txt);
        return txt(1 to l);
    end txt_shorter;

    -------------------------------------------------------------------------------
    -- procedure to print instruction records to stdout  *for debug*
    procedure print_inst(variable inst : in stim_line_ptr) is
        variable l : text_line;
        variable l_i : integer := 1;
        variable j : integer := 1;
    begin
        while (inst.instruction(j) /= nul) loop
            l(l_i) := inst.instruction(j);
            j := j + 1;
            l_i := l_i + 1;
        end loop;

        l(l_i) := ' ';
        l_i := l_i + 1;
        j := 1;
        -- field one
        if (inst.inst_field_1(1) /= nul) then
            while (inst.inst_field_1(j) /= nul) loop
                l(l_i) := inst.inst_field_1(j);
                j := j + 1;
                l_i := l_i + 1;
            end loop;
            l(l_i) := ' ';
            l_i := l_i + 1;
            j := 1;
            -- field two
            if (inst.inst_field_2(1) /= nul) then
                while (inst.inst_field_2(j) /= nul) loop
                    l(l_i) := inst.inst_field_2(j);
                    j := j + 1;
                    l_i := l_i + 1;
                end loop;
                l(l_i) := ' ';
                l_i := l_i + 1;
                j := 1;
                -- field three
                if (inst.inst_field_3(1) /= nul) then
                    while (inst.inst_field_3(j) /= nul) loop
                        l(l_i) := inst.inst_field_3(j);
                        j := j + 1;
                        l_i := l_i + 1;
                    end loop;
                    l(l_i) := ' ';
                    l_i := l_i + 1;
                    j := 1;
                    -- field four
                    if (inst.inst_field_4(1) /= nul) then
                        while (inst.inst_field_4(j) /= nul) loop
                            l(l_i) := inst.inst_field_4(j);
                            j := j + 1;
                            l_i := l_i + 1;
                        end loop;
                    end if;
                end if;
            end if;
        end if;
        print(l);
        print("   sequence number: " & to_str(inst.line_number) &
          "  file line number: " & to_str(inst.file_line));
        if (inst.num_of_lines > 0) then
            print("   number of lines: " & to_str(inst.num_of_lines));
        end if;
    end print_inst;

    --------------------------------------------------------------------------------
    --  access_variable
    --     inputs:
    --               text field containing variable
    --     outputs:
    --               value  $var  returns value of var
    --               value  var   returns index of var
    --
    --               valid  is 1 if valid 0 if not
    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var : in text_field;
                              variable value : out integer;
                              variable valid : out integer) is
        variable l : integer;
        variable var_ptr : var_field_ptr;
        variable temp_field : text_field;
        variable ptr : integer := 0; -- 0 is index, 1 is pointer
        variable is_defined : boolean := false;
    begin

        l := fld_len(var);
        valid := 0;
        -- if the variable is a special
        if (var(1) = '=') then
            value := 0;
            valid := 1;
        elsif (var(1 to 2) = ">=") then
            value := 4;
            valid := 1;
        elsif (var(1 to 2) = "<=") then
            value := 5;
            valid := 1;
        elsif (var(1) = '>') then
            value := 1;
            valid := 1;
        elsif (var(1) = '<') then
            value := 2;
            valid := 1;
        elsif (var(1 to 2) = "!=") then
            value := 3;
            valid := 1;
        else
            if (var(1) = '$') then
                ptr := 1; -- this is a pointer
                for i in 2 to l loop
                    temp_field(i - 1) := var(i);
                end loop;
            else
                temp_field := var;
            end if;

            assert (var_list /= null)
            report lf & "error: no variables are defined." & lf
            severity failure;

            var_ptr := var_list;
            while (var_ptr.next_rec /= null) loop
                -- if we have a match
                if (fld_equal(temp_field, var_ptr.var_name)) then
                    if (ptr = 1) then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := var_ptr.var_index;
                        valid := 1;
                        is_defined := true;
                    end if;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;

            -- if we have a match and was the last record
            if (var_ptr.next_rec = null) then
                if (fld_equal(temp_field, var_ptr.var_name)) then
                    if (ptr = 1) then
                        value := var_ptr.var_value;
                        valid := 1;
                        is_defined := true;
                    else
                        value := var_ptr.var_index;
                        valid := 1;
                        is_defined := true;
                    end if;
                end if;
            end if;

            assert (is_defined)
            report lf & "error: variable is not defined " & temp_field & lf
            severity failure;
        end if;
    end access_variable;

    --------------------------------------------------------------------------------
    procedure init_text_field(variable sourcestr : in string;
                              variable destfield : out text_field) is
        variable tempfield : text_field;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;

        for i in 1 to text_field'length loop
            destfield(i) := tempfield(i);
        end loop;
    end init_text_field;

    --------------------------------------------------------------------------------
    --  index_variable
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               variable value
    --               valid  is 1 if valid 0 if not
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable value : out integer;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                value := ptr.var_value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            value := ptr.var_value;
            valid := 1;
        end if;
    end index_variable;

    --------------------------------------------------------------------------------
    --  index_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               array
    --               valid  is 1 if valid 0 if not
    procedure index_array(variable var_list : in var_field_ptr;
                          variable index : in integer;
                          variable array_object_ptr : out t_array_object_ptr;
                          variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                array_object_ptr := ptr.var_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            array_object_ptr := ptr.var_array;
            valid := 1;
        end if;
    end index_array;

    --------------------------------------------------------------------------------
    --  index_file
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               file record
    --               valid  is 1 if valid 0 if not
    procedure index_file(variable var_list : in var_field_ptr;
                         variable index : in integer;
                         variable file_object : out text_field;
                         variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                file_object := ptr.var_file;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            file_object := ptr.var_file;
            valid := 1;
        end if;
    end index_file;
    
    --------------------------------------------------------------------------------
    --  index_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               lines
    --               valid  is 1 if valid 0 if not
    procedure index_lines(variable var_list : in var_field_ptr;
                          variable index : in integer;
                          variable lines_object_ptr : out t_lines_object_ptr;
                          variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index) then
                lines_object_ptr := ptr.var_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if (ptr.var_index = index) then
            lines_object_ptr := ptr.var_lines;
            valid := 1;
        end if;
    end index_array;

    --------------------------------------------------------------------------------
    --  update_variable
    --     inputs:
    --               index:  the index of the variable being updated
    --     outputs:
    --               valid  is 1 if valid 0 if not
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in integer;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index and not ptr.const) then
                ptr.var_value := value;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if (ptr.var_index = index and not ptr.const) then
            ptr.var_value := value;
            valid := 1;
        end if;
    end update_variable;

    --------------------------------------------------------------------------------
    --  update_array
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new array
    --               valid  is 1 if valid 0 if not
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable array_object_ptr : in t_array_object_ptr;
                           variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index and not ptr.const) then
                ptr.var_array := array_object_ptr;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if (ptr.var_index = index and not ptr.const) then
            ptr.var_array := array_object_ptr;
            valid := 1;
        end if;
    end update_array;
    
    --------------------------------------------------------------------------------
    --  update_lines
    --     inputs:
    --               index:  the index of the variable being accessed
    --     outputs:
    --               new lines
    --               valid  is 1 if valid 0 if not
    procedure update_array(variable var_list : in var_field_ptr;
                           variable index : in integer;
                           variable lines_object_ptr : in t_lines_object_ptr;
                           variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while (ptr.next_rec /= null) loop
            if (ptr.var_index = index and not ptr.const) then
                ptr.var_Lines := lines_object_ptr;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if (ptr.var_index = index and not ptr.const) then
            ptr.var_lines := lines_object_ptr;
            valid := 1;
        end if;
    end update_lines;

    -------------------------------------------------------------------------------
    -- read a line from a file
    --   inputs  :   file of type text
    --   outputs :   the line of type text_line
    procedure file_read_line(file file_name : text;
                             variable file_line : out text_line
                            ) is
        variable index : integer; -- index into string
        variable rline : line;

    begin

        index := 1; -- set index to begin of string
        file_line := (others => nul);
        if (not endfile(file_name)) then
            readline(file_name, rline);

            while (rline'right /= (index - 1) and rline'length /= 0) loop
                file_line(index) := rline(index);
                index := index + 1;
            end loop;
        end if;
    end file_read_line;

    ------------------------------------------------------------------------------
    -- procedure to break a line down in to text fields
    procedure tokenize_line(variable text_line : in text_line;
                            variable otoken1 : out text_field;
                            variable otoken2 : out text_field;
                            variable otoken3 : out text_field;
                            variable otoken4 : out text_field;
                            variable otoken5 : out text_field;
                            variable otoken6 : out text_field;
                            variable otoken7 : out text_field;
                            variable txt_ptr : out stm_text_ptr;
                            variable ovalid : out integer) is
        variable token_index : integer := 0;
        variable current_token : text_field;
        variable token_number : integer := 0;
        variable c : string(1 to 2);
        variable comment_found : integer := 0;
        variable txt_found : integer := 0;
        variable j : integer;
        variable txt_ptr_tmp : stm_text_ptr;
        variable txt_str : stm_text;
        variable token1 : text_field;
        variable token2 : text_field;
        variable token3 : text_field;
        variable token4 : text_field;
        variable token5 : text_field;
        variable token6 : text_field;
        variable token7 : text_field;
        variable token8 : text_field;
        variable valid : integer := 0;
        variable token_merge : boolean;
        variable token1_len : integer;
        variable token2_len : integer;
    begin
        -- null outputs
        token1 := (others => nul);
        token2 := (others => nul);
        token3 := (others => nul);
        token4 := (others => nul);
        token5 := (others => nul);
        token6 := (others => nul);
        token7 := (others => nul);
        token8 := (others => nul);
        txt_ptr := null;
        txt_ptr_tmp := null;
        valid := 0;
        txt_found := 0;
        j := 1;
        txt_str := (others => nul);
        token_merge := false;

        -- loop for max number of char
        for i in 1 to text_line'high loop
            -- collect for comment test ** assumed no line will be max 256
            c(1) := text_line(i);
            c(2) := text_line(i + 1); -- or this line will blow up
            if (c = "--") then
                comment_found := 1;
                exit;
            end if;
            -- if is begin text char '"'
            if (txt_found = 0 and c(1) = '"') --"  <-- this double quote is just to fix highlighting.
                then
                txt_found := 1;
                txt_ptr_tmp := new stm_text;
                next;
            end if;

            -- if we have found a txt string
            if (txt_found = 1 and text_line(i) /= nul) then
                -- if string too long, prevent tool hang, truncate and notify
                if (j > c_stm_text_len) then
                    print("tokenize_line: truncated txt line, it was larger than c_stm_text_len");
                    exit;
                end if;

                if (text_line(i) /= '"') then
                    txt_str(j) := text_line(i);
                    txt_ptr_copy(txt_ptr_tmp, txt_ptr, txt_str);
                    j := j + 1;
                else
                    exit;
                end if;

            -- if is a character store in the right token
            elsif (is_space(text_line(i)) = false and text_line(i) /= nul) then
                token_index := token_index + 1;
                current_token(token_index) := text_line(i);
            -- else is a space, deal with pointers
            elsif (is_space(text_line(i + 1)) = false and text_line(i + 1) /= nul) then
                case token_number is
                    when 0 =>
                        if (token_index /= 0) then
                            token1 := current_token;
                            current_token := (others => nul);
                            token_number := 1;
                            valid := 1;
                            token_index := 0;
                        end if;
                    when 1 =>
                        token2 := current_token;
                        current_token := (others => nul);
                        token_number := 2;
                        valid := 2;
                        token_index := 0;
                    when 2 =>
                        token3 := current_token;
                        current_token := (others => nul);
                        token_number := 3;
                        valid := 3;
                        token_index := 0;
                    when 3 =>
                        token4 := current_token;
                        current_token := (others => nul);
                        token_number := 4;
                        valid := 4;
                        token_index := 0;
                    when 4 =>
                        token5 := current_token;
                        current_token := (others => nul);
                        token_number := 5;
                        valid := 5;
                        token_index := 0;
                    when 5 =>
                        token6 := current_token;
                        current_token := (others => nul);
                        token_number := 6;
                        valid := 6;
                        token_index := 0;
                    when 6 =>
                        token7 := current_token;
                        current_token := (others => nul);
                        token_number := 7;
                        valid := 7;
                        token_index := 0;
                    when 7 =>
                        token8 := current_token;
                        current_token := (others => nul);
                        token_number := 8;
                        valid := 8;
                        token_index := 0;
                    when 8 =>
                    when others =>
                        null;
                end case;
            end if;
            -- break from loop if is null
            if (text_line(i) = nul) then
                if (token_index /= 0) then
                    case token_number is
                        when 0 =>
                            token1 := current_token;
                            valid := 1;
                        when 1 =>
                            token2 := current_token;
                            valid := 2;
                        when 2 =>
                            token3 := current_token;
                            valid := 3;
                        when 3 =>
                            token4 := current_token;
                            valid := 4;
                        when 4 =>
                            token5 := current_token;
                            valid := 5;
                        when 5 =>
                            token6 := current_token;
                            valid := 6;
                        when 6 =>
                            token7 := current_token;
                            valid := 7;
                        when 7 =>
                            token8 := current_token;
                            valid := 8;
                        when others =>
                            null;
                    end case;
                end if;
                exit;
            end if;
        end loop;
        -- did we find a comment and there is a token
        if (comment_found = 1) then
            if (token_index /= 0) then
                case token_number is
                    when 0 =>
                        token1 := current_token;
                        valid := 1;
                    when 1 =>
                        token2 := current_token;
                        valid := 2;
                    when 2 =>
                        token3 := current_token;
                        valid := 3;
                    when 3 =>
                        token4 := current_token;
                        valid := 4;
                    when 4 =>
                        token5 := current_token;
                        valid := 5;
                    when 5 =>
                        token6 := current_token;
                        valid := 6;
                    when 6 =>
                        token7 := current_token;
                        valid := 7;
                    when 7 =>
                        token8 := current_token;
                        valid := 8;
                    when others =>
                        null;
                end case;
            end if;
        end if;
        if valid > 1 then
            if token1(1 to 3) = "end" then
                token1_len := 3;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := true;
                elsif token2(1 to 4) = "loop" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 4) = "proc" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 9) = "interrupt" then
                    token2_len := 9;
                    token_merge := true;
                end if;
            elsif token1(1 to 4) = "file" then
                token1_len := 4;
                if token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                elsif token2(1 to 6) = "append" then
                    token2_len := 6;
                    token_merge := true;
                end if;
            elsif token1(1 to 5) = "lines" then
                token1_len := 5;
                if token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 6) = "delete" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 6) = "insert" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            elsif token1(1 to 5) = "array" then
                token1_len := 5;
                if token2(1 to 3) = "set" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 3) = "get" then
                    token2_len := 3;
                    token_merge := true;
                elsif token2(1 to 4) = "size" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 7) = "pointer" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            elsif token1(1 to 4) = "else" then
                token1_len := 4;
                if token2(1 to 2) = "if" then
                    token2_len := 2;
                    token_merge := true;
                end if;
            elsif token1(1 to 6) = "signal" then
                token1_len := 6;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                end if;
            elsif token1(1 to 3) = "bus" then
                token1_len := 3;
                if token2(1 to 6) = "verify" then
                    token2_len := 6;
                    token_merge := true;
                elsif token2(1 to 4) = "read" then
                    token2_len := 4;
                    token_merge := true;
                elsif token2(1 to 5) = "write" then
                    token2_len := 5;
                    token_merge := true;
                elsif token2(1 to 7) = "timeout" then
                    token2_len := 7;
                    token_merge := true;
                end if;
            end if;
        end if;
        if token_merge then
            token1(token1_len + 2 to token1_len + token2_len + 1) := token2(1 to token2_len);
            token1(token1_len + 1) := '_';

            otoken1 := token1;
            otoken2 := token3;
            otoken3 := token4;
            otoken4 := token5;
            otoken5 := token6;
            otoken6 := token7;
            otoken7 := token8;
            ovalid := valid - 1;
        else
            otoken1 := token1;
            otoken2 := token2;
            otoken3 := token3;
            otoken4 := token4;
            otoken5 := token5;
            otoken6 := token6;
            otoken7 := token7;
            ovalid := valid;
        end if;
    end tokenize_line;

    --------------------------------------------------------------------------------
    -- add a new instruction to the instruction list
    --   inputs  :   the linked list of instructions
    --               the instruction
    --               the number of args
    --   outputs :   updated instruction set linked list
    procedure define_instruction(variable inst_set : inout inst_def_ptr;
                                 constant inst : in string;
                                 constant args : in integer) is
        variable v_inst_ptr : inst_def_ptr;
        variable v_prev_ptr : inst_def_ptr;
        variable v_new_ptr : inst_def_ptr;
        variable v_temp_inst : inst_def_ptr;
        variable v_list_size : integer;
        variable v_dup_error : boolean;
    begin
        assert (inst'high <= max_field_len)
        report lf & "error: creation of instruction of length greater than max_field_len attemped!!" &
             lf & "this max is currently set to " & (integer'image(max_field_len))
        severity failure;
        -- get to the last element and test is not exsiting
        v_temp_inst := inst_set;
        v_inst_ptr := inst_set;
        -- zero the size
        v_list_size := 0;
        while (v_inst_ptr /= null) loop
            -- if there is a chance of a duplicate command
            if (v_inst_ptr.instruction_l = inst'high) then
                v_dup_error := true;
                for i in 1 to inst'high loop
                    if (v_inst_ptr.instruction(i) /= inst(i)) then
                        v_dup_error := false;
                    end if;
                end loop;
                -- if we find a duplicate, die
                assert (v_dup_error = false)
                report lf & "error: duplicate instruction definition attempted!"
                severity failure;
            end if;
            v_prev_ptr := v_inst_ptr; -- store for pointer updates
            v_inst_ptr := v_inst_ptr.next_rec;
            v_list_size := v_list_size + 1;
        end loop;

        -- add the new instruction
        v_new_ptr := new inst_def;
        -- if this is the first command return new pointer
        if (v_list_size = 0) then
            v_temp_inst := v_new_ptr;
        -- else write new pointer to next_rec
        else
            v_prev_ptr.next_rec := v_new_ptr;
        end if;
        v_new_ptr.instruction_l := inst'high;
        v_new_ptr.params := args;
        -- copy the instruction text into field
        for i in 1 to v_new_ptr.instruction_l loop
            v_new_ptr.instruction(i) := inst(i);
        end loop;
        -- return the pointer
        inst_set := v_temp_inst;
    end define_instruction;

    --------------------------------------------------------------------------------
    --  check for valid instruction in the list of instructions
    procedure check_valid_inst(variable inst : in text_field;
                               variable inst_set : in inst_def_ptr;
                               variable token_num : in integer;
                               variable line_num : in integer;
                               variable name : in text_line) is
        variable l : integer := 0;
        variable seti : inst_def_ptr;
        variable match : integer := 0;
        variable ilv : integer := 0; -- inline variable
    begin
        -- create useable pointer
        seti := inst_set;
        -- count up the characters in inst
        l := fld_len(inst);
        -- if this is a referance variable -- handle in add variable proc
        if (inst(l) = ':') then
            match := 1;
            ilv := 1;
        else
            -- process list till null next
            while (seti.next_rec /= null) loop
                if (seti.instruction_l = l) then
                    match := 1;
                    for j in 1 to l loop
                        if (seti.instruction(j) /= inst(j)) then
                            match := 0;
                        end if;
                    end loop;
                end if;
                if (match = 0) then
                    seti := seti.next_rec;
                else
                    exit;
                end if;
            end loop;
            -- check current one
            if (seti.instruction_l = l and match = 0) then
                match := 1;
                for j in 1 to l loop
                    if (seti.instruction(j) /= inst(j)) then
                        match := 0;
                    end if;
                end loop;
            end if;
        end if;

        -- if we had a match, check the number of paramiters
        if (match = 1 and ilv = 0) then
            assert (seti.params = (token_num - 1))
            report lf & "error: undefined instruction was found, incorrect number of fields passed!" & lf &
                    "this is found on line " & (integer'image(line_num)) & " in file " & name & lf
            severity failure;
        end if;

        -- if we find a duplicate, die
        assert (match = 1)
        report lf & "error: undefined instruction on line " & (integer'image(line_num)) &
                  " found in input file " & name & lf
        severity failure;
    end check_valid_inst;

    --------------------------------------------------------------------------------
    --  add_variable
    --    this procedure adds a variable to the variable list.  this is localy
    --    available at this time.
    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable token_num : in integer;
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_type : in integer -- 0:Variable, 1:Constant, 2:Array, 3:File, 4:Lines
                          ) is
        variable temp_var : var_field_ptr;
        variable current_ptr : var_field_ptr;
        variable index : integer := 1;
        variable len : integer := 0;
    begin
        -- if this is not the first one
        if (var_list /= null) then
            current_ptr := var_list;
            index := index + 1;
            
            if (var_type = 4) then -- lines
                while (current_ptr.next_rec /= null) loop
                    -- if we have defined the current before then die
                    assert (current_ptr.var_name /= p1)
                    report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                    severity failure;

                    current_ptr := current_ptr.next_rec;
                    index := index + 1;
                end loop;
                -- if we have defined the current before then die. this checks the last one
                assert (current_ptr.var_name /= p1)
                report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                severity failure;

                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := null;
                temp_var.var_file := null;
                temp_var.var_lines := new t_lines_object;
                temp_var.var_lines.lines := null;
                current_ptr.next_rec := temp_var;

            elsif (var_type = 3) then -- file
                while (current_ptr.next_rec /= null) loop
                    -- if we have defined the current before then die
                    assert (current_ptr.var_name /= p1)
                    report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                    severity failure;

                    current_ptr := current_ptr.next_rec;
                    index := index + 1;
                end loop;
                -- if we have defined the current before then die. this checks the last one
                assert (current_ptr.var_name /= p1)
                report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                severity failure;

                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := null;
                temp_var.var_file := p2;
                temp_var.var_lines := null;
                current_ptr.next_rec := temp_var;

            elsif (var_type = 2) then -- array
                while (current_ptr.next_rec /= null) loop
                    -- if we have defined the current before then die
                    assert (current_ptr.var_name /= p1)
                    report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                    severity failure;

                    current_ptr := current_ptr.next_rec;
                    index := index + 1;
                end loop;
                -- if we have defined the current before then die. this checks the last one
                assert (current_ptr.var_name /= p1)
                report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                severity failure;

                assert (stim_to_integer(p2, name, line_num) > 0)
                report lf & "error: array size <= 0 are not allowd. See "
                  & " on line " & (integer'image(line_num)) & " of file " & name
                severity failure;

                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := new t_array_object(0 to stim_to_integer(p2, name, line_num)-1);
                temp_var.var_file := null;
                temp_var.var_lines := null;

                current_ptr.next_rec := temp_var;

            elsif (p1(length) /= ':') then -- is not an inline variable
                while (current_ptr.next_rec /= null) loop
                    -- if we have defined the current before then die
                    assert (current_ptr.var_name /= p1)
                    report lf & "error: attemping to add a duplicate variable definition "
                      & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                    severity failure;

                    current_ptr := current_ptr.next_rec;
                    index := index + 1;
                end loop;
                -- if we have defined the current before then die. this checks the last one
                assert (current_ptr.var_name /= p1)
                report lf & "error: attemping to add a duplicate variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & txt_shorter(name)
                severity failure;

                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := stim_to_integer(p2, name, line_num); -- convert text_field to integer
                temp_var.var_index := index;
                temp_var.const := (var_type = 1);
                temp_var.var_array := null;
                temp_var.var_file := null;
                temp_var.var_lines := null;
                current_ptr.next_rec := temp_var;


            else -- this is an inline variable
                while (current_ptr.next_rec /= null) loop
                    -- if we have defined the current before then die
                    len := fld_len(current_ptr.var_name);
                    assert (current_ptr.var_name(1 to len) /= p1(1 to (length - 1)))
                    report lf & "error: attemping to add a duplicate inline variable definition "
                      & " on line " & (integer'image(line_num)) & " of file " & name
                    severity failure;

                    current_ptr := current_ptr.next_rec;
                    index := index + 1;
                end loop;
                -- if we have defined the current before then die. this checks the last one
                len := fld_len(current_ptr.var_name);
                assert (current_ptr.var_name(1 to len) /= p1(1 to (length - 1)))
                report lf & "error: attemping to add a duplicate inline variable definition "
                    & " on line " & (integer'image(line_num)) & " of file " & name
                severity failure;

                temp_var := new var_field;
                temp_var.var_name(1 to (length - 1)) := p1(1 to (length - 1));
                temp_var.var_value := sequ_num;
                temp_var.var_index := index;
                temp_var.const := (var_type = 1);
                temp_var.var_array := null;
                temp_var.var_file := null;
                temp_var.var_lines := null;
                current_ptr.next_rec := temp_var;
            end if;
        -- this is the first one
        else

            if (var_type = 4) then -- lines
                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := null;
                temp_var.var_file := null;
                temp_var.var_lines := new t_lines_object;
                temp_var.var_lines.lines := null;
                temp_var.var_lines.size := 0;
                var_list := temp_var;
                
            elsif (var_type = 3) then -- file
                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := null;
                temp_var.var_file := p2;
                temp_var.var_file.name := p2;
                temp_var.var_file.pos := 0;
                temp_var.var_lines := null;
                var_list := temp_var;

            elsif (var_type = 2) then -- array
                assert (stim_to_integer(p2, name, line_num) > 0)
                report lf & "error: array size <= 0 are not allowd. See "
                  & " on line " & (integer'image(line_num)) & " of file " & name
                severity failure;

                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_value := 0;
                temp_var.var_index := index;
                temp_var.const := false;
                temp_var.var_array := new t_array_object(0 to stim_to_integer(p2, name, line_num)-1);
                temp_var.var_file := null;
                temp_var.var_lines := null;
                var_list := temp_var;

            elsif (p1(length) /= ':') then -- is not an inline variable
                temp_var := new var_field;
                temp_var.var_name := p1; -- direct write of text_field
                temp_var.var_index := index;
                temp_var.const := (var_type = 1);
                temp_var.var_array := null;
                temp_var.var_value := stim_to_integer(p2, name, line_num); -- convert text_field to integer
                temp_var.var_file := null;
                temp_var.var_lines := null;
                var_list := temp_var;

            else
                temp_var := new var_field;
                temp_var.var_name(1 to (length - 1)) := p1(1 to (length - 1));
                temp_var.var_value := sequ_num;
                temp_var.var_index := index;
                temp_var.const := (var_type = 1);
                temp_var.var_array := null;
                temp_var.var_file := null;
                temp_var.var_lines := null;
                var_list := temp_var;
            end if;
        end if;
    end add_variable;

    --------------------------------------------------------------------------------
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
                              variable token_num : in integer;
                              variable sequ_num : inout integer;
                              variable line_num : in integer;
                              variable file_name : in text_line;
                              variable file_idx : in integer) is
        variable temp_stim_line : stim_line_ptr;
        variable temp_current : stim_line_ptr;
        variable valid : integer;
        variable l : integer;
    begin
        valid := 1;
        l := fld_len(inst);
        temp_current := inst_list;
        -- take care of special cases
        if (inst(1 to l) = "var") then
            l := fld_len(p1);
            --  add the variable to the variable pool, not considered an instruction
            add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, 0);
            valid := 0; --removes this from the instruction list

        elsif (inst(1 to l) = "const") then
            l := fld_len(p1);
            --  add the variable to the variable pool, not considered an instruction
            add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, 1);
            valid := 0; --removes this from the instruction list

        elsif (inst(1 to l) = "array") then
            l := fld_len(p1);
            --  add the variable to the array pool, not considered an instruction
            add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, 2);
            valid := 0; --removes this from the instruction list

        elsif (inst(1 to l) = "file") then
            l := fld_len(p1);
            --  add the variable to the file pool, not considered an instruction
            add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, 3);
            valid := 0; --removes this from the instruction list
            
        elsif (inst(1 to l) = "lines") then
            l := fld_len(p1);
            --  add the variable to the lines pool, not considered an instruction
            add_variable(var_list, p1, p2, token_num, sequ_num, line_num, file_name, l, 4);
            valid := 0; --removes this from the instruction list

        elsif (inst(l) = ':') then
            add_variable(var_list, inst, p1, token_num, sequ_num, line_num, file_name, l, 0);
            valid := 0;

        end if;

        if (valid = 1) then
            -- prepare the new record
            temp_stim_line := new stim_line;
            temp_stim_line.instruction := inst;
            temp_stim_line.inst_field_1 := p1;
            temp_stim_line.inst_field_2 := p2;
            temp_stim_line.inst_field_3 := p3;
            temp_stim_line.inst_field_4 := p4;
            temp_stim_line.inst_field_5 := p5;
            temp_stim_line.inst_field_6 := p6;
            temp_stim_line.txt := str_ptr;
            temp_stim_line.line_number := sequ_num;
            temp_stim_line.file_idx := file_idx;
            temp_stim_line.file_line := line_num;

            -- if is not the first instruction
            if (inst_list /= null) then
                while (temp_current.next_rec /= null) loop
                    temp_current := temp_current.next_rec;
                end loop;
                temp_current.next_rec := temp_stim_line;
                inst_list.num_of_lines := inst_list.num_of_lines + 1;
            -- other wise is first instruction to be added
            else
                inst_list := temp_stim_line;
                inst_list.num_of_lines := 1;
            end if;
            sequ_num := sequ_num + 1;
            -- print_inst(temp_stim_line);  -- for debug
        end if;

    end add_instruction;

    ------------------------------------------------------------------------------
    -- test_inst_sequ
    --  this procedure accesses the full instruction sequence and checks for valid
    --   variables.  this is prior to the simulation run start.
    procedure test_inst_sequ(variable inst_sequ : in stim_line_ptr;
                             variable file_list : in file_def_ptr;
                             variable var_list : in var_field_ptr) is
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable v_p : integer;
        variable inst : text_field;
        variable txt : stm_text_ptr;
        variable inst_len : integer;
        variable fname : text_line;
        variable file_line : integer;
        variable temp_fn_prt : file_def_ptr;
        variable tmp_int : integer;
        -- variable value:     integer := 1;
        -- variable temp_str : string(1 to 48);
    begin
        inst_ptr := inst_sequ;
        -- go through all the instructions
        while (inst_ptr.next_rec /= null) loop
            inst := inst_ptr.instruction;
            inst_len := fld_len(inst_ptr.instruction);
            file_line := inst_ptr.file_line;
            line := inst_ptr.file_line;
            -- recover the file name this line came from
            temp_fn_prt := file_list;
            tmp_int := inst_ptr.file_idx;
            while (temp_fn_prt.next_rec /= null) loop
                if (temp_fn_prt.rec_idx = tmp_int) then
                    exit;
                end if;
                temp_fn_prt := temp_fn_prt.next_rec;
            end loop;
            for i in 1 to fname'high loop
                file_name(i) := temp_fn_prt.file_name(i);
            end loop;

            txt := inst_ptr.txt;
            -- load parameter one
            temp_text_field := inst_ptr.inst_field_1;

            if (temp_text_field(1) /= nul) then
                -- if this is a numaric  do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: first variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter two
            temp_text_field := inst_ptr.inst_field_2;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: second variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter three
            temp_text_field := inst_ptr.inst_field_3;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: third variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter four
            temp_text_field := inst_ptr.inst_field_4;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: forth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter five
            temp_text_field := inst_ptr.inst_field_5;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric do nothing
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: fifth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- load parameter six
            temp_text_field := inst_ptr.inst_field_6;
            if (temp_text_field(1) /= nul) then
                -- if this is a numaric field convert to integer
                if ((temp_text_field(1) = '#' and (temp_text_field(2) = 'x' or temp_text_field(2) = 'b'))
                    or is_digit(temp_text_field(1)) = true) then
                    null;
                else -- else is a variable, get the value or halt incase of error
                    access_variable(var_list, temp_text_field, v_p, valid);
                    assert (valid = 1)
                    report lf & "error: sixth variable on stimulus line " & (integer'image(line))
                      & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            -- point to next record
            inst_ptr := inst_ptr.next_rec;
        end loop;
    end test_inst_sequ;

    --------------------------------------------------------------------------------
    --  the read include file procedure
    --    this is the main procedure for reading, parcing, checking and returning
    --    the instruction sequence link list.
    procedure read_include_file(variable name : text_line;
                                variable sequ_numb : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_sequ : inout stim_line_ptr;
                                variable status : inout integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable valid : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable idx : integer;
        variable v_tmp : text_line;

        variable v_tmp_fn_ptr : file_def_ptr;
        variable v_new_fn : integer;
        variable v_tmp_fn : file_def_ptr;

    begin
        sequ_line := sequ_numb;
        v_tmp_fn_ptr := file_list;
        -- for linux systems, trailing spaces need to be removed
        --    from file names
        --  copy text string to temp
        for i in 1 to c_stm_text_len loop
            if (name(i) = nul) then
                v_tmp(i) := name(i);
                exit;
            else
                v_tmp(i) := name(i);
            end if;
        end loop;
        --fix up any trailing white space in txt
        idx := 0;
        --    get to the end of the string
        for i in 1 to c_stm_text_len loop
            if (v_tmp(i) /= nul) then
                idx := idx + 1;
            else
                exit;
            end if;
        end loop;
        --  now nul out spaces
        for i in idx downto 1 loop
            if (is_space(v_tmp(i)) = true) then
                v_tmp(i) := nul;
            else
                exit;
            end if;
        end loop;
        --  open include file
        file_open(v_stat, include_file, v_tmp, read_mode);
        if (v_stat /= open_ok) then
            print("error: unable to open include file  " & name);
            status := 1;
            return;
        end if;
        l_num := 1; -- initialize line number

        --  the file is opened, put it on the file name ll
        while (v_tmp_fn_ptr.next_rec /= null) loop
            v_tmp_fn_ptr := v_tmp_fn_ptr.next_rec;
        end loop;
        v_new_fn := v_tmp_fn_ptr.rec_idx + 1;
        v_tmp_fn := new file_def;
        v_tmp_fn_ptr.next_rec := v_tmp_fn;
        v_tmp_fn.rec_idx := v_new_fn;

        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to name'high loop
            v_tmp_fn.file_name(i) := name(i);
        end loop;
        v_tmp_fn.next_rec := null;


        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;

        -- while not the end of file read it
        while (not endfile(include_file)) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, valid);
            v_len := fld_len(t1);
            if (t1(1 to v_len) = "include") then
                print("nested include statement found in " & v_tmp & " on line " &
              (integer'image(l_num)));
                assert (false)
                report lf & "error: nested include statements are not supported at this time."
                severity failure;

            -- if there was valid tokens
            elsif (valid /= 0) then
                check_valid_inst(t1, v_inst_ptr, valid, l_num, name);
                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7, t_txt, valid,
                                sequ_line, l_num, name, v_new_fn);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(include_file);
        sequ_numb := sequ_line;
        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
    end read_include_file;

    --------------------------------------------------------------------------------
    --  the read instruction file procedure
    --    this is the main procedure for reading, parcing, checking and returning
    --    the instruction sequence link list.
    procedure read_instruction_file(constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_sequ : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_inst_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;
        variable v_idx : integer;
        variable path_v_iname : text_line;
    begin
        -- open the stimulus_file and check
        file_open(v_stat, stimulus, path_name & file_name, read_mode);
        assert (v_stat = open_ok)
        report lf & "error: unable to open stimulus_file  " & path_name & file_name
        severity failure;
        -- copy file name to type text_line
        for i in 1 to path_name'high loop
            v_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_name(i + path_name'high) := file_name(i);
        end loop;
        -- the first item on the file names link list
        file_list := null;
        v_tmp_fn := new file_def;
        v_tmp_fn.rec_idx := 1;
        v_fn_idx := 1;
        v_idx := 1;
        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to path_name'high loop
            v_tmp_fn.file_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_tmp_fn.file_name(i + path_name'high) := file_name(i);
        end loop;
        v_tmp_fn.next_rec := null;

        l_num := 1;
        sequ_line := 1;
        v_ostat := 0;

        v_inst_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;

        -- while not the end of file read it
        while (not endfile(stimulus)) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, valid);

            v_len := fld_len(t1);
            -- if there is an include instruction
            if (t1(1 to v_len) = "include") then
                -- if file name is in par2
                if (valid = 2) then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
                    end loop;
                -- elsif the text string is not null
                elsif (t_txt /= null) then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if (t_txt(i) = nul) then
                            exit;
                        end if;
                    end loop;
                else
                    assert (false)
                    report lf & "error:  include instruction has not file name included.  found on" & lf &
                        "line " & (integer'image(l_num)) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                -- copy include file name to type text_line
                for i in 1 to path_name'high loop

                    path_v_iname(i) := path_name(i);

                end loop;
                for i in 1 to max_str_len - path_name'high loop
                    path_v_iname(i + path_name'high) := v_iname(i);
                end loop;
                print("include found: loading file " & path_v_iname);
                read_include_file(path_v_iname, sequ_line, v_tmp_fn, v_inst_ptr, v_var_prt, v_sequ_ptr, v_ostat);
                -- if include file not found
                if (v_ostat = 1) then
                    exit;
                end if;
            -- if there was valid tokens
            elsif (valid /= 0) then
                -- assert(false)
                -- report lf & "before check_valid_inst: "
                -- severity warning;
                check_valid_inst(t1, v_inst_ptr, valid, l_num, v_name);
                -- assert(false)
                -- report lf & "after check_valid_inst: "
                -- severity warning;

                add_instruction(v_sequ_ptr, v_var_prt, t1, t2, t3, t4, t5, t6, t7, t_txt, valid,
                                sequ_line, l_num, v_name, v_fn_idx);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file

        file_close(stimulus); -- close the file when done

        assert (v_ostat = 0)
        report lf & "include file specified on line " & (integer'image(l_num)) &
                  " in file " & path_name & file_name &
                  " was not found! test terminated" & lf
        severity failure;

        inst_set := v_inst_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
        file_list := v_tmp_fn;

        --  now that all the stimulus is loaded, test for invalid variables
        test_inst_sequ(inst_sequ, v_tmp_fn, var_list);
    end read_instruction_file;

    ------------------------------------------------------------------------------
    -- access_inst_sequ
    --  this procedure accesses the instruction sequence and returns the parameters
    --  as they exsist related to the variables state.
    --  inputs:   inst_sequ  link list of instructions from stimulus
    --            var_list   link list of variables
    --            file_list  link list of file names
    --            sequ_num   the sequence number to recover
    --
    --  outputs:  inst  instruction text
    --            p1    paramiter 1 in integer form
    --            p2    paramiter 2 in integer form
    --            p3    paramiter 3 in integer form
    --            p4    paramiter 4 in integer form
    --            p5    paramiter 5 in integer form
    --            p6    paramiter 6 in integer form
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
                               variable last_ptr : inout stim_line_ptr) is
        variable temp_text_field : text_field;
        variable inst_ptr : stim_line_ptr;
        variable valid : integer;
        variable line : integer; -- value of the file_line
        variable file_name : text_line;
        variable tmp_int : integer;
        variable temp_fn_prt : file_def_ptr;
    begin
        -- get to the instruction indicated by sequ_num
        -- check to see if this sequence is before the last
        --    so search from start
        if (last_num > sequ_num) then
            inst_ptr := inst_sequ;
            while (inst_ptr.next_rec /= null) loop
                if (inst_ptr.line_number = sequ_num) then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            inst_ptr := last_ptr;
            while (inst_ptr.next_rec /= null) loop
                if (inst_ptr.line_number = sequ_num) then
                    exit;
                else
                    inst_ptr := inst_ptr.next_rec;
                end if;
            end loop;
        end if;

        -- update the last sequence number and record pointer
        last_num := sequ_num;
        last_ptr := inst_ptr;

        -- output the instruction and its length
        inst := inst_ptr.instruction;
        inst_len := fld_len(inst_ptr.instruction);
        file_line := inst_ptr.file_line;
        line := inst_ptr.file_line;
        -- recover the file name this line came from
        temp_fn_prt := file_list;
        tmp_int := inst_ptr.file_idx;
        while (temp_fn_prt.next_rec /= null) loop
            if (temp_fn_prt.rec_idx = tmp_int) then
                exit;
            end if;
            temp_fn_prt := temp_fn_prt.next_rec;
        end loop;
        for i in 1 to fname'high loop
            file_name(i) := temp_fn_prt.file_name(i);
            fname(i) := temp_fn_prt.file_name(i);
        end loop;

        --  print ("access_inst_sequ" & file_name);

        txt := inst_ptr.txt;
        -- load parameter one
        temp_text_field := inst_ptr.inst_field_1;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p1 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p1 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p1, valid);
                assert (valid = 1)
                report lf & "error: first variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter two
        temp_text_field := inst_ptr.inst_field_2;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p2 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p2 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p2, valid);
                assert (valid = 1)
                report lf & "error: second variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter three
        temp_text_field := inst_ptr.inst_field_3;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p3 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p3 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p3, valid);
                assert (valid = 1)
                report lf & "error: third variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter four
        temp_text_field := inst_ptr.inst_field_4;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p4 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p4 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p4, valid);
                assert (valid = 1)
                report lf & "error: forth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter five
        temp_text_field := inst_ptr.inst_field_5;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p5 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p5 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p5, valid);
                assert (valid = 1)
                report lf & "error: fifth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        -- load parameter six
        temp_text_field := inst_ptr.inst_field_6;
        if (temp_text_field(1) /= nul) then
            -- if this is a numaric field convert to integer
            if (temp_text_field(1) = '#') then
                p6 := stim_to_integer(temp_text_field, file_name, line);
            elsif (is_digit(temp_text_field(1)) = true) then
                p6 := stim_to_integer(temp_text_field, file_name, line);
            else -- else is a variable, get the value or halt incase of error
                access_variable(var_list, temp_text_field, p6, valid);
                assert (valid = 1)
                report lf & "error: sixth variable on stimulus line " & (integer'image(line))
                    & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
    end access_inst_sequ;

    -------------------------------------------------------------------------------
    -- procedure to print loggings to stdout
    procedure print(s : in string) is
        variable l : line;
    begin
        for i in 1 to s'length loop
            if (s(i) /= nul) then
                write(l, s(i));
            end if;
        end loop;
        writeline(output, l);
    end print;

    -------------------------------------------------------------------------------
    --  procedure to print to the stdout the txt pointer
    procedure txt_print(variable ptr : in stm_text_ptr) is
        variable txt_str : stm_text;
    begin

        if (ptr /= null) then
            txt_str := (others => nul);
            for i in 1 to c_stm_text_len loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                txt_str(i) := ptr(i);
            end loop;
            print(txt_str);
        end if;
    end txt_print;

    -------------------------------------------------------------------------------
    --  procedure copy text into an existing pointer
    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
                           variable ptr_o : out stm_text_ptr;
                           variable txt_str : in stm_text) is
        variable ptr_temp : stm_text_ptr;
    begin
        ptr_temp := ptr;
        if (ptr_temp /= null) then
            for i in 1 to c_stm_text_len loop
                if (txt_str(i) = nul) then
                    exit;
                end if;
                ptr_temp(i) := txt_str(i);
            end loop;
        end if;
        ptr_o := ptr_temp;
    end txt_ptr_copy;

    -------------------------------------------------------------------------------
    --  procedure to print to the stdout the txt pointer, and
    --     sub any variables found
    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable ptr : in stm_text_ptr;
                             constant b : in base) is
        variable i : integer;
        variable j : integer;
        variable k : integer;
        variable txt_str : stm_text;
        variable v1 : integer;
        variable valid : integer;
        variable tmp_field : text_field;
        variable tmp_i : integer;
    begin
        if (ptr /= null) then
            i := 1;
            j := 1;
            txt_str := (others => nul);
            while (i <= c_stm_text_len and j <= c_stm_text_len) loop
                if (ptr(i) /= '$') then
                    txt_str(j) := ptr(i);
                    i := i + 1;
                    j := j + 1;
                else
                    tmp_field := (others => nul);
                    tmp_i := 1;
                    tmp_field(tmp_i) := ptr(i);
                    i := i + 1;
                    tmp_i := tmp_i + 1;
                    -- parse to the next space
                    while (ptr(i) /= ' ' and ptr(i) /= nul) loop
                        tmp_field(tmp_i) := ptr(i);
                        i := i + 1;
                        tmp_i := tmp_i + 1;
                    end loop;
                    access_variable(var_list, tmp_field, v1, valid);
                    assert (valid = 1)
                    report lf & "invalid variable found in stm_text_ptr: ignoring."
                    severity warning;

                    if (valid = 1) then

                        txt_str := ew_str_cat(txt_str, ew_to_str_len(v1, b));
                        k := 1;
                        while (txt_str(k) /= nul) loop
                            k := k + 1;
                        end loop;
                        j := k;
                    end if;
                end if;
            end loop;
            -- print the created string
            print(txt_str);
        end if;
    end txt_print_wvar;

    -------------------------------------------------------------------------
    --  get a rundom intetger number
    procedure getrandint(variable seed1 : inout positive;
                         variable seed2 : inout positive;
                         variable lowestvalue : in integer;
                         variable utmostvalue : in integer;
                         variable randint : out integer) is
        variable randreal : real;
        variable intdelta : integer;
    begin
        intdelta := utmostvalue - lowestvalue;
        uniform(seed1, seed2, randreal); -- generate random number
        randint := integer(trunc(randreal * (real(intdelta) + 1.0))) + lowestvalue; -- rescale to delta, find integer part, adjust
    end getrandint;

end tb_pkg;
