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

    procedure file_read_line(file file_name : text;
                             variable file_line : out text_line) is
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

    procedure tokenize_line(variable itext_line : in text_line;
                            variable otokens : out token_text_field_array;
                            variable txt_ptr : out stm_text_ptr;
                            variable txt_enclosing_quote : out character;
                            variable ovalid : out integer) is
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
        variable itokens: unmerged_token_text_field_array;
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

    procedure txt_print_wvar(variable var_list : in var_field_ptr;
                             variable scope : in text_field;
                             variable ptr : in stm_text_ptr;
                             variable txt_enclosing_quote : in character;
                             variable stack_ptr : integer;
                             variable stack_called_files : stack_text_line_array;
                             variable stack_called_file_line_numbers : stack_numbers_array;
                             variable stack_called_procs : stack_text_field_array;
                             constant stm_value_width : in integer) is
        variable stm_text_substituded : stm_text;
    begin
        stm_text_substitude_wvar(var_list, scope, ptr, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_procs, stm_text_substituded, stm_value_width);
        print(stm_text_substituded);
    end procedure;
    
    procedure stm_text_substitude_wvar(variable var_list : in var_field_ptr;
                                       variable scope : in text_field; 
                                       variable ptr : in stm_text_ptr;
                                       variable txt_enclosing_quote : in character;
                                       variable stack_ptr : integer;
                                       variable stack_called_files : stack_text_line_array;
                                       variable stack_called_file_line_numbers : stack_numbers_array;
                                       variable stack_called_procs : stack_text_field_array;
                                       variable stm_text_substituded : out stm_text;
                                       constant stm_value_width : in integer) is
        variable src_i : integer;
        variable src_tail_i : integer;
        variable dest_i : integer;
        variable f_src_i : integer;
        variable f_dest_i : integer;
        variable f_dest_txt_str : stm_text;
        variable k : integer;
        variable src_tail_begin : integer;
        variable dest_txt_str : stm_text;
        variable v1 : unsigned(stm_value_width - 1 downto 0);
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
                access_variable(var_list, scope, tmp_field, v1_index, v1, valid);
                assert valid /= 0
                report lf & "invalid variable found in stm_text_ptr: ignoring."
                severity warning;
                if valid /= 0 then
                    dest_txt_str := ew_str_cat(dest_txt_str, ew_to_str(v1, format));
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
                stack_called_file_line_number := stack_called_file_line_numbers(stack_ptr - previous_level);
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_str(stack_called_file_line_number, dec));
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

    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field; 
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value : out integer;
                              variable valid : out integer;
                              constant stm_value_width : in integer) is
        variable stmvalue : unsigned(stm_value_width - 1 downto 0) := to_unsigned(0, stm_value_width);
    begin
        access_variable(var_list, var_scope, var_name, var_index, stmvalue, valid);
        var_value := to_integer(stmvalue(30 downto 0));
    end procedure;

    procedure access_variable(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value : out unsigned;
                              variable valid : out integer) is
                              
        variable var_ptr : var_field_ptr;
        variable is_defined : boolean := false;
    begin
        valid := 0;
        -- if the variable is a special
        if var_name(1) = '=' then
            var_value := to_unsigned(0, var_value'length);
            valid := 1;
        elsif var_name(1 to 2) = ">=" then
            var_value := to_unsigned(4, var_value'length);
            valid := 1;
        elsif var_name(1 to 2) = "<=" then
            var_value := to_unsigned(5, var_value'length);
            valid := 1;
        elsif var_name(1) = '>' then
            var_value := to_unsigned(1, var_value'length);
            valid := 1;
        elsif var_name(1) = '<' then
            var_value := to_unsigned(2, var_value'length);
            valid := 1;
        elsif var_name(1 to 2) = "!=" then
            var_value := to_unsigned(3, var_value'length);
            valid := 1;
        else
            assert var_list /= null
            report lf & "no variables are defined." & lf
            severity failure;
            if fld_len(var_scope) > 0 then
                var_ptr := var_list;
                while var_ptr.next_rec /= null loop
                    -- check for a local match
                    if fld_equal(var_name, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                        var_index := var_ptr.var_index;
                        var_value := var_ptr.var_value(0);
                        valid := 1;
                        is_defined := true;
                        exit;
                    end if;
                    var_ptr := var_ptr.next_rec;
                end loop;
                if not is_defined then
                    var_ptr := var_list;
                    while var_ptr.next_rec /= null loop
                        -- check for a global match
                        if fld_equal(var_name, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                            var_index := var_ptr.var_index;
                            var_value := var_ptr.var_value(0);
                            valid := 1;
                            is_defined := true;
                            exit;
                        end if;
                        var_ptr := var_ptr.next_rec;
                    end loop;
                end if;  
            else
                var_ptr := var_list;
                while var_ptr.next_rec /= null loop
                    -- check for a global match
                    if fld_equal(var_name, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_value := var_ptr.var_value(0);
                        valid := 1;
                        is_defined := true;
                        exit;
                    end if;
                    var_ptr := var_ptr.next_rec;
                end loop;                          
            end if;
            
            if fld_len(var_scope) > 0 then
                if var_ptr.next_rec = null then
                    -- check for a local match in the last record
                    if fld_equal(var_name, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                        var_index := var_ptr.var_index;
                        var_value := var_ptr.var_value(0);
                        valid := 1;
                        is_defined := true;
                    end if;
                    if not is_defined then
                        -- check for a global match in the last record
                        if fld_equal(var_name, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                            var_index := var_ptr.var_index;
                            var_value := var_ptr.var_value(0);
                            valid := 1;
                            is_defined := true;
                        end if;  
                    end if;
                end if;
            else
                if var_ptr.next_rec = null then
                    -- check for a global match in the last record
                    if fld_equal(var_name, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_value := var_ptr.var_value(0);
                        valid := 1;
                        is_defined := true;
                    end if;
                    var_ptr := var_ptr.next_rec;
                end if;                          
            end if;                                         
            assert is_defined
            report lf & "variable is not defined " & var_name & lf
            severity error;
        end if;
    end procedure;
    
    procedure access_variable_value_ptr(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_value_ptr : out t_stm_value_ptr;
                              variable valid : out integer) is
                              
        variable var_ptr : var_field_ptr;
        variable temp_field : text_field;
        variable is_defined : boolean := false;
    begin
        valid := 0;
        temp_field := var_name;
        assert var_list /= null
        report lf & "no variables are defined." & lf
        severity failure;
        if fld_len(var_scope) > 0 then
            var_ptr := var_list;
            while var_ptr.next_rec /= null loop
                -- check for a local match
                if fld_equal(temp_field, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                    var_index := var_ptr.var_index;
                    var_value_ptr := var_ptr.var_value;
                    valid := 1;
                    is_defined := true;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;
            if not is_defined then
                var_ptr := var_list;
                while var_ptr.next_rec /= null loop
                    -- check for a global match
                    if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_value_ptr := var_ptr.var_value;
                        valid := 2;
                        is_defined := true;
                        exit;
                    end if;
                    var_ptr := var_ptr.next_rec;
                end loop;
            end if;  
        else
            var_ptr := var_list;
            while var_ptr.next_rec /= null loop
                -- check for a global match
                if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                    var_index := var_ptr.var_index;
                    var_value_ptr := var_ptr.var_value;
                    valid := 2;
                    is_defined := true;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;                          
        end if;
        
        if fld_len(var_scope) > 0 then
            if var_ptr.next_rec = null then
                -- check for a local match in the last record
                if fld_equal(temp_field, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                    var_index := var_ptr.var_index;
                    var_value_ptr := var_ptr.var_value;
                    valid := 1;
                    is_defined := true;
                end if;
                if not is_defined then
                    -- check for a global match in the last record
                    if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_value_ptr := var_ptr.var_value;
                        valid := 2;
                        is_defined := true;
                    end if;  
                end if;
            end if;
        else
            if var_ptr.next_rec = null then
                -- check for a global match in the last record
                if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                    var_index := var_ptr.var_index;
                    var_value_ptr := var_ptr.var_value;
                    valid := 2;
                    is_defined := true;
                end if;
                var_ptr := var_ptr.next_rec;
            end if;                          
        end if;                                         
        assert is_defined
        report lf & "variable is not defined " & temp_field & lf
        severity error;

    end procedure;
    
    procedure access_variable_label_ptr(variable var_list : in var_field_ptr;
                              variable var_scope : in text_field;
                              variable var_name : in text_field;
                              variable var_index : out integer;
                              variable var_label_ptr : out text_field_ptr;
                              variable valid : out integer) is
                              
        variable var_ptr : var_field_ptr;
        variable temp_field : text_field;
        variable is_defined : boolean := false;
    begin
        valid := 0;
        temp_field := var_name;
        assert var_list /= null
        report lf & "no variables are defined." & lf
        severity failure;
        if fld_len(var_scope) > 0 then
            var_ptr := var_list;
            while var_ptr.next_rec /= null loop
                -- check for a local match
                if fld_equal(temp_field, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                    var_index := var_ptr.var_index;
                    var_label_ptr := var_ptr.var_label;
                    valid := 1;
                    is_defined := true;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;
            if not is_defined then
                var_ptr := var_list;
                while var_ptr.next_rec /= null loop
                    -- check for a global match
                    if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_label_ptr := var_ptr.var_label;
                        valid := 2;
                        is_defined := true;
                        exit;
                    end if;
                    var_ptr := var_ptr.next_rec;
                end loop;
            end if;  
        else
            var_ptr := var_list;
            while var_ptr.next_rec /= null loop
                -- check for a global match
                if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                    var_index := var_ptr.var_index;
                    var_label_ptr := var_ptr.var_label;
                    valid := 2;
                    is_defined := true;
                    exit;
                end if;
                var_ptr := var_ptr.next_rec;
            end loop;                          
        end if;
        
        if fld_len(var_scope) > 0 then
            if var_ptr.next_rec = null then
                -- check for a local match in the last record
                if fld_equal(temp_field, var_ptr.var_name) and fld_equal(var_scope, var_ptr.var_scope) then
                    var_index := var_ptr.var_index;
                    var_label_ptr := var_ptr.var_label;
                    valid := 1;
                    is_defined := true;
                end if;
                if not is_defined then
                    -- check for a global match in the last record
                    if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                        var_index := var_ptr.var_index;
                        var_label_ptr := var_ptr.var_label;
                        valid := 2;
                        is_defined := true;
                    end if;  
                end if;
            end if;
        else
            if var_ptr.next_rec = null then
                -- check for a global match in the last record
                if fld_equal(temp_field, var_ptr.var_name) and fld_len(var_ptr.var_scope) = 0 then
                    var_index := var_ptr.var_index;
                    var_label_ptr := var_ptr.var_label;
                    valid := 2;
                    is_defined := true;
                end if;
                var_ptr := var_ptr.next_rec;
            end if;                          
        end if;                                         
        assert is_defined
        report lf & "variable is not defined " & temp_field & lf
        severity error;

    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value : out unsigned;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            value := ptr.var_value(0);
            valid := 1;
        end if;
    end procedure;
    
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value : out unsigned;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            ptr.var_value := ptr.var_org_value;
            value := ptr.var_value(0);
            valid := 1;
        end if;
    end procedure;
    
    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_label : out text_field_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                stm_label := ptr.var_label;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            stm_label := ptr.var_label;
            valid := 1;
        end if;
    end procedure;
    
     procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_label : out text_field_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            ptr.var_label := ptr.var_org_label;
            stm_label := ptr.var_label;
            valid := 1;
        end if;
    end procedure;
   
    procedure index_variable_value_ptr(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable value_ptr : out t_stm_value_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            value_ptr := ptr.var_value;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            var_stm_text := ptr.var_stm_text;
            var_stm_text_enclosing_quote := ptr.var_stm_text_enclosing_quote;
            valid := 1;
        end if;
    end procedure;
    
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable var_stm_text : out stm_text_ptr;
                             variable var_stm_text_enclosing_quote : out character;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            var_stm_text := ptr.var_org_stm_text;
            var_stm_text_enclosing_quote := ptr.var_org_stm_text_enclosing_quote;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                stm_array := ptr.var_stm_array;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            stm_array := ptr.var_stm_array;
            valid := 1;
        end if;
    end procedure;
    
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_array : out t_stm_array_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            ptr.var_stm_array := ptr.var_org_stm_array;
            stm_array := ptr.var_stm_array;
            valid := 1;
        end if;
    end procedure;

    procedure index_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                stm_lines := ptr.var_stm_lines;
                valid := 1;
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            stm_lines := ptr.var_stm_lines;
            valid := 1;
        end if;
    end procedure;
    
    procedure index_and_reinit_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             variable var_scope : out text_field;
                             variable stm_lines : out t_stm_lines_ptr;
                             variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            var_scope := ptr.var_scope;
            ptr.var_stm_lines := ptr.var_org_stm_lines;
            stm_lines := ptr.var_stm_lines;
            valid := 1;
        end if;
    end procedure;



    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in unsigned;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_value(0) := value;
            valid := 1;
        end if;
    end procedure;
    
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value : in unsigned;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_value := ptr.var_org_value;
            ptr.var_value(0) := value;
            valid := 1;
        end if;
    end procedure;
   
    procedure update_variable_value_ptr(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable value_ptr : in t_stm_value_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE) then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_value := value_ptr;
            valid := 1;
        end if;
    end procedure;
    
    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            ptr.var_stm_text := var_stm_text;
            valid := 1;
        end if;
    end procedure;
    
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable var_stm_text : in stm_text_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
                ptr.var_stm_text := ptr.var_org_stm_text;
                ptr.var_stm_text_enclosing_quote := ptr.var_org_stm_text_enclosing_quote;
                ptr.var_stm_text := var_stm_text;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_stm_array := stm_array;
            valid := 1;
        end if;
    end procedure;
    
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_array : in t_stm_array_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index and ptr.var_stm_type /= STM_CONST_VALUE_TYPE then
            ptr.var_stm_array := ptr.var_org_stm_array;
            ptr.var_stm_array := stm_array;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index) then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            ptr.var_stm_lines := stm_lines;
            valid := 1;
        end if;
    end procedure;
    
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_lines : in t_stm_lines_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if (ptr.var_index = index) then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        if ptr.var_index = index then
            ptr.var_stm_lines := ptr.var_org_stm_lines;
            ptr.var_stm_lines := stm_lines;
            valid := 1;
        end if;
    end procedure;

    procedure update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index then
            ptr.var_label := stm_label;
            valid := 1;
        end if;
    end procedure;
    
    procedure reinit_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index then
            ptr.var_label := ptr.var_org_label;
            ptr.var_label := stm_label;
            valid := 1;
        end if;
    end procedure;
    
    procedure init_and_update_variable(variable var_list : in var_field_ptr;
                              variable index : in integer;
                              variable stm_label : in text_field_ptr;
                              variable valid : out integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        valid := 0;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- check the current one
        if ptr.var_index = index then
            ptr.var_org_label := stm_label;
            ptr.var_label := stm_label;
            valid := 1;
        end if;
    end procedure;
    
    procedure print_file_def(file_list : inout file_def_ptr; index : in integer) is
        variable tmp_file_def_ptr : file_def_ptr;
    begin
        tmp_file_def_ptr := file_list;
        while tmp_file_def_ptr.next_rec /= null loop
            if tmp_file_def_ptr.rec_idx = index then
                exit;
            else
                tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
            end if;
        end loop;
        print(".... -----------------------------------------------------------------");
        print(".... file_def is ");
        print(".... index: " & to_str(tmp_file_def_ptr.rec_idx));
        print(".... name: " & tmp_file_def_ptr.file_name);
    end procedure;
    
    procedure print_inst_element_number(
        variable inst_list : in stim_line_ptr; 
        element_number : in integer; 
        file_list : inout file_def_ptr
    ) is
        variable inst_ptr : stim_line_ptr;
    begin
        inst_ptr := inst_list;
        while inst_ptr.next_rec /= null loop
            if inst_ptr.element_number = element_number then
                print_inst_ptr(inst_ptr, file_list);
                exit;
            else
                inst_ptr := inst_ptr.next_rec;
            end if;
        end loop;
    end procedure;
    
    procedure print_inst_ptr(
        variable inst_ptr : in stim_line_ptr; 
        file_list : inout file_def_ptr
    ) is
        variable tmp_txt : stm_text;
        variable fn : text_line;
        variable pl : integer;
    begin
        print(".... -----------------------------------------------------------------");
        print(".... instruction is " & inst_ptr.inst);
        print(".... internal list element number: " & to_str(inst_ptr.element_number));
        print(".... instruction file linenumber: " & to_str(inst_ptr.file_line));
        print(".... instruction file idx: " & to_str(inst_ptr.file_idx));
        get_instruction_file_name(file_list, inst_ptr.file_idx, fn);
        print(".... instruction file name: " & fn);
        for i in 1 to 6 loop
            pl := fld_len(inst_ptr.parameters(i));
            if pl > 0 then
                print(".... par " & to_str(i) & " text" & inst_ptr.parameters(i)(1 to pl));
            end if; 
        end loop;
        txt_to_string(inst_ptr.txt, tmp_txt);
        print(".... text: " & tmp_txt);
    end procedure;
    
--    procedure print_access_inst(
--        variable inst_ptr : in stim_line_ptr; 
--        file_list : inout file_def_ptr
--    ) is
--        variable tmp_txt : stm_text;
--        variable fn : text_line;
--    begin
--        print(".... -----------------------------------------------------------------");
--        print(".... instruction is " & inst_ptr.inst);
--        print(".... internal list element number: " & to_str(inst_ptr.element_number));
--        print(".... instruction file linenumber: " & to_str(inst_ptr.file_line));
--        print(".... instruction file idx: " & to_str(inst_ptr.file_idx));
--        get_instruction_file_name(file_list, inst_ptr.file_idx, fn);
--        print(".... instruction file name: " & fn);
--        for i in 1 to 6 loop
--            print(".... par" & to_str(inst_ptr.parameters(i).var_index) & " text: " & inst_ptr.inst_parameters(i));
--            if inst_ptr.parameters(i).var_index >= 0 then
--                print(".... index a proc var with var list element number: " & to_str(var_index(1)));
--                dump_variable(var_list, inst_ptr.parameters(i).var_index, machine_value_width);
--            else
--                print(".... par" & to_str(var_index(i)) & " value 0x: " & to_str_hex(par_values(1)));
--                print(".... par" & to_str(var_index(i)) & " value : " & to_str(par_values(1)));
--            end if; 
--        end loop;
--        txt_to_string(inst_ptr.txt, tmp_txt);
--        print(".... text: " & tmp_txt);
--    end procedure;
    
    procedure dump_inst_list(
        variable inst_list : in stim_line_ptr; 
        file_list : inout file_def_ptr
    ) is
        variable inst_ptr : stim_line_ptr;
    begin
        inst_ptr := inst_list;
        print("++++ --dump_inst_list-----------------------------------------------------");
        while inst_ptr.next_rec /= null loop
            print_inst_ptr(inst_ptr, file_list);
            inst_ptr := inst_ptr.next_rec;
        end loop;
        -- get the last one
        print_inst_ptr(inst_ptr, file_list);
    end procedure;

    procedure dump_variables(variable var_list : in var_field_ptr;
                             constant stm_value_width : in integer) is
        variable ptr : var_field_ptr;
    begin
        ptr := var_list;
        print("---- -----------------------------------------------------------------");
        print("---- -- dump variables start -----------------------------------------");
        while ptr.next_rec /= null loop
            dump_var_field(ptr, stm_value_width);
            ptr := ptr.next_rec;
        end loop;
        -- the last one
        dump_var_field(ptr, stm_value_width);
    end procedure;
    
    procedure dump_variable(variable var_list : in var_field_ptr;
                             variable index : in integer;
                             constant stm_value_width : in integer) is
        variable ptr : var_field_ptr;
        variable found : boolean;
    begin
        ptr := var_list;
        found := false;
        while ptr.next_rec /= null loop
            if ptr.var_index = index then
                dump_var_field(ptr, stm_value_width);
                found := true; 
                exit;
            end if;
            ptr := ptr.next_rec;
        end loop;
        -- the last one
        if not found then
            if ptr.var_index = index then
                dump_var_field(ptr, stm_value_width);
            end if;
        end if;
    end procedure;

    procedure dump_file_defs(file_list : inout file_def_ptr) is
        variable tmp_file_def_ptr : file_def_ptr;
        variable index : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump file defs start -----------------------------------------");
        index := 0;
        tmp_file_def_ptr := file_list;
        while tmp_file_def_ptr.next_rec /= null loop
            print_file_def(file_list, index);
            tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
            index := index + 1;
        end loop;
        -- the last one
        print_file_def(file_list, index);
    end procedure;

    procedure dump_var_field(variable ptr : var_field_ptr;
                             constant stm_value_width : in integer) is
        variable std_line : line;
        variable tmp_label : text_field;
        variable tmp_str : stm_text;
        variable tmp_str_ptr : stm_text_ptr;
        variable stm_line_ptr : t_stm_line_ptr;
        variable success : boolean;
        variable array_index : integer;
        variable array_value : unsigned(stm_value_width - 1 downto 0);
        variable value_std_logic_vector : std_logic_vector(stm_value_width - 1 downto 0);
        variable tmp_std_line_print : line;
        variable stm_array : t_stm_array_ptr;
    begin
        write(std_line, string'("Hello, world!"));
        print("-----------------------------------------------------------------");
        print("---- var_name: " & ptr.var_name);
        print("---- var_scope: " & ptr.var_scope);
        print("---- var_index: " & to_str(ptr.var_index));
        print("---- var_value: 0x" & to_str_hex(ptr.var_value(0)));
        print("---- var_org_value: 0x" & to_str_hex(ptr.var_org_value(0)));
        if ptr.var_stm_type = STM_VALUE_TYPE then
            print("---- var_stm_type: STM_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_CONST_VALUE_TYPE then
            print("---- var_stm_type: STM_CONST_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_CONST_VALUE_TYPE then
            print("---- var_stm_type: STM_CONST_VALUE_TYPE");
        elsif ptr.var_stm_type = STM_TEXT_TYPE then
            print("---- var_stm_type: STM_TEXT_TYPE");
            txt_to_string(ptr.var_stm_text, tmp_str);
            print("---- var_stm_text: " & tmp_str);
            print("---- var_stm_text_enclosing_quote: " & ptr.var_stm_text_enclosing_quote);
        elsif ptr.var_stm_type = STM_ARRAY_TYPE then
            print("---- var_stm_type: STM_ARRAY_TYPE");
            stm_array := ptr.var_stm_array;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := ptr.var_stm_array(array_index);
                print("-------- index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
            end loop;
            stm_array := ptr.var_org_stm_array;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := ptr.var_stm_array(array_index);
                print("-------- org index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
            end loop;
        elsif ptr.var_stm_type = STM_LINES_TYPE then
            print("---- var_stm_type: STM_LINES_TYPE");
            assert ptr.var_stm_lines /= null
            report " stm_lines_ptr pointer is null "
            severity failure;
            print("-------- stm_lines.size: " & to_str(ptr.var_stm_lines.size));
            stm_line_ptr := ptr.var_stm_lines.stm_line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_line_ptr.line_number: " & to_str(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = STM_LINE_TEXT_TYPE then
                    print("-------- stm_line_ptr.line_type: STM_LINE_TEXT_TYPE");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);                    
                elsif stm_line_ptr.line_type = STM_LINE_ARRAY_TYPE then
                    print("-------- stm_line_ptr.line_type: STM_LINE_ARRAY_TYPE");
                    success := true;
                    print("-------- stm_line_ptr.line_content'length before reading: " & to_str(stm_line_ptr.line_content'length));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_line_ptr.line_content'length after reading: " & to_str(stm_line_ptr.line_content'length));
                end if;
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
            stm_line_ptr := ptr.var_org_stm_lines.stm_line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_org_lines.line_number: " & to_str(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = STM_LINE_TEXT_TYPE then
                    print("-------- stm_org_lines.line_type: STM_LINE_TEXT_TYPE");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);                    
                elsif stm_line_ptr.line_type = STM_LINE_ARRAY_TYPE then
                    print("-------- stm_org_lines.line_type: STM_LINE_ARRAY_TYPE");
                    success := true;
                    print("-------- stm_org_lines.line_content'length before reading: " & to_str(stm_line_ptr.line_content'length));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index: " & to_str(array_index) & ", value: " & to_str_hex(array_value));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_org_lines.line_content'length after reading: " & to_str(stm_line_ptr.line_content'length));
                end if;
                stm_line_ptr := stm_line_ptr.next_stm_line;
            end loop;
        elsif ptr.var_stm_type = STM_BUS_TYPE then
            print("---- var_stm_type: STM_BUS_TYPE");
        elsif ptr.var_stm_type = STM_SIGNAL_TYPE then
            print("---- var_stm_type: STM_SIGNAL_TYPE");
        elsif ptr.var_stm_type = STM_LABEL_TYPE then
            if ptr.var_label /= null then
                text_field_ptr_to_text_field(ptr.var_label, tmp_label); 
                print("---- var_label: " & tmp_label);
            else
                print("---- var_label: missing");
            end if;
            if ptr.var_org_label /= null then
                text_field_ptr_to_text_field(ptr.var_org_label, tmp_label);
                print("---- var_org_label: " & tmp_label);
            else
                print("---- var_org_label: missing");
            end if;
            print("---- var_stm_type: STM_LABEL_TYPE");
        elsif ptr.var_stm_type = NO_VAR_TYPE then
            print("---- var_stm_type: NO_VAR_TYPE");
        end if;
    end procedure;

end package body;
