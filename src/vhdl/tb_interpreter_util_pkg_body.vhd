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

use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;

package body tb_interpreter_util_pkg is

    procedure file_read_line(
        file file_name : text;
        variable file_line : out text_line
    ) is
        variable index : integer; -- index into string
        variable rline : line;
    begin
        index := 1; -- set index to begin of string
        file_line := (others => nul);
        if not endfile(file_name) then
            readline(file_name, rline);
            while rline'right /= (index - 1) and rline'length /= 0 loop
                file_line(index) := rline(index);
                index := index + 1;
            end loop;
        end if;
    end procedure;

    procedure tokenize_inst_line(
        variable itext_line : in text_line;
        variable otokens : out token_text_field_array;
        variable txt_ptr : out stm_text_ptr;
        variable txt_enclosing_quote : out character;
        variable ovalid : out integer
    ) is
        variable tmp_text_line : text_line;
        variable token_index : integer := 0;
        variable current_token : text_field;
        variable token_number : integer := 0;
        variable c : string(1 to 2);
        variable comment_found : integer := 0;
        variable txt_found : integer := 0;
        variable j : integer;
        variable txt_ptr_tmp : stm_text_ptr;
        variable txt_str : stm_text;
        variable itokens : unmerged_token_text_field_array;
        variable valid : integer := 0;
        constant SINGLE_QUOTE : character := character'val(39);
        constant DOUBLE_QUOTE : character := character'val(34);

    begin
        tmp_text_line := (others => nul);
        j := 1;
        for i in 1 to itext_line'high - 1 loop
            c(1) := itext_line(i);
            c(2) := itext_line(i + 1);
            if c(2) = '(' and not is_space(c(1)) then
                tmp_text_line(j) := c(1);
                j := j + 1;
                tmp_text_line(j) := ' ';
                j := j + 1;
            elsif c(2) = ')' and not is_space(c(1)) then
                tmp_text_line(j) := c(1);
                j := j + 1;
                tmp_text_line(j) := ' ';
                j := j + 1;
            else
                tmp_text_line(j) := c(1);
                j := j + 1;
            end if;
        end loop;

        -- null outputs
        itokens := (others => (others => nul));
        txt_ptr := null;
        txt_ptr_tmp := null;
        valid := 0;
        txt_found := 0;
        j := 1;
        txt_str := (others => nul);
        -- loop for max number of char
        for i in 1 to tmp_text_line'high loop
            -- collect for comment test ** assumed no line will be max 256
            c(1) := tmp_text_line(i);
            c(2) := tmp_text_line(i + 1); -- or this line will blow up
            if c = "--" then
                comment_found := 1;
                exit;
            end if;
            -- if is begin text char
            if txt_found = 0 and (c(1) = DOUBLE_QUOTE or c(1) = SINGLE_QUOTE) then
                txt_found := 1;
                txt_enclosing_quote := c(1);
                txt_ptr_tmp := new stm_text;
                next;
            end if;
            -- if we have found a txt string
            if txt_found = 1 and tmp_text_line(i) /= nul then
                -- if string too long, prevent tool hang, truncate and notify
                if j > c_stm_text_len then
                    print("tokenize_line: truncated txt line, it was larger than c_stm_text_len");
                    exit;
                end if;
                -- till the very end of tmp_text_line
                if tmp_text_line(i) /= nul then
                    txt_str(j) := tmp_text_line(i);
                    txt_ptr_copy(txt_ptr_tmp, txt_ptr, txt_str);
                    j := j + 1;
                else
                    exit;
                end if;
            -- if is a character store in the right token
            elsif is_space(tmp_text_line(i)) = false and tmp_text_line(i) /= nul then
                token_index := token_index + 1;
                current_token(token_index) := tmp_text_line(i);
            -- else is a space, deal with pointers
            elsif is_space(tmp_text_line(i + 1)) = false and tmp_text_line(i + 1) /= nul then
                for i in 0 to 9 loop
                    if i = 0 then
                        if token_index /= 0 then
                            itokens(1) := current_token;
                            current_token := (others => nul);
                            token_number := 1;
                            valid := 1;
                            token_index := 0;
                        end if;
                    else
                        if i = token_number then
                            itokens(i) := current_token;
                            valid := 1;
                            exit;
                        end if;
                    end if;
                end loop;
            end if;
            -- break from loop if is null
            if tmp_text_line(i) = nul then
                if token_index /= 0 then
                    for i in 0 to 9 loop
                        if i = token_number then
                            itokens(i) := current_token;
                            valid := 1;
                            exit;
                        end if;
                    end loop;
                end if;
                exit;
            end if;
        end loop;
        -- did we find a comment and there is a token
        if comment_found = 1 then
            if token_index /= 0 then
                for i in 0 to 9 loop
                    if i = token_number then
                        itokens(i) := current_token;
                        valid := 1;
                        exit;
                    end if;
                end loop;
            end if;
        end if;
        token_merge_words(itokens, valid, otokens, ovalid);
    end procedure;

    procedure txt_print_wvar(
        variable var_list : in var_field_ptr;
        variable scope : in text_field;
        variable ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable stack_ptr : integer;
        variable stack_called_files : stack_text_line_array;
        variable stack_called_file_linebers : stack_numbers_array;
        variable stack_called_procs : stack_text_field_array;
        constant machine_value_width : in integer
    ) is
        variable stm_text_substituded : stm_text;
    begin
        stm_text_substitude_wvar(var_list, scope, ptr, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_linebers, stack_called_procs, stm_text_substituded, machine_value_width);
        print(stm_text_substituded);
    end procedure;

    procedure stm_text_substitude_wvar(
        variable var_list : in var_field_ptr;
        variable scope : in text_field;
        variable ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable stack_ptr : integer;
        variable stack_called_files : stack_text_line_array;
        variable stack_called_file_line_numbers : stack_numbers_array;
        variable stack_called_procs : stack_text_field_array;
        variable stm_text_substituded : out stm_text;
        constant machine_value_width : in integer
    ) is
        variable src_i : integer;
        variable src_tail_i : integer;
        variable dest_i : integer;
        variable f_src_i : integer;
        variable f_dest_i : integer;
        variable f_dest_txt_str : stm_text;
        variable k : integer;
        variable src_tail_begin : integer;
        variable dest_txt_str : stm_text;
        variable v1 : unsigned(machine_value_width - 1 downto 0);
        variable v1_index : integer;
        variable valid : integer;
        variable tmp_field : text_field;
        variable tmp_i : integer;
        variable input_txt : stm_text;

        variable insert_var : boolean;
        variable format : base;
        variable insert_call_stack_label : boolean;
        variable previous_level : integer;
        variable insert_call_stack_file : boolean;
        variable insert_call_stack_line_number : boolean;
        variable stack_called_file : text_field;
        variable stack_called_file_line_number : integer;
        variable stack_called_label : text_field;

    begin
        if ptr = null then
            return;
        end if;
        txt_to_string(ptr, input_txt);
        -- determine variables tail_start in src string
        src_i := 1;
        src_tail_begin := 0;
        while src_i <= c_stm_text_len loop
            if src_i > 1 then
                if ptr(src_i - 1) = '\' and ptr(src_i) = txt_enclosing_quote then
                    src_i := src_i + 1;
                else
                    if ptr(src_i) = txt_enclosing_quote then
                        src_tail_begin := src_i;
                        exit;
                    end if;
                    src_i := src_i + 1;
                end if;
            else
                if ptr(src_i) = txt_enclosing_quote then
                    src_tail_begin := src_i;
                    exit;
                end if;
                src_i := src_i + 1;
            end if;
        end loop;
        src_i := 1;
        src_tail_i := src_tail_begin;
        dest_i := 1;
        dest_txt_str := (others => nul);
        while src_i <= src_tail_begin and dest_i <= c_stm_text_len loop
            if src_i < src_tail_begin then
                if ptr(src_i) = '\' and ptr(src_i + 1) = txt_enclosing_quote then
                    src_i := src_i + 1;
                end if;
            end if;

            -- copy until next '{'
            while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                if ptr(src_i) = '{' then
                    exit;
                else
                    dest_txt_str(dest_i) := ptr(src_i);
                    src_i := src_i + 1;
                    dest_i := dest_i + 1;
                end if;
            end loop;
            if src_i = src_tail_begin then
                -- src end reached
                f_src_i := 1;
                f_dest_i := 1;
                f_dest_txt_str := (others => nul);
                while f_src_i < dest_i loop
                    if f_src_i + 1 < dest_i then
                        if dest_txt_str(f_src_i) = '\' and dest_txt_str(f_src_i + 1) = txt_enclosing_quote then
                            -- skip '/' before txt_enclosing_quote
                            f_src_i := f_src_i + 1;
                            f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                            f_src_i := f_src_i + 1;
                            f_dest_i := f_dest_i + 1;
                        else
                            -- don't skip '/' before others but txt_enclosing_quote
                            f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                            f_src_i := f_src_i + 1;
                            f_dest_i := f_dest_i + 1;
                        end if;
                    else
                        f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                        f_src_i := f_src_i + 1;
                        f_dest_i := f_dest_i + 1;
                    end if;
                end loop;
                stm_text_substituded := f_dest_txt_str;
                return;
            end if;
            -- place to embed a var found
            insert_call_stack_label := false;
            insert_call_stack_file := false;
            insert_call_stack_line_number := false;
            if ptr(src_i) = '{' then
                src_i := src_i + 1;
                format := hex;
                insert_var := true;
                while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                    if ptr(src_i) = '}' then
                        -- default insert variable hex
                        exit;
                    else
                        -- skip until next '}'
                        if ptr(src_i) = ':' then
                            -- insert variable decimal, binary or octal
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if ptr(src_i) = 'd' then
                                format := dec;
                            elsif ptr(src_i) = 'b' then
                                format := bin;
                            elsif ptr(src_i) = 'o' then
                                format := oct;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        elsif ptr(src_i) = '@' then
                            insert_var := false;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if ptr(src_i) = 'c' then
                                insert_call_stack_label := true;
                            elsif ptr(src_i) = 'f' then
                                insert_call_stack_file := true;
                            elsif ptr(src_i) = 'l' then
                                insert_call_stack_line_number := true;
                            else
                                assert (false)
                                report lf & "wrong substitution format in {...} brackets " & stm_text_crop(input_txt)
                                severity failure;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            previous_level := c2int(ptr(src_i));
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        else
                            assert (false)
                            report lf & "wrong substitution format in {...} brackets " & stm_text_crop(input_txt)
                            severity failure;
                        end if;
                    end if;
                end loop;
            end if;
            if ptr(src_i) = '}' then
                src_i := src_i + 1;
            else
                assert (false)
                report lf & "missing closing } bracket " & stm_text_crop(input_txt)
                severity failure;
            end if;

            if insert_var then
                while src_tail_i <= c_stm_text_len loop
                    if is_txt_var_first_character(ptr(src_tail_i)) then
                        exit;
                    else
                        src_tail_i := src_tail_i + 1;
                    end if;
                end loop;
                assert is_txt_var_first_character(ptr(src_tail_i))
                report lf & "missing variable for substitution bracket " & stm_text_crop(input_txt)
                severity failure;
                tmp_field := (others => nul);
                tmp_i := 1;
                tmp_field(tmp_i) := ptr(src_tail_i);
                src_tail_i := src_tail_i + 1;
                tmp_i := tmp_i + 1;
                -- parse to the next space
                while ptr(src_tail_i) /= ' ' and ptr(src_tail_i) /= nul and ptr(src_tail_i) /=  ht loop
                    tmp_field(tmp_i) := ptr(src_tail_i);
                    src_tail_i := src_tail_i + 1;
                    tmp_i := tmp_i + 1;
                end loop;
                access_var(var_list, scope, tmp_field, v1_index, v1, valid);
                assert valid /= 0
                report lf & "invalid variable found in stm_text_ptr: ignoring."
                severity warning;
                if valid /= 0 then
                    dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(v1, format));
                    k := 1;
                    while dest_txt_str(k) /= nul loop
                        k := k + 1;
                    end loop;
                    dest_i := k;
                end if;
            elsif insert_call_stack_file then
                stack_called_file := stack_called_files(stack_ptr - previous_level)(1 to max_field_len);
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_file);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_line_number then
                stack_called_file_lineber := stack_called_file_linebers(stack_ptr - previous_level);
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(stack_called_file_lineber, dec));
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_label then
                stack_called_label := stack_called_procs(stack_ptr - previous_level);
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_label);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            end if;
        end loop;
        assert false
        report lf & "txt_print_wvar ended abnormally " & stm_text_crop(input_txt)
        severity failure;
    end procedure;
    
    procedure access_inst_element_parameters(
        variable ie : inst_element;
        variable vars : in var_field_ptr;
        variable par_text_fields : in parameter_text_field_array;
        variable par_scopes : in parameter_text_field_array;
        variable par_indexes : out parameter_index_array;
        variable par_values : out parameter_value_array
    ) is
        variable ptf : parameter_text_field_array;
    begin
        for i in 1 to 6 loop
            if par_text_fields(i)(1) /= nul then
                if is_digit(par_text_fields(i)(1)) then
                    par_values(i) := stim_to_stm_value(par_text_fields(i), ie.src_loc, par_text_fields(i)'length);
                else
                    for i in 1 to 6 loop
                        ptf := textfield_dot_cat(par_text_fields(i),par_scopes(i));
                    end loop;
                    access_var(vars, ptf(i), par_indexes(i), par_values(i));
                end if;
            end if;
        end loop;
    end procedure;

    procedure access_var(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer;
        variable var_value : out integer;
        constant machine_value_width : in integer
    ) is
        variable v : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);
    begin
        access_var(vars, var_name, var_element_num, v, valid);
        var_value := to_integer(v(30 downto 0));
    end procedure;

    procedure access_var(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer;
        variable var_value : out integer
    ) is
        variable ven : integer;
        variable tf : text_field;
    begin
        -- if the variable is a special
        if var_name(1) = '=' then
            var_value := to_unsigned(0, var_value'length);
        elsif var_name(1 to 2) = ">=" then
            var_value := to_unsigned(4, var_value'length);
        elsif var_name(1 to 2) = "<=" then
            var_value := to_unsigned(5, var_value'length);
        elsif var_name(1) = '>' then
            var_value := to_unsigned(1, var_value'length);
        elsif var_name(1) = '<' then
            var_value := to_unsigned(2, var_value'length);
        elsif var_name(1 to 2) = "!=" then
            var_value := to_unsigned(3, var_value'length);
        else
            -- check for a local match
            ven := search_var_element_number(vars, var_name);
            if ven >= 0 then
                var_value := vars.element_ptrs(ven).values(0);
                var_element_num := ven;
            else
                -- check for a global match
                tf := truncate_scope(var_name);
                ven := search_var_element_number(vars, tf);
                if ven >= 0 then 
                    var_value := vars.element_ptrs(ven).values(0);
                    var_element_num := ven;
                else
                    assert false
                    report "access var values, neither local variable" & var_name & "nor global variable " & tf &  " is defined"
                    severity failure;                    
                end if;
            end if;
        end if;
    end procedure;

    procedure access_var_value_ptr(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer;
        variable var_values_ptr : out stm_values_ptr
    ) is
    begin
        -- check for a local match
        ven := search_var_element_number(vars, var_name);
        if ven >= 0 then
            var_values_ptr := vars.element_ptrs(ven).values;
            var_element_num := ven;
        else
            -- check for a global match
            tf := truncate_scope(var_name);
            ven := search_var_element_number(vars, tf);
            if ven >= 0 then 
                var_values_ptr := vars.element_ptrs(ven).values;
                var_element_num := ven;
            else
                assert false
                report "access var values ptr, neither local variable" & var_name & "nor global variable " & tf &  " is defined"
                severity failure;                    
            end if;
        end if;
    end procedure;

    procedure access_var_label_ptr(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer;
        variable var_label_ptr : out text_field_ptr
    ) is    
    begin 
        -- check for a local match
        ven := search_var_element_number(vars, var_name);
        if ven >= 0 then
            var_label_ptr := vars.element_ptrs(ven).label_proc_ref;
            var_element_num := ven;
        else
            -- check for a global match
            tf := truncate_scope(var_name);
            ven := search_var_element_number(vars, tf);
            if ven >= 0 then 
                var_label_ptr := vars.element_ptrs(ven).label_proc_ref;
                var_element_num := ven;
            else
                assert false
                report "access var label, neither local variable" & var_name & "nor global variable " & tf &  " is defined"
                severity failure;                    
            end if;
        end if;        
    end procedure;

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var values, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        value := vars.element_ptrs(var_element_num).value(0);
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    ) is
    begin
        vars.element_ptrs(var_element_num).var_value := vars.element_ptrs(var_element_num).var_org_value;
        value := vars.element_ptrs(var_element_num).value(0);
    end procedure;

    procedure index_var_values_ptr(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable value_ptr : out stm_values_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var values ptr var, element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        value_ptr := vars.element_ptrs(var_element_num);
    end procedure;

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : out stm_text_ptr;
        variable var_txt_enclosing_quote : out character
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var text, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        var_txt := vars.element_ptrs(var_element_num).txt;
        var_txt_enclosing_quote := vars.element_ptrs(var_element_num).txt_enclosing_quote;
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : out stm_text_ptr;
        variable var_txt_enclosing_quote : out character
    ) is
    begin        
        assert var_element_num <= vars.last_element_num
        report "index and reinit var text, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).txt:= vars.element_ptrs(var_element_num).txt_org;
        vars.element_ptrs(var_element_num).txt_enclosing_quote := vars.element_ptrs(var_element_num).txt_enclosing_quote_org;
        var_txt := vars.element_ptrs(var_element_num).txt;
        var_txt_enclosing_quote := vars.element_ptrs(var_element_num).txt_enclosing_quote;
    end procedure;

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : out stm_array_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var array, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        var_arr := vars.element_ptrs(var_element_num).arr;
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : out stm_array_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index and reinit var array, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).arr:= vars.element_ptrs(var_element_num).arr_org;
        var_arr := vars.element_ptrs(var_element_num).arr;
    end procedure;

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : out text_field_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var label , var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        var_label_proc_ref := vars.element_ptrs(var_element_num).label_proc_ref;
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : out text_field_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index and reinit var label, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).label_proc_ref:= vars.element_ptrs(var_element_num).label_proc_ref_org;
        var_label_proc_ref := vars.element_ptrs(var_element_num).label_proc_ref;
    end procedure;

    procedure index_var(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : out stm_lines_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var lines , var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        var_lines := vars.element_ptrs(var_element_num).lines;
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_stm_lines : out stm_lines_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index and reinit var lines, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).lines:= vars.element_ptrs(var_element_num).lines_org;
        var_lines := vars.element_ptrs(var_element_num).lines;
    end procedure;

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : in unsigned
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var values , var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).values(0) := value;
    end procedure;

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value : in unsigned
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "reinit and reinit var values, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).values:= vars.element_ptrs(var_element_num).values_org;
        vars.element_ptrs(var_element_num).values(0) := var_value;
    end procedure;

    procedure update_var_values_ptr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value_ptr : in stm_values_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var values ptr, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).values := var_value_ptr;
    end procedure;

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : in stm_text_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var text, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).txt := var_txt;
    end procedure;

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt : in stm_text_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "reinit and reinit var text, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).txt:= vars.element_ptrs(var_element_num).txt_org;
        vars.element_ptrs(var_element_num).txt_enclosing_quote:= vars.element_ptrs(var_element_num).txt_enclosing_quote_org;
        vars.element_ptrs(var_element_num).txt := var_txt;
    end procedure;

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : in stm_array_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var array, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).arr := var_arr;
    end procedure;

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr : in stm_array_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "reinit and reinit var array, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure; 
        vars.element_ptrs(var_element_num).arr:= vars.element_ptrs(var_element_num).arr_org;
        vars.element_ptrs(var_element_num).arr := var_arr;        
    end procedure;

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var label, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).label_proc_ref := var_label_proc_ref;
    end procedure;

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "reinit and reinit var label, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).label_proc_ref:= vars.element_ptrs(var_element_num).label_proc_ref_org;
        vars.element_ptrs(var_element_num).label_proc_ref := var_label_proc_ref;
    end procedure;

    procedure init_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "init and reinit var label, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).label_proc_ref_org := var_label_proc_ref;
        vars.element_ptrs(var_element_num).label_proc_ref := var_label_proc_ref;
    end procedure;

    procedure update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    ) is      
    begin
        assert var_element_num <= vars.last_element_num
        report "update var lines, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).lines := var_lines;
    end procedure;

    procedure reinit_and_update_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "reinit and reinit var lines, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        vars.element_ptrs(var_element_num).lines:= vars.element_ptrs(var_element_num).lines_org;
        vars.element_ptrs(var_element_num).lines := var_lines;
    end procedure;

    procedure print_inst_element(
        variable insts : in inst_sequence;
        variable inst_element_num : in integer;
        variable code_files : in file_def_list
    ) is
    begin
        assert inst_element_num <= insts.last_element_num
        report "print instruction element, inst element number, " & integer'image(inst_element_num) & "greater than insts last element number & integer'image(inst.last_element_num)" 
        severity failure;
        print(".... -----------------------------------------------------------------");
        print(".... instruction " & insts.element_ptrs(inst_element_num).inst);
        print(".... instruction element number: " & to_text_field(inst_element_num));
        print(".... instruction file name: " & insts.element_ptrs(inst_element_num).src_loc.file_name);
        print(".... instruction file linenumber: " & to_text_field(insts.element_ptrs(inst_element_num).src_loc.file_line));              
        for i in 1 to 6 loop
            pl := fld_len(insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
            if pl > 0 then
                print(".... par" & integer'image(i) & insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
            end if;
        end loop;
        print(".... text: " & insts.element_ptrs(inst_element_num).inst_args.txt_enclosing_quote & insts.element_ptrs(inst_element_num).inst_args.txt & insts.element_ptrs(inst_element_num).inst_args.txt_enclosing_quote);
    end procedure;

    procedure dump_inst_sequence(
        variable insts : in inst_sequence;
        variable code_files : in file_def_list
    ) is
    begin
        print("++++ --dump_var_pool_ordered-----------------------------------------------------");
        for i in 0 to insts.last_element_num loop
            print_inst_element(insts, i, code_files);
        end loop;
    end procedure;

    procedure dump_var_pool_ordered(
        variable vars : in var_pool_ordered;
        constant machine_value_width : in integer
    ) is
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump variables start -----------------------------------------");
        for i in 0 to vars.last_element_num loop
            dump_var_element(vars, i, machine_value_width);
        end loop;
    end procedure;

    procedure dump_var_element(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        constant machine_value_width : in integer
    ) is
        variable std_line : line;
        variable tmp_label : text_field;
        variable tmp_str : stm_text;
        variable tmp_str_ptr : stm_text_ptr;
        variable stm_line_ptr : stm_line_ptr;
        variable success : boolean;
        variable array_index : integer;
        variable array_value : unsigned(machine_value_width - 1 downto 0);
        variable value_std_logic_vector : std_logic_vector(machine_value_width - 1 downto 0);
        variable tmp_std_line_print : line;
        variable stm_array : stm_array_ptr;
    begin
        assert var_element_num <= vars.last_element_num
        report "dump  var element, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        write(std_line, string'("Hello, world!"));
        print("-----------------------------------------------------------------");
        print("---- var name: " & vars_element_ptrs(var_element_num).name);
        print("---- var element num: " & to_text_field(var_element_num));
        print("---- var_value: 0x" & to_text_field_hex(vars_element_ptrs(var_element_num).values(0)));
        print("---- var_org_value: 0x" & to_text_field_hex(vars_element_ptrs(var_element_num).values_org(0)));
        if vars_element_ptrs(var_element_num).typ = STM_VALUE then
            print("---- var type: STM_VALUE");
        elsif vars_element_ptrs(var_element_num).typ = STM_CONST_VALUE then
            print("---- var type: STM_CONST_VALUE");
        elsif vars_element_ptrs(var_element_num).typ = STM_CONST_VALUE then
            print("---- var type: STM_CONST_VALUE");
        elsif vars_element_ptrs(var_element_num).typ = STM_TEXT then
            print("---- var type: STM_TEXT");
            txt_to_string(ptr.var_stm_text, tmp_str);
            print("---- var_txt: "& vars_element_ptrs(var_element_num).txt_enclosing_quote & vars_element_ptrs(var_element_num).txt & vars_element_ptrs(var_element_num).txt_enclosing_quote);
        elsif vars_element_ptrs(var_element_num).typ = STM_ARRAY then
            print("---- var_stm_type: STM_ARRAY");
            stm_array := vars_element_ptrs(var_element_num).arr;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := ptr.var_stm_array(array_index);
                print("-------- index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
            end loop;
            stm_array := vars_element_ptrs(var_element_num).arr_org;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := ptr.var_stm_array(array_index);
                print("-------- org index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
            end loop;
        elsif vars_element_ptrs(var_element_num).typ = STM_LINES then
            print("---- var_stm_type: STM_LINES");
            assert vars_element_ptrs(var_element_num).lines /= null
            report " dump  var element, stm_lines_ptr pointer is null "
            severity failure;
            print("-------- stm_lines.size: " & to_text_field(vars_element_ptrs(var_element_num).lines.size));
            stm_line_ptr := vars_element_ptrs(var_element_num).lines.line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_line_ptr.line_number: " & to_text_field(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = STM_LINE_TEXT then
                    print("-------- stm_line_ptr.line_type: STM_LINE_TEXT");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);
                elsif stm_line_ptr.line_type = STM_LINE_ARRAY then
                    print("-------- stm_line_ptr.line_type: STM_LINE_ARRAY");
                    success := true;
                    print("-------- stm_line_ptr.line_content'length before reading: " & to_text_field(stm_line_ptr.line_content'length));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_line_ptr.line_content'length after reading: " & to_text_field(stm_line_ptr.line_content'length));
                end if;
                stm_line_ptr := stm_line_ptr.nexstm_line;
            end loop;
            stm_line_ptr := vars_element_ptrs(var_element_num).lines_org.line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_org_lines.line_number: " & to_text_field(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = STM_LINE_TEXT then
                    print("-------- stm_org_lines.line_type: STM_LINE_TEXT");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);
                elsif stm_line_ptr.line_type = STM_LINE_ARRAY then
                    print("-------- stm_org_lines.line_type: STM_LINE_ARRAY");
                    success := true;
                    print("-------- stm_org_lines.line_content'length before reading: " & to_text_field(stm_line_ptr.line_content'length));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_org_lines.line_content'length after reading: " & to_text_field(stm_line_ptr.line_content'length));
                end if;
                stm_line_ptr := stm_line_ptr.nexstm_line;
            end loop;
        elsif vars_element_ptrs(var_element_num).typ = STM_BUS then
            print("---- var_stm_type: STM_BUS");
        elsif vars_element_ptrs(var_element_num).typ = STM_SIGNAL then
            print("---- var_stm_type: STM_SIGNAL");
        elsif vars_element_ptrs(var_element_num).typ = STM_LABEL then
            if vars_element_ptrs(var_element_num).label_proc_ref /= null then
                text_field_ptr_to_text_field(ptr.var_label, tmp_label);
                print("---- var_label_proc_ref: " & tmp_label);
            else
                print("---- var_label_proc_ref: missing");
            end if;
            if vars_element_ptrs(var_element_num).label_proc_ref_org /= null then
                text_field_ptr_to_text_field(ptr.label_proc_ref_org, tmp_label);
                print("---- var_label_proc_ref_org: " & tmp_label);
            else
                print("---- var_label_proc_ref_org: missing");
            end if;
            print("---- var_stm_type: STM_LABEL");
        elsif vars_element_ptrs(var_element_num).typ = NO_VAR then
            print("---- var_stm_type: NO_VAR");
        end if;
    end procedure;
    
    procedure print_file_def_element(
        variable files : in file_def_list;
        variable file_element_num : in integer
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "print file definition, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        print(".... -----------------------------------------------------------------");
        print(".... file def is ");
        print(".... file element num: " & integer'image(file_element_num));
        print(".... file name: " & files.element_ptrs(file_element_num).absolute_file_name);
    end procedure;
    
    procedure dump_file_defs(
        variable files : in file_def_list
    ) is
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump file defs start -----------------------------------------");
        for i in 0 to files.last_element_num loop
            print_file_def_element(files, i);
        end loop;
    end procedure;
    
    procedure print_runtime_context(
        variable rc : in t_stm_runtime_context
    ) is
    begin
        print("inst_element_number" & integer'image(rc.inst_element_number));
        case rc.call_process_state is
            when IN_PROC_CONVENTIONAL_BODY =>    
                print("call_process_state IN_PROC_CONVENTIONAL_BODY");
            when IN_PROC_ADVANCED_PARAMS =>    
                print("call_process_state IN_PROC_ADVANCED_PARAMS");
            when IN_PROC_ADVANCED_BODY =>    
                print("call_process_state IN_PROC_ADVANCED_BODY");
            when IN_CALL_ADVANCED_PARAMS =>    
                print("call_process_state IN_CALL_ADVANCED_PARAMS");       
        end case;            
        print("called_proc_name " & rc.called_proc_name);
        print("called_file_line " & integer'image(rc.called_file_line));
        print("called_file_name " & rc.called_file_name);    
        for i in 1 to 6 loop
            print("par 0 scope " & rc.par_scope(i));
        end loop;     
    end procedure;    

end package body;
