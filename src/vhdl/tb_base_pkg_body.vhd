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
use ieee.math_real.all;

package body tb_base_pkg is

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
                    assert false
                    report lf & "error: bin2integer found non binary digit on line " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (2 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end function;

    function bin2stm_value(bin_number : in text_field;
                           file_name : in text_line;
                           line : in integer;
                           stm_value_width : in integer) return unsigned is
        variable len : integer;
        variable temp_stm_value : unsigned(stm_value_width - 1 downto 0);
        variable vec_number : std_logic;
    begin
        len := fld_len(bin_number);
        temp_stm_value := to_unsigned(0, stm_value_width);
        for i in 1 to len loop
            case bin_number(i) is
                when '0' =>
                    vec_number := '0';
                when '1' =>
                    vec_number := '1';
                when others =>
                    assert false
                    report lf & "error: bin2stm_value found non binary digit on line " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_stm_value := temp_stm_value(stm_value_width - 2 downto 0) & vec_number;
        end loop;
        return temp_stm_value;
    end function;

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
                report lf & "error: c2int was given a non number digit."
                severity failure;
        end case;
        return i;
    end function;

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
                report lf & "error: c2std_vec found non hex digit on file line "
                severity failure;
                return "XXXX";
        end case;
    end function;

    procedure check_presence_instruction_file_name(file_list : inout file_def_ptr;
                                                   file_name : in string;
                                                   present : out boolean) is
        variable temp_fn_prt : file_def_ptr;
    begin
        present := false;
        -- recover the file name this line came from
        temp_fn_prt := file_list;
        while temp_fn_prt.next_rec /= null loop
            if file_name = temp_fn_prt.file_name then
                present := true;
                return;
            end if;
            temp_fn_prt := temp_fn_prt.next_rec;
        end loop;
        return;
    end procedure;

    function ew_str_cat(s1 : stm_text;
                        s2 : text_field) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sc : stm_text;
    begin
        sc := s1;
        i := 1;
        while sc(i) /= nul loop
            i := i + 1;
        end loop;
        j := 1;
        while s2(j) /= nul loop
            sc(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sc;
    end function;

    function ew_str_cat(s1 : stm_text;
                        s2 : text_field;
                        s3 : integer) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sc : stm_text;
    begin
        sc := s1;
        i := 1;
        while sc(i) /= nul loop
            i := i + 1;
        end loop;
        j := s3;
        while s2(j) /= nul loop
            sc(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        return sc;
    end function;

    function ew_str_cat(s1 : stm_text;
                        s2 : text_field;
                        s3 : integer;
                        s4 : character) return stm_text is
        variable i : integer;
        variable j : integer;
        variable sc : stm_text;
    begin
        sc := s1;
        i := 1;
        while sc(i) /= nul loop
            i := i + 1;
        end loop;
        j := s3;
        while s2(j) /= nul loop
            sc(i) := s2(j);
            i := i + 1;
            j := j + 1;
        end loop;
        sc(i) := s4;
        return sc;
    end function;

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
                assert false
                report lf & "error: ew_to_char was given a non number digit."
                severity failure;
        end case;
        return c;
    end function;

    function ew_to_str(int : integer;
                       b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : integer := 0;
        variable num : integer := 0;
        variable power : integer := 1;
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable ix : integer;
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
        if num < 0 and b = hex then
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
            for i in len downto 1 loop -- convert the number to
                temp(i) := ew_to_char(int / power mod radix); -- a string starting
                power := power * radix; -- with the right hand
            end loop; -- side.
        end if;
        -- add prefix if is one
        if pre(1) /= nul then
            temp1 := temp;
            ix := 1;
            j := 3;
            temp(1 to 2) := pre;
            while temp1(ix) /= nul loop
                temp(j) := temp1(ix);
                ix := ix + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;

    function ew_to_str(stmvalue : unsigned;
                       b : base) return text_field is
        variable temp : text_field;
        variable temp1 : text_field;
        variable radix : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(1, stmvalue'length);
        variable num : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(0, stmvalue'length);
        variable power : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(1, stmvalue'length);
        variable len : integer := 1;
        variable pre : string(1 to 2);
        variable ix : integer;
        variable j : integer;
        variable cpval : unsigned(stmvalue'length - 1 downto 0) := to_unsigned(0, stmvalue'length);
    begin
        num := stmvalue;
        temp := (others => nul);
        case b is
            when bin =>
                radix := to_unsigned(2, stmvalue'length); -- depending on what
                pre := "0b";
            when oct =>
                radix := to_unsigned(8, stmvalue'length); -- base the number is
                pre := "0o";
            when hex =>
                radix := to_unsigned(16, stmvalue'length); -- to be displayed as
                pre := "0x";
            when dec =>
                radix := to_unsigned(10, stmvalue'length); -- choose a radix range
                pre := (others => nul);
        end case;
        while num >= radix loop -- determine how many
            len := len + 1; -- characters required
            num := num / radix; -- to represent the
        end loop; -- number.
        for i in len downto 1 loop -- convert the number to
            cpval := stmvalue / power mod radix;
            temp(i) := ew_to_char(to_integer(cpval(3 downto 0))); -- a string starting
            power := resize(power * radix, stmvalue'length); -- with the right hand
        end loop; -- side.

        -- add prefix if is one
        if pre(1) /= nul then
            temp1 := temp;
            ix := 1;
            j := 3;
            temp(1 to 2) := pre;
            while temp1(ix) /= nul loop
                temp(j) := temp1(ix);
                ix := ix + 1;
                j := j + 1;
            end loop;
        end if;
        return temp;
    end function;

    function fld_equal(s1 : in text_field;
                       s2 : in text_field) return boolean is
        variable i : integer := 0;
        variable s1_length : integer := 0;
        variable s2_length : integer := 0;
    begin
        s1_length := fld_len(s1);
        s2_length := fld_len(s2);

        if s1_length /= s2_length then
            return false;
        end if;
        while i /= s1_length loop
            i := i + 1;
            if s1(i) /= s2(i) then
                return false;
            end if;
        end loop;
        return true;
    end function;

    function fld_len(s : in text_field) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= max_field_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure get_instruction_file_name(file_list : inout file_def_ptr;
                                        file_idx : integer;
                                        file_name : inout text_line) is
        variable temp_fn_prt : file_def_ptr;
    begin
        -- recover the file name this line came from
        temp_fn_prt := file_list;
        while temp_fn_prt.next_rec /= null loop
            if temp_fn_prt.rec_idx = file_idx then
                exit;
            end if;
            temp_fn_prt := temp_fn_prt.next_rec;
        end loop;
        for i in 1 to max_str_len loop
            file_name(i) := temp_fn_prt.file_name(i);
        end loop;
    end procedure;

    procedure get_line_from_str(s : in string;
                                std_line : inout line) is
    begin
        for i in 1 to s'length loop
            if s(i) /= nul then
                write(std_line, s(i));
            end if;
        end loop;
    end procedure;

    procedure get_stm_text_ptr_from_line(std_line : inout line;
                                         var_stm_text_ptr : inout stm_text_ptr) is
        variable var_stm_text : stm_text;
        variable chr : character;
        variable good : boolean;
        variable tmp_std_line : line;
    begin
        tmp_std_line := new string'(std_line.all);
        for i in 1 to var_stm_text'length loop
            read(tmp_std_line, chr, good);
            if good then
                var_stm_text(i) := chr;
            else
                var_stm_text(i) := nul;
                exit;
            end if;
        end loop;
        stm_text_copy_to_ptr(var_stm_text_ptr, var_stm_text);
    end procedure;

    procedure random(variable seed1 : inout positive;
                     variable seed2 : inout positive;
                     variable rand : out real) is
    begin
        uniform(seed1, seed2, rand);
    end procedure;

    procedure random(variable seed1 : inout positive;
                     variable seed2 : inout positive;
                     variable lowestvalue : in integer;
                     variable utmostvalue : in integer;
                     variable rand : out integer) is
        variable randreal : real := 0.0;
        variable intdelta : integer := 0;
    begin
        intdelta := utmostvalue - lowestvalue;
        uniform(seed1, seed2, randreal); -- generate random number
        rand := integer(trunc(randreal * (real(intdelta) + 1.0))) + lowestvalue; -- rescale to delta, find integer part, adjust
    end procedure;

    procedure random(variable seed1 : inout positive;
                     variable seed2 : inout positive;
                     variable rand : out unsigned) is
        constant size : integer := rand'length;
        -- Populate vector in 30-bit chunks to avoid exceeding the
        -- range of integer
        constant seg_size : natural := 30;
        constant segments : natural := size / seg_size;
        constant remainder : natural := size - segments * seg_size;
        variable lowestvalue : integer := 0;
        variable utmostvalue : integer := 0;
        variable rand_of_segment : integer := 0;
        variable result : unsigned(rand'range) := (others => '0');
    begin
        if segments > 0 then
            for s in 0 to segments - 1 loop
                lowestvalue := 0;
                utmostvalue := 2 ** seg_size - 1;
                random(seed1, seed2, lowestvalue, utmostvalue, rand_of_segment);
                result((s + 1) * seg_size - 1 downto s * seg_size) := to_unsigned(rand_of_segment, seg_size);
            end loop;
        end if;
        if remainder > 0 then
            lowestvalue := 0;
            utmostvalue := 2 ** remainder - 1;
            random(seed1, seed2, lowestvalue, utmostvalue, rand_of_segment);
            result(size - 1 downto size - remainder) := to_unsigned(rand_of_segment, remainder);
        end if;
        rand := result;
    end procedure;

    procedure random(variable seed1 : inout positive;
                     variable seed2 : inout positive;
                     variable lowestvalue : in unsigned;
                     variable utmostvalue : in unsigned;
                     variable rand : out unsigned) is
        variable rand_full_range : unsigned(rand'range) := to_unsigned(0, rand'length);
        variable rand_delta_range : unsigned(rand'length * 2 - 1 downto 0) := to_unsigned(0, rand'length * 2);
        variable delta : unsigned(rand'range) := to_unsigned(0, rand'length);
        variable product : unsigned(rand'length * 2 - 1 downto 0) := to_unsigned(0, rand'length * 2);

    begin
        random(seed1, seed2, rand_full_range);
        delta := utmostvalue - lowestvalue;
        product := rand_full_range * delta;
        rand_delta_range := shift_right(product, rand'length);
        rand := lowestvalue + resize(rand_delta_range, rand'length);
    end procedure;

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
                    assert false
                    report lf & "error: hex2integer found non hex digit on line " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_int := temp_int + (int_number * (16 ** power));
            power := power + 1;
        end loop;
        return temp_int;
    end function;

    function hex2stm_value(hex_number : in text_field;
                           file_name : in text_line;
                           line : in integer;
                           stm_value_width : in integer) return unsigned is
        variable len : integer;
        variable temp_stm_value : unsigned(stm_value_width - 1 downto 0);
        variable vec_number : unsigned(3 downto 0);
    begin
        len := fld_len(hex_number);
        temp_stm_value := to_unsigned(0, stm_value_width);
        for i in 1 to len loop
            case hex_number(i) is
                when '0' =>
                    vec_number := x"0";
                when '1' =>
                    vec_number := x"1";
                when '2' =>
                    vec_number := x"2";
                when '3' =>
                    vec_number := x"3";
                when '4' =>
                    vec_number := x"4";
                when '5' =>
                    vec_number := x"5";
                when '6' =>
                    vec_number := x"6";
                when '7' =>
                    vec_number := x"7";
                when '8' =>
                    vec_number := x"8";
                when '9' =>
                    vec_number := x"9";
                when 'a' | 'A' =>
                    vec_number := x"A";
                when 'b' | 'B' =>
                    vec_number := x"B";
                when 'c' | 'C' =>
                    vec_number := x"C";
                when 'd' | 'D' =>
                    vec_number := x"D";
                when 'e' | 'E' =>
                    vec_number := x"E";
                when 'f' | 'F' =>
                    vec_number := x"F";
                when others =>
                    assert false
                    report lf & "error: hex2stm_value found non hex digit on line " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
            temp_stm_value := temp_stm_value(stm_value_width - 5 downto 0) & vec_number;

        end loop;
        return temp_stm_value;
    end function;

    function is_digit(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if c >= '0' and c <= '9' then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;

    function is_space(constant c : in character) return boolean is
        variable rtn : boolean;
    begin
        if c = ' ' or c = ht then
            rtn := true;
        else
            rtn := false;
        end if;
        return rtn;
    end function;

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
    end procedure;

    procedure init_const_text_field(constant sourcestr : in string;
                                    variable destfield : out text_field) is
        variable tempfield : text_field;
    begin
        for i in 1 to sourcestr'length loop
            tempfield(i) := sourcestr(i);
        end loop;
        for i in 1 to text_field'length loop
            destfield(i) := tempfield(i);
        end loop;
    end procedure;

    procedure print(s : in string) is
        variable l : line;
    begin
        for i in 1 to s'length loop
            if s(i) /= nul then
                write(l, s(i));
            end if;
        end loop;
        writeline(output, l);
    end procedure;

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
                report lf & "error: std_vec2c found non-binary digit in vec "
                severity failure;
                return 'X';
        end case;
    end function;

    function stim_to_integer(field : in text_field;
                             file_name : in text_line;
                             line : in integer) return integer is
        variable value : integer := 1;
        variable temp_str : text_field;
    begin
        if field(1) = '0' and (field(2) = 'x' or field(2) = 'b') then
            case field(2) is
                when 'x' =>
                    value := 3;
                    while field(value) /= nul loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    -- assert(false)
                    -- report lf & "hex2integer: " & temp_str
                    -- severity warning;
                    value := hex2integer(temp_str, file_name, line);
                when 'b' =>
                    value := 3;
                    while field(value) /= nul loop
                        temp_str(value - 2) := field(value);
                        value := value + 1;
                    end loop;
                    value := bin2integer(temp_str, file_name, line);
                when others =>
                    assert false
                    report lf & "error: strange # found ! " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
        else
            value := str2integer(field);
        end if;
        return value;
    end function;

    function stim_to_stm_value(field : in text_field;
                               file_name : in text_line;
                               line : in integer;
                               stm_value_width : in integer) return unsigned is
        variable stmvalue : unsigned(stm_value_width - 1 downto 0) := to_unsigned(1, stm_value_width);
        variable ci : integer := 1;
        variable temp_str : text_field;
    begin
        if field(1) = '0' and (field(2) = 'x' or field(2) = 'b') then
            case field(2) is
                when 'x' =>
                    ci := 3;
                    while field(ci) /= nul loop
                        temp_str(ci - 2) := field(ci);
                        ci := ci + 1;
                    end loop;
                    -- assert(false)
                    -- report lf & "hex2integer: " & temp_str
                    -- severity warning;
                    stmvalue := hex2stm_value(temp_str, file_name, line, stm_value_width);
                when 'b' =>
                    ci := 3;
                    while field(ci) /= nul loop
                        temp_str(ci - 2) := field(ci);
                        ci := ci + 1;
                    end loop;
                    stmvalue := bin2stm_value(temp_str, file_name, line, stm_value_width);
                when others =>
                    assert false
                    report lf & "error: strange # found ! " & (integer'image(line)) & " of file " & file_name
                    severity failure;
            end case;
        else
            stmvalue := str2stm_value(field, stm_value_width);
        end if;
        return stmvalue;
    end function;

    procedure stm_file_append(variable stm_lines : in t_stm_lines_ptr;
                              variable file_path : in stm_text_ptr;
                              variable valid : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable stm_lines_get_valid : integer := 0;
        variable position : integer;
        variable file_path_string : stm_text;
    begin
        valid := 0;
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), append_mode);
        if v_stat /= open_ok then
            return;
        end if;
        for i in 0 to stm_lines.size - 1 loop
            position := i;
            stm_lines_get(stm_lines, position, std_line, stm_lines_get_valid);
            writeline(user_file, std_line);
            if stm_lines_get_valid = 0 then
                return;
            end if;
        end loop;
        valid := 1;
        file_close(user_file);
    end procedure;

    procedure stm_file_appendable(variable file_path : in stm_text_ptr;
                                  variable status : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    procedure stm_file_read_all(variable stm_lines : inout t_stm_lines_ptr;
                                variable file_path : in stm_text_ptr;
                                variable valid : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable tmp_std_line : line;
        variable stm_lines_append_valid : integer := 0;
        variable file_path_string : stm_text;
    begin
        valid := 0;
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat /= open_ok then
            return;
        end if;
        while not endfile(user_file) loop
            readline(user_file, std_line);
            tmp_std_line := new string'(std_line.all);
            stm_lines_append(stm_lines, tmp_std_line, stm_lines_append_valid);
            if stm_lines_append_valid = 0 then
                return;
            end if;
        end loop;
        valid := 1;
        file_close(user_file);
    end procedure;

    procedure stm_file_readable(variable file_path : in stm_text_ptr;
                                variable status : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), read_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    function stm_file_status(v_stat : file_open_status) return integer is
    begin
        if v_stat = open_ok then
            return 0;
        elsif v_stat = status_error then
            return 1;
        elsif v_stat = name_error then
            return 2;
        elsif v_stat = mode_error then
            return 3;
        else
            return 4;
        end if;
    end function;

    procedure stm_file_write(variable stm_lines : in t_stm_lines_ptr;
                             variable file_path : in stm_text_ptr;
                             variable valid : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable std_line : line;
        variable stm_lines_get_valid : integer := 0;
        variable position : integer;
        variable file_path_string : stm_text;
    begin
        valid := 0;
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), write_mode);
        if v_stat /= open_ok then
            return;
        end if;
        for i in 0 to stm_lines.size - 1 loop
            position := i;
            stm_lines_get(stm_lines, position, std_line, stm_lines_get_valid);
            writeline(user_file, std_line);
            if stm_lines_get_valid = 0 then
                return;
            end if;
        end loop;
        valid := 1;
        file_close(user_file);
    end procedure;

    procedure stm_file_writeable(variable file_path : in stm_text_ptr;
                                 variable status : out integer) is
        variable v_stat : file_open_status;
        file user_file : text;
        variable file_path_string : stm_text;
    begin
        txt_to_string(file_path, file_path_string);
        file_open(v_stat, user_file, stm_text_crop(file_path_string), write_mode);
        if v_stat = open_ok then
            file_close(user_file);
        end if;
        status := stm_file_status(v_stat);
    end procedure;

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable std_line : in line;
                               variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable stm_next_line_ptr : t_stm_line_ptr;
    begin
        valid := 0;
        if stm_lines.size = 0 then
            stm_line_ptr := new t_stm_line;
            stm_line_ptr.line_number := 0;
            stm_line_ptr.line_content := std_line;
            stm_line_ptr.line_type := STM_LINE_TEXT_TYPE;
            stm_line_ptr.array_size := 0;
            stm_line_ptr.next_stm_line := null;
            stm_lines.stm_line_list := stm_line_ptr;
            stm_lines.size := 1;
        else
            stm_line_ptr := stm_lines.stm_line_list;
            while stm_line_ptr.next_stm_line /= null loop
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
            stm_next_line_ptr := new t_stm_line;
            stm_next_line_ptr.line_number := stm_line_ptr.line_number + 1;
            stm_next_line_ptr.line_content := std_line;
            stm_next_line_ptr.line_type := STM_LINE_TEXT_TYPE;
            stm_next_line_ptr.array_size := 0;
            stm_next_line_ptr.next_stm_line := null;
            stm_line_ptr.next_stm_line := stm_next_line_ptr;
            stm_lines.size := stm_lines.size + 1;
            valid := 1;
        end if;
        valid := 1;
    end procedure;

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable stm_array : in t_stm_array_ptr;
                               variable valid : out integer;
                               constant stm_value_width : in integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable std_line : line;
        variable stm_next_line_ptr : t_stm_line_ptr;
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
    begin
        valid := 0;
        for j in 0 to stm_array'length - 1 loop
            value_std_logic_vector := std_logic_vector(stm_array(j));
            hwrite(std_line, value_std_logic_vector, left, stm_value_width / 4 + 1);
        end loop;
        if stm_lines.size = 0 then
            stm_line_ptr := new t_stm_line;
            stm_line_ptr.line_number := 0;
            stm_line_ptr.line_content := std_line;
            stm_line_ptr.line_type := STM_LINE_ARRAY_TYPE;
            stm_line_ptr.array_size := stm_array'length;
            stm_line_ptr.next_stm_line := null;
            stm_lines.stm_line_list := stm_line_ptr;
            stm_lines.size := 1;
        else
            stm_line_ptr := stm_lines.stm_line_list;
            while stm_line_ptr.next_stm_line /= null loop
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
            stm_next_line_ptr := new t_stm_line;
            stm_next_line_ptr.line_number := stm_line_ptr.line_number + 1;
            stm_next_line_ptr.line_content := std_line;
            stm_next_line_ptr.line_type := STM_LINE_ARRAY_TYPE;
            stm_next_line_ptr.array_size := stm_array'length;
            stm_next_line_ptr.next_stm_line := null;
            stm_line_ptr.next_stm_line := stm_next_line_ptr;
            stm_lines.size := stm_lines.size + 1;
            valid := 1;
        end if;
        valid := 1;
    end procedure;

    procedure stm_lines_append(variable stm_lines : inout t_stm_lines_ptr;
                               variable var_stm_text : in stm_text_ptr;
                               variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable stm_next_line_ptr : t_stm_line_ptr;
        variable std_line : line;
    begin
        valid := 0;
        stm_text_ptr_to_line(var_stm_text, std_line);
        if stm_lines.size = 0 then
            stm_line_ptr := new t_stm_line;
            stm_line_ptr.line_number := 0;
            stm_line_ptr.line_content := std_line;
            stm_line_ptr.line_type := STM_LINE_TEXT_TYPE;
            stm_line_ptr.array_size := 0;
            stm_line_ptr.next_stm_line := null;
            stm_lines.stm_line_list := stm_line_ptr;
            stm_lines.size := 1;
        else
            stm_line_ptr := stm_lines.stm_line_list;
            while stm_line_ptr.next_stm_line /= null loop
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
            stm_next_line_ptr := new t_stm_line;
            stm_next_line_ptr.line_number := stm_line_ptr.line_number + 1;
            stm_next_line_ptr.line_content := std_line;
            stm_next_line_ptr.line_type := STM_LINE_TEXT_TYPE;
            stm_next_line_ptr.array_size := 0;
            stm_next_line_ptr.next_stm_line := null;
            stm_line_ptr.next_stm_line := stm_next_line_ptr;
            stm_lines.size := stm_lines.size + 1;
            valid := 1;
        end if;
        valid := 1;
    end procedure;

    procedure stm_lines_delete(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : in integer;
                               variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable stm_line_before : t_stm_line_ptr := null;
        variable stm_line_after : t_stm_line_ptr := null;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                stm_line_after := stm_line_ptr.next_stm_line;
                if stm_line_before /= null and stm_line_after /= null then
                    stm_line_before.next_stm_line := stm_line_after;
                elsif stm_line_before = null and stm_line_after /= null then
                    stm_lines.stm_line_list := stm_line_after;
                elsif stm_line_before /= null and stm_line_after = null then
                    stm_line_before.next_stm_line := null;
                else
                    stm_lines.stm_line_list := null;
                end if;
                deallocate(stm_line_ptr);
                stm_lines.size := stm_lines.size - 1;
                valid := 1;
                exit;
            end if;
            stm_line_before := stm_line_ptr;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            stm_line_ptr.line_number := i;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
                            variable position : in integer;
                            variable std_line : out line;
                            variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                std_line := new string'(stm_line_ptr.line_content.all);
                valid := 1;
                return;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_get(variable stm_lines : in t_stm_lines_ptr;
                            variable position : in integer;
                            variable stm_array : inout t_stm_array_ptr;
                            variable number_found : out integer;
                            variable valid : out integer;
                            constant stm_value_width : in integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
        variable success : boolean := true;
        variable array_index : integer := 0;
        variable tmp_std_line : line;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                tmp_std_line := new string'(stm_line_ptr.line_content.all);
                while success loop
                    hread(tmp_std_line, value_std_logic_vector, success);
                    if success then
                        stm_array(array_index) := unsigned(value_std_logic_vector);
                        array_index := array_index + 1;
                    end if;
                end loop;
                number_found := array_index;
                valid := 1;
                return;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : in integer;
                               variable var_stm_text : in stm_text_ptr;
                               variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable tmp_std_line : line;
        variable stm_line_new : t_stm_line_ptr := new t_stm_line;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 1 to var_stm_text'length loop
                    if var_stm_text(j) /= nul then
                        write(tmp_std_line, var_stm_text(j), left, 1);
                    else
                        exit;
                    end if;
                end loop;
                -- copy current stm_line to new stmline object
                stm_line_new.line_content := stm_line_ptr.line_content;
                stm_line_new.line_type := stm_line_ptr.line_type;
                stm_line_new.array_size := stm_line_ptr.array_size;
                stm_line_new.next_stm_line := stm_line_ptr.next_stm_line;
                -- set current stm_line to new content
                stm_line_ptr.line_content := tmp_std_line;
                stm_line_ptr.line_type := STM_LINE_TEXT_TYPE;
                stm_line_ptr.array_size := 0;
                stm_line_ptr.next_stm_line := stm_line_new;
                stm_lines.size := stm_lines.size + 1;
                valid := 1;
                exit;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            stm_line_ptr.line_number := i;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_insert(variable stm_lines : inout t_stm_lines_ptr;
                               variable position : integer;
                               variable stm_array : in t_stm_array_ptr;
                               variable valid : out integer;
                               constant stm_value_width : in integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable tmp_std_line : line;
        variable stm_line_new : t_stm_line_ptr := new t_stm_line;
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 0 to stm_array'length - 1 loop
                    value_std_logic_vector := std_logic_vector(stm_array(j));
                    hwrite(tmp_std_line, value_std_logic_vector, left, stm_value_width / 4 + 1);
                end loop;
                -- copy current stm_line to new stmline object
                stm_line_new.line_content := stm_line_ptr.line_content;
                stm_line_new.line_type := stm_line_ptr.line_type;
                stm_line_new.array_size := stm_line_ptr.array_size;
                stm_line_new.next_stm_line := stm_line_ptr.next_stm_line;
                -- set current stm_line to new content
                stm_line_ptr.line_content := tmp_std_line;
                stm_line_ptr.line_type := STM_LINE_ARRAY_TYPE;
                stm_line_ptr.array_size := stm_array'length;
                stm_line_ptr.next_stm_line := stm_line_new;
                stm_lines.size := stm_lines.size + 1;
                valid := 1;
                exit;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            stm_line_ptr.line_number := i;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_print(variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer) is
        variable std_line : line;
        variable tmp_str_ptr : stm_text_ptr;
        variable stm_line_ptr : t_stm_line_ptr;
        variable tmp_std_line_print : line;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        while stm_line_ptr /= null loop
            if stm_line_ptr.line_type = STM_LINE_TEXT_TYPE then
                std_line := stm_line_ptr.line_content;
                tmp_str_ptr := new stm_text;
                get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                stm_text_ptr_to_line(tmp_str_ptr, std_line);
                stm_line_ptr.line_content := std_line;
                txt_print(tmp_str_ptr);
            elsif stm_line_ptr.line_type = STM_LINE_ARRAY_TYPE then
                tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                writeline(output, tmp_std_line_print);
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
        valid := 1;
    end procedure;

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
                            variable position : in integer;
                            variable var_stm_text : in stm_text_ptr;
                            variable valid : out integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable std_line : line;
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 1 to var_stm_text'length loop
                    if var_stm_text(j) /= nul then
                        write(std_line, var_stm_text(j), left, 1);
                    else
                        exit;
                    end if;
                end loop;
                stm_line_ptr.line_content := std_line;
                stm_line_ptr.line_type := STM_LINE_TEXT_TYPE;
                stm_line_ptr.array_size := 0;
                valid := 1;
                return;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_lines_set(variable stm_lines : inout t_stm_lines_ptr;
                            variable position : integer;
                            variable stm_array : in t_stm_array_ptr;
                            variable valid : out integer;
                            constant stm_value_width : in integer) is
        variable stm_line_ptr : t_stm_line_ptr;
        variable std_line : line;
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
    begin
        valid := 0;
        stm_line_ptr := stm_lines.stm_line_list;
        for i in 0 to stm_lines.size - 1 loop
            if i = position then
                for j in 0 to stm_array'length - 1 loop
                    value_std_logic_vector := std_logic_vector(stm_array(j));
                    hwrite(std_line, value_std_logic_vector, left, stm_value_width / 4 + 1);
                end loop;
                stm_line_ptr.line_content := std_line;
                valid := 1;
                return;
            end if;
            stm_line_ptr := stm_line_ptr.next_stm_line;
        end loop;
    end procedure;

    procedure stm_text_copy_to_ptr(variable ptr : inout stm_text_ptr;
                                   variable txt_str : in stm_text) is
    begin
        if ptr /= null then
            for i in 1 to c_stm_text_len loop
                if txt_str(i) = nul then
                    exit;
                end if;
                ptr(i) := txt_str(i);
            end loop;
        end if;
    end procedure;

    function stm_text_crop(txt : in stm_text) return string is
        variable l : integer;
    begin
        l := stm_text_len(txt);
        return txt(1 to l);
    end function;

    function stm_text_len(s : in stm_text) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= c_stm_text_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure stm_text_ptr_to_line(variable var_stm_text : in stm_text_ptr;
                                   variable line_out : out line) is
        variable std_line : line;
    begin
        for j in 1 to var_stm_text'length loop
            if var_stm_text(j) /= nul then
                write(std_line, var_stm_text(j), left, 1);
            else
                exit;
            end if;
        end loop;
        line_out := std_line;
    end procedure;

    procedure stm_text_ptr_truncate_trailing_quote(variable si : stm_text_ptr;
                                                   variable so : inout stm_text_ptr) is
        variable i : integer := 1;
        variable o : integer := 1;
    begin
        while si(i) /= nul and i /= max_str_len loop
            if i + 1 /= max_str_len then
                if si(i + 1) /= nul then
                    if si(i) = '\' and si(i + 1) = '"' then -- "
                        -- skip '/' before '"'    "
                        i := i + 1;
                        so(o) := si(i);
                        i := i + 1;
                        o := o + 1;
                    else
                        -- don't skip '/' before others but '"'    "
                        if si(i) = '"' then -- this is the trailing '"'    "
                            exit;
                        end if;
                        so(o) := si(i);
                        i := i + 1;
                        o := o + 1;
                    end if;
                else
                    if si(i) = '"' then -- this is the trailing '"'    "
                        exit;
                    end if;
                    so(o) := si(i);
                    i := i + 1;
                    o := o + 1;
                end if;
            else
                if si(i) = '"' then -- this is the trailing '"'    "
                    exit;
                end if;
                so(o) := si(i);
                i := i + 1;
                o := o + 1;
            end if;
        end loop;
    end procedure;

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
    end function;

    function str2stm_value(str : in string; stm_value_width : in integer) return unsigned is
        variable l : integer;
        variable rtn : unsigned(stm_value_width - 1 downto 0) := to_unsigned(0, stm_value_width);
    begin
        l := fld_len(str);
        for i in 1 to l loop
            rtn := resize(rtn * 10 + c2int(str(i)), stm_value_width);
        end loop;
        return rtn;
    end function;

    function text_line_crop(txt : in text_line) return string is
        variable l : integer;
    begin
        l := text_line_len(txt);
        return txt(1 to l);
    end function;

    function text_line_len(s : in text_line) return integer is
        variable i : integer := 1;
    begin
        while s(i) /= nul and i /= max_str_len loop
            i := i + 1;
        end loop;
        return (i - 1);
    end function;

    procedure txt_print(variable ptr : in stm_text_ptr) is
        variable txt_str : stm_text;
    begin
        if ptr /= null then
            txt_str := (others => nul);
            for i in 1 to c_stm_text_len loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                txt_str(i) := ptr(i);
            end loop;
            print(txt_str);
        end if;
    end procedure;

    procedure txt_ptr_copy(variable ptr : in stm_text_ptr;
                           variable ptr_o : out stm_text_ptr;
                           variable txt_str : in stm_text) is
        variable ptr_temp : stm_text_ptr;
    begin
        ptr_temp := ptr;
        if ptr_temp /= null then
            for i in 1 to c_stm_text_len loop
                if txt_str(i) = nul then
                    exit;
                end if;
                ptr_temp(i) := txt_str(i);
            end loop;
        end if;
        ptr_o := ptr_temp;
    end procedure;

    procedure txt_to_string(variable ptr : in stm_text_ptr;
                            variable str : out stm_text) is
        variable txt_str : stm_text;
    begin
        txt_str := (others => nul);
        if ptr /= null then
            for i in 1 to c_stm_text_len loop
                if (ptr(i) = nul) then
                    exit;
                end if;
                txt_str(i) := ptr(i);
            end loop;
            str := txt_str;
        end if;
    end procedure;

    function to_str_hex(int : integer) return string is
    begin
        return ew_to_str(int, hex);
    end function;

    function to_str(int : integer) return string is
    begin
        return ew_to_str(int, dec);
    end function;

    function to_str_hex(stmvalue : unsigned) return string is
    begin
        return ew_to_str(stmvalue, hex);
    end function;

    function to_str(stmvalue : unsigned) return string is
    begin
        return ew_to_str(stmvalue, dec);
    end function;

end package body;
