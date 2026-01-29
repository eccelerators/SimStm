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
        variable slc : src_locator;
        variable insts : inst_sequence;
        variable vars : in var_pool_ordered;
        variable rcs : stm_array_of_runtime_context;
        variable txt_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable sp : integer;
        constant machine_value_width : in integer
    ) is
        variable stm_text_substituded : stm_text;
    begin
        stm_text_substitude_wvar(slc, insts, vars, rcs, txt_ptr, txt_enclosing_quote, sp, stm_text_substituded, machine_value_width);
        print(stm_text_substituded);
    end procedure;

    procedure stm_text_substitude_wvar(
        variable slc : src_locator;
        variable insts : inst_sequence;
        variable vars : in var_pool_ordered;
        variable rcs : stm_array_of_runtime_context;
        variable txt_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable sp : integer;    
        variable stm_text_substituded : out stm_text;
        constant machine_value_width : in integer
    ) is
        variable ven : integer;
        variable cien : integer;
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
        variable insert_call_stack_file_name : boolean;
        variable insert_call_stack_file_line : boolean;
        variable stack_called_file_name : text_field;
        variable stack_called_file_line : integer;
        variable stack_called_proc : text_field;

    begin
        if txt_ptr = null then
            return;
        end if;
        txt_to_string(txt_ptr, input_txt);
        -- determine variables tail_start in src string
        src_i := 1;
        src_tail_begin := 0;
        while src_i <= c_stm_text_len loop
            if src_i > 1 then
                if txt_ptr(src_i - 1) = '\' and txt_ptr(src_i) = txt_enclosing_quote then
                    src_i := src_i + 1;
                else
                    if txt_ptr(src_i) = txt_enclosing_quote then
                        src_tail_begin := src_i;
                        exit;
                    end if;
                    src_i := src_i + 1;
                end if;
            else
                if txt_ptr(src_i) = txt_enclosing_quote then
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
                if txt_ptr(src_i) = '\' and txt_ptr(src_i + 1) = txt_enclosing_quote then
                    src_i := src_i + 1;
                end if;
            end if;

            -- copy until next '{'
            while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                if txt_ptr(src_i) = '{' then
                    exit;
                else
                    dest_txt_str(dest_i) := txt_ptr(src_i);
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
            insert_call_stack_file_name := false;
            insert_call_stack_file_line := false;
            if txt_ptr(src_i) = '{' then
                src_i := src_i + 1;
                format := hex;
                insert_var := true;
                while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                    if txt_ptr(src_i) = '}' then
                        -- default insert variable hex
                        exit;
                    else
                        -- skip until next '}'
                        if txt_ptr(src_i) = ':' then
                            -- insert variable decimal, binary or octal
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if txt_ptr(src_i) = 'd' then
                                format := dec;
                            elsif txt_ptr(src_i) = 'b' then
                                format := bin;
                            elsif txt_ptr(src_i) = 'o' then
                                format := oct;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        elsif txt_ptr(src_i) = '@' then
                            insert_var := false;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if txt_ptr(src_i) = 'c' then
                                insert_call_stack_label := true;
                            elsif txt_ptr(src_i) = 'f' then
                                insert_call_stack_file_name := true;
                            elsif txt_ptr(src_i) = 'l' then
                                insert_call_stack_file_line := true;
                            else
                                assert (false)
                                report lf & "wrong substitution format in {...} brackets " & stm_text_crop(input_txt)
                                severity failure;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            previous_level := c2int(txt_ptr(src_i));
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
            if txt_ptr(src_i) = '}' then
                src_i := src_i + 1;
            else
                assert (false)
                report lf & "missing closing } bracket " & stm_text_crop(input_txt)
                severity failure;
            end if;

            if insert_var then
                while src_tail_i <= c_stm_text_len loop
                    if is_txt_var_first_character(txt_ptr(src_tail_i)) then
                        exit;
                    else
                        src_tail_i := src_tail_i + 1;
                    end if;
                end loop;
                assert is_txt_var_first_character(txt_ptr(src_tail_i))
                report lf & "missing variable for substitution bracket " & stm_text_crop(input_txt)
                severity failure;
                tmp_field := (others => nul);
                tmp_i := 1;
                tmp_field(tmp_i) := txt_ptr(src_tail_i);
                src_tail_i := src_tail_i + 1;
                tmp_i := tmp_i + 1;
                -- parse to the next space
                while txt_ptr(src_tail_i) /= ' ' and txt_ptr(src_tail_i) /= nul and txt_ptr(src_tail_i) /=  ht loop
                    tmp_field(tmp_i) := txt_ptr(src_tail_i);
                    src_tail_i := src_tail_i + 1;
                    tmp_i := tmp_i + 1;
                end loop;
                access_var(slc, vars, tmp_field, ven);
                v1 := vars.element_ptrs(ven).values(0);
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(v1, format));
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;

            elsif insert_call_stack_file_name then
                cien := rcs(sp - previous_level).ien_of_called_proc;
                stack_called_file_name := insts.element_ptrs(cien).slc.file_name;
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_file_name);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_file_line then
                cien := rcs(sp - previous_level).ien_of_called_proc;
                stack_called_file_line := insts.element_ptrs(cien).slc.file_line;
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(stack_called_file_line, dec));
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_label then
                cien := rcs(sp - previous_level).ien_of_called_proc;
                stack_called_proc := insts.element_ptrs(cien).inst_args.par_text_fields(1);
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_proc);
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
        variable vars : in var_pool_ordered;
        variable par_text_fields : in parameter_text_field_array;
        variable par_scopes : in parameter_text_field_array;
        variable par_indexes : out parameter_index_array;
        variable par_values : out parameter_value_array;
        constant machine_value_width : in integer
    ) is
        variable ptf : parameter_text_field_array;
        variable ven : integer;
    begin
        for i in 1 to 6 loop
            if par_text_fields(i)(1) /= nul then
                if is_digit(par_text_fields(i)(1)) then
                    par_values(i) := stim_to_stm_value(ie.slc, ie.inst_args.par_text_fields(i), machine_value_width);
                else
                    for i in 1 to 6 loop
                        ptf(i) := textfield_dot_cat(par_text_fields(i),par_scopes(i));
                    end loop;
                    access_var(ie.slc, vars, ptf(i), ven);
                    par_indexes(i) := ven;
                    par_values(i) := vars.element_ptrs(ven).values(0);
                end if;
            end if;
        end loop;
    end procedure;
    
    procedure access_proc(
        variable slc : src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_element_num : out integer
    ) is
        variable pen : integer;
    begin
        search_proc_element_number(slc, procs, proc_name, pen);
        assert pen >= 0
        report "access proc, couldn't find proc" & proc_name & lf &
               "file " & slc.file_name & lf &
               "line" & integer'image(slc.file_line)
        severity failure;
        proc_element_num := pen;
    end procedure;
    
    procedure access_var(
        variable slc : src_locator;
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable var_element_num : out integer
    ) is
        variable ven : integer;
    begin
        search_var_element_number(slc, vars, var_name, ven);
        assert ven >= 0
        report "access var, couldn't find var" & var_name & lf &
               "file " & slc.file_name & lf &
               "line" & integer'image(slc.file_line)
        severity failure;
        var_element_num := ven;
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
        value := vars.element_ptrs(var_element_num).values(0);
    end procedure;

    procedure index_and_reinit_var(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable value : out unsigned
    ) is
    begin
        vars.element_ptrs(var_element_num).values := vars.element_ptrs(var_element_num).values_org;
        value := vars.element_ptrs(var_element_num).values(0);
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
        value_ptr := vars.element_ptrs(var_element_num).values;
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
        variable var_lines : out stm_lines_ptr
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
        variable pl : integer;
        variable eq : character;
        variable txt : stm_text;
    begin
        assert inst_element_num <= insts.last_element_num
        report "print instruction element, inst element number, " & integer'image(inst_element_num) & "greater than insts last element number & integer'image(inst.last_element_num)" 
        severity failure;
        print(".... -----------------------------------------------------------------");
        print(".... instruction " & insts.element_ptrs(inst_element_num).inst);
        print(".... instruction element number: " & to_text_field(inst_element_num));
        print(".... instruction file name: " & insts.element_ptrs(inst_element_num).slc.file_name);
        print(".... instruction file linenumber: " & to_text_field(insts.element_ptrs(inst_element_num).slc.file_line));              
        for i in 1 to 6 loop
            pl := fld_len(insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
            if pl > 0 then
                print(".... par" & integer'image(i) & insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
            end if;
        end loop;
        txt_to_string(insts.element_ptrs(inst_element_num).inst_args.txt, txt);
        eq := insts.element_ptrs(inst_element_num).inst_args.txt_enclosing_quote;
        print(".... text: " & txt);
    end procedure;

    procedure dump_inst_sequence(
        variable insts : in inst_sequence;
        variable code_files : in file_def_list
    ) is
        variable ien : integer;
    begin
        print("++++ --dump_var_pool_ordered-----------------------------------------------------");
        for i in 0 to insts.last_element_num loop
            ien := i;
            print_inst_element(insts, ien, code_files);
        end loop;
    end procedure;

    procedure dump_var_pool_ordered(
        variable vars : in var_pool_ordered;
        constant machine_value_width : in integer
    ) is
        variable ien : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump variables start -----------------------------------------");
        for i in 0 to vars.last_element_num loop
            ien := i;
            dump_var_element(vars, ien, machine_value_width);
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
        variable eq : character;
    begin
        assert var_element_num <= vars.last_element_num
        report "dump  var element, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        write(std_line, string'("Hello, world!"));
        print("-----------------------------------------------------------------");
        print("---- var name: " & vars.element_ptrs(var_element_num).name);
        print("---- var element num: " & to_text_field(var_element_num));
        print("---- var_value: 0x" & to_text_field_hex(vars.element_ptrs(var_element_num).values(0)));
        print("---- var_org_value: 0x" & to_text_field_hex(vars.element_ptrs(var_element_num).values_org(0)));
        if vars.element_ptrs(var_element_num).typ = T_VALUE then
            print("---- var type: T_VALUE");
        elsif vars.element_ptrs(var_element_num).typ = T_CONST then
            print("---- var type: T_CONST");
        elsif vars.element_ptrs(var_element_num).typ = T_VALUE then
            print("---- var type: T_VALUE");
        elsif vars.element_ptrs(var_element_num).typ = T_TEXT then
            print("---- var type: T_TEXT");
            txt_to_string(vars.element_ptrs(var_element_num).txt, tmp_str);
            eq := vars.element_ptrs(var_element_num).txt_enclosing_quote;
            print("---- var_txt: " & eq & tmp_str & eq);
        elsif vars.element_ptrs(var_element_num).typ = T_ARRAY then
            print("---- var_stm_type: T_ARRAY");
            stm_array := vars.element_ptrs(var_element_num).arr;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := stm_array(array_index);
                print("-------- index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
            end loop;
            stm_array := vars.element_ptrs(var_element_num).arr_org;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := stm_array(array_index);
                print("-------- org index: " & to_text_field(array_index) & ", value: " & to_text_field_hex(array_value));
            end loop;
        elsif vars.element_ptrs(var_element_num).typ = T_LINES then
            print("---- var_stm_type: T_LINES");
            assert vars.element_ptrs(var_element_num).lines /= null
            report " dump  var element, stm_lines_ptr pointer is null "
            severity failure;
            print("-------- stm_lines.size: " & to_text_field(vars.element_ptrs(var_element_num).lines.size));
            stm_line_ptr := vars.element_ptrs(var_element_num).lines.line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_line_ptr.line_number: " & to_text_field(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = T_LINE_TEXT then
                    print("-------- stm_line_ptr.line_type: T_LINE_TEXT");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);
                elsif stm_line_ptr.line_type = T_LINE_ARRAY then
                    print("-------- stm_line_ptr.line_type: T_LINE_ARRAY");
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
                stm_line_ptr := stm_line_ptr.next_line_ptr;
            end loop;
            stm_line_ptr := vars.element_ptrs(var_element_num).lines_org.line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_org_lines.line_number: " & to_text_field(stm_line_ptr.line_number));
                if stm_line_ptr.line_type = T_LINE_TEXT then
                    print("-------- stm_org_lines.line_type: T_LINE_TEXT");
                    std_line := stm_line_ptr.line_content;
                    tmp_str_ptr := new stm_text;
                    get_stm_text_ptr_from_line(std_line, tmp_str_ptr);
                    stm_text_ptr_to_line(tmp_str_ptr, std_line);
                    stm_line_ptr.line_content := std_line;
                    txt_print(tmp_str_ptr);
                elsif stm_line_ptr.line_type = T_LINE_ARRAY then
                    print("-------- stm_org_lines.line_type: T_LINE_ARRAY");
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
                stm_line_ptr := stm_line_ptr.next_line_ptr;
            end loop;
        elsif vars.element_ptrs(var_element_num).typ = T_BUS then
            print("---- var_stm_type: T_BUS");
        elsif vars.element_ptrs(var_element_num).typ = T_SIGNAL then
            print("---- var_stm_type: T_SIGNAL");
        elsif vars.element_ptrs(var_element_num).typ = T_LABEL then
            if vars.element_ptrs(var_element_num).label_proc_ref /= null then
                text_field_ptr_to_text_field(vars.element_ptrs(var_element_num).label_proc_ref, tmp_label);
                print("---- var_label_proc_ref: " & tmp_label);
            else
                print("---- var_label_proc_ref: missing");
            end if;
            if vars.element_ptrs(var_element_num).label_proc_ref_org /= null then
                text_field_ptr_to_text_field(vars.element_ptrs(var_element_num).label_proc_ref_org, tmp_label);
                print("---- var_label_proc_ref_org: " & tmp_label);
            else
                print("---- var_label_proc_ref_org: missing");
            end if;
            print("---- var_stm_type: T_LABEL");
        elsif vars.element_ptrs(var_element_num).typ = T_NO_VAR then
            print("---- var_stm_type: T_NO_VAR");
        end if;
    end procedure;
    
    procedure print_file_def_element(
        variable files : in file_def_list;
        variable file_element_num : in integer
    ) is
    begin
        assert file_element_num <= files.last_element_num
        report "print file definition, var element number, " & integer'image(file_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)" 
        severity failure;
        print(".... -----------------------------------------------------------------");
        print(".... file def is ");
        print(".... file element num: " & integer'image(file_element_num));
        print(".... absolute file name: " & files.element_ptrs(file_element_num).absolute_file_name);
        print(".... file name: " & files.element_ptrs(file_element_num).file_name);
    end procedure;
    
    procedure dump_file_defs(
        variable files : in file_def_list
    ) is
        variable fen : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump file defs start -----------------------------------------");
        for i in 0 to files.last_element_num loop
            fen := i;
            print_file_def_element(files, fen);
        end loop;
    end procedure;
    
    procedure print_runtime_context(
        variable rc : in stm_runtime_context
    ) is
    begin       
        case rc.call_process_state is
            when IN_NONE =>    
                print("call_process_state IN_NONE");
            when IN_PROC_PARAMS =>    
                print("call_process_state IN_PROC_PARAMS");
            when IN_PROC_BODY =>    
                print("call_process_state IN_PROC_BODY");
            when IN_CALL_PARAMS =>    
                print("call_process_state IN_CALL_PARAMS");       
        end case;            
        print("ien_of_call " & integer'image(rc.ien_of_call));
        print("ien_of_proc_params_end " & integer'image(rc.ien_of_proc_params_end));
        print("ien_of_called_proc " & integer'image(rc.ien_of_called_proc));    
        for i in 1 to 6 loop
            print("par 0 scope " & rc.par_scopes(i));
        end loop; 
        print("loop_num " & integer'image(rc.loop_num));
        print("loop_if_enter_level " & integer'image(rc.loop_if_enter_level));   
    end procedure;    
    
    procedure search_var_element_number(
        variable slc : in src_locator;
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable ien : out integer
    ) is
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable en : integer;     
    begin
        en := -1;
        s.left := 0;
        s.right := vars.last_element_num;           
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.right / 2 - 1;
            su.left := sl.right + 1;
            su.right := sl.right;
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(su.left).name, var_name) then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;    
        end loop;    
        for i in s.left to s.right loop
            if vars.element_ptrs(i).name = var_name then
                en := i;
                exit;
            end if;              
        end loop;
        ien :=  en;
    end procedure;
    
    procedure search_proc_element_number( 
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable pen : out integer
    ) is
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable en : integer;     
    begin
        en := -1;
        s.left := 0;
        s.right := procs.last_element_num;           
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.right / 2 - 1;
            su.left := sl.right + 1;
            su.right := sl.right;
            if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(su.left).name, proc_name) then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;    
        end loop;    
        for i in s.left to s.right loop
            if procs.element_ptrs(i).name = proc_name then
                en := i;
                exit;
            end if;              
        end loop;
        pen :=  en;
    end procedure;
    
    procedure set_var_type(
        variable inst : in text_field;
        variable inst_len : in integer;
        variable var_type : out stm_var_type
    ) is
    begin
        var_type := T_NO_VAR;
        if inst(1 to inst_len) = INSTR_VAR then
            var_type := T_VALUE;
        elsif inst(1 to inst_len) = INSTR_CONST then
            var_type := T_CONST;
        elsif inst(1 to inst_len) = INSTR_ARRAY then
            var_type := T_ARRAY;
        elsif inst(1 to inst_len) = INSTR_LINES then
            var_type := T_LINES;
        elsif inst(1 to inst_len) = INSTR_FILE then
            var_type := T_TEXT;
        elsif inst(1 to inst_len) = INSTR_BUS then
            var_type := T_BUS;
        elsif inst(1 to inst_len) = INSTR_SIGNAL then
            var_type := T_SIGNAL;
        elsif inst(1 to inst_len) = INSTR_LABEL then
            var_type := T_LABEL;
        end if; 
    end procedure;
    
    procedure set_proc_type(
        variable inst : in text_field;
        variable inst_len : in integer;
        variable proc_type : out boolean
    ) is
    begin
        proc_type := false;
        if inst(1 to inst_len) = INSTR_PROC_PAR_OPEN then
            proc_type := true;
        elsif inst(1 to inst_len) = INSTR_PROC_NOPAR then
            proc_type := true;
        end if;
    end procedure;
    
    procedure track_inst_initial_context(
        variable slc : src_locator;
        variable inst : in text_field;
        variable inst_args : in inst_arguments;
        variable vars : in var_pool_ordered;
        variable procs : in proc_pool_ordered; 
        variable iic : inout stm_inst_initial_context
    ) is
        variable il : integer;
        variable vn : text_field;
        variable ven : integer;
        variable pen : integer;
        variable pn : text_field;
        variable pn_ptr : text_field_ptr;
    begin
        il := fld_len(inst);
        if inst(1 to il) = INSTR_NAMESPACE then
            iic.namespace_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_NAMESPACE then
            iic.namespace_name := (others => nul);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_OPEN then
            iic.code_section := PROC_PARAMS;
            iic.proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_PROC_NOPAR then
            iic.code_section := PROC_BODY;
            iic.proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_PROC then
            iic.code_section := NONE;
        end if;

        if inst(1 to il) = INSTR_CALL_PAR_OPEN then
            iic.code_section := CALL_PARAMS;
            iic.called_proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
            iic.code_section := CALL_PARAMS;
            vn := textfield_dot_cat(iic.namespace_name, inst_args.par_text_fields(1), iic.proc_name);
            access_var(slc, vars, vn, ven);
            pn_ptr := vars.element_ptrs(ven).label_proc_ref;
            text_field_ptr_to_text_field(pn_ptr, pn);
            iic.called_proc_name := pn;
        end if;
        if inst(1 to il) = INSTR_PAR_CLOSE
            or inst(1 to il) = INSTR_EQU_PAR_CLOSE
            or inst(1 to il) = INSTR_VAR_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_ARRAY_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_LABEL_EQU_PAR_CLOSE
            or inst(1 to il) = INSTR_FILE_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_LINES_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE
            or inst(1 to il) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then  
            if iic.code_section = PROC_PARAMS then
                iic.code_section := PROC_BODY;
            end if;
            if iic.code_section = CALL_PARAMS then
                iic.code_section := PROC_BODY;
            end if;
        iic.is_var_declaration := false;
        if inst(1 to il) = INSTR_CONST
            or inst(1 to il) = INSTR_VAR
            or inst(1 to il) = INSTR_VAR_PAR_CLOSE
            or inst(1 to il) = INSTR_SIGNAL
            or inst(1 to il) = INSTR_SIGNAL_PAR_CLOSE
            or inst(1 to il) = INSTR_BUS
            or inst(1 to il) = INSTR_BUS_PAR_CLOSE
            or inst(1 to il) = INSTR_FILE
            or inst(1 to il) = INSTR_FILE_PAR_CLOSE
            or inst(1 to il) = INSTR_LABEL
            or inst(1 to il) = INSTR_LABEL_PAR_CLOSE
            or inst(1 to il) = INSTR_LINES
            or inst(1 to il) = INSTR_LINES_PAR_CLOSE
            or inst(1 to il) = INSTR_ARRAY
            or inst(1 to il) = INSTR_ARRAY_PAR_CLOSE
            or inst(1 to il) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then  
                iic.is_var_declaration := true;
            end if;
        end if;
    end procedure;
             
    procedure insert_proc_element(
        variable slc : src_locator;
        variable procs : inout proc_pool_ordered;
        variable proc_name : in text_field;
        variable debug : boolean
    ) is
        variable ne : proc_element_ptr;
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable is_equ : boolean;
        variable is_less : boolean;
        variable insert_before : integer;
    begin
        ne := new proc_element;    
        ne.name := proc_name;
        ne.slc := slc;
        if procs.last_element_num < 8 then
            insert_before := -1;
            for i in 0 to procs.last_element_num loop
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(i).name, proc_name) then
                    insert_before := i;
                    exit;
                end if;              
            end loop;
        else
            s.left := 0;
            s.right := procs.last_element_num;           
            while s.right - s.left > 8 loop
                sl.left := s.left;
                sl.right := s.right / 2 - 1;
                su.left := sl.right + 1;
                su.right := sl.right;
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(su.left).name, proc_name) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;    
            end loop;
            insert_before := -1;
            for i in 0 to procs.last_element_num - 1 loop
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(su.left).name, proc_name) then
                    insert_before := i;
                    exit;
                end if;              
            end loop;
            insert_before := -1;
            for i in s.left to s.right loop
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(su.left).name, proc_name) then
                    insert_before := i;
                    exit;
                end if;              
            end loop;
        end if;  
        if insert_before >= 0 then
           procs.element_ptrs(insert_before + 1 to procs.last_element_num + 1) := procs.element_ptrs(insert_before to procs.last_element_num);
           procs.element_ptrs(insert_before) := ne;
           procs.last_element_num := procs.last_element_num + 1;
        else
           procs.element_ptrs(procs.last_element_num + 1) := ne;
           procs.last_element_num := procs.last_element_num + 1;
        end if;     
        if debug then
            print("add proc " & proc_name);
        end if;           
    end procedure;
    
    procedure insert_var_element(
        variable slc : src_locator;
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable inst_args : inst_arguments;
        constant var_type : in stm_var_type;
        constant machine_value_width : in integer;
        variable debug : boolean
    ) is
        variable ne : var_element_ptr;
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable insert_before : integer;
        
        procedure init_lines_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.values_org := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values_org(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.label_proc_ref_org := null;
            ne.txt := null;
            ne.txt_enclosing_quote := character'val(126);
            ne.txt_org := null;
            ne.txt_enclosing_quote_org := character'val(126);
            ne.arr := null;
            ne.arr_org := null;
            ne.lines := new stm_lines;
            ne.lines.line_list := null;
            ne.lines.size := 0;
            ne.lines_org := new stm_lines;
            ne.lines_org.line_list := null;
            ne.lines_org.size := 0;
            ne.typ := var_type;
        end procedure;

        procedure init_array_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.values_org := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values_org(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.label_proc_ref_org := null;
            ne.txt := null;
            ne.txt_enclosing_quote := character'val(126);
            ne.txt_org := null;
            ne.txt_enclosing_quote_org := character'val(126);
            ne.arr := new stm_array(0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1)(machine_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1 loop
                ne.arr(i) := to_unsigned(0, machine_value_width);
            end loop;
            ne.arr_org := new stm_array(0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1)(machine_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1 loop
                ne.arr_org(i) := to_unsigned(0, machine_value_width);
            end loop;
            ne.lines := null;
            ne.lines_org := null;
            ne.typ := var_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert inst_args.txt /= null
            report "missing file name in file declaration " & lf &
                   "file " & slc.file_name & lf &
                   "line" & integer'image(slc.file_line)
            severity failure;
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);    
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.values_org := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values_org(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.label_proc_ref_org := null;
            ne.txt := inst_args.txt;
            ne.txt_enclosing_quote := inst_args.txt_enclosing_quote;
            ne.txt_org := inst_args.txt;
            ne.txt_enclosing_quote_org := inst_args.txt_enclosing_quote;
            ne.arr := null;
            ne.arr_org := null;
            ne.lines := null;
            ne.lines_org := null;
            ne.typ := var_type;
        end procedure;
        
        procedure init_label_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.values_org := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values_org(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := new text_field;
            text_field_to_text_field_ptr(inst_args.par_text_fields(2), ne.label_proc_ref);
            ne.label_proc_ref_org := new text_field;
            text_field_to_text_field_ptr(inst_args.par_text_fields(2), ne.label_proc_ref_org);
            ne.txt := null;
            ne.txt_enclosing_quote := character'val(126);
            ne.txt_org := null;
            ne.txt_enclosing_quote_org := character'val(126);
            ne.arr := null;
            ne.arr_org := null;
            ne.lines := null;
            ne.lines_org := null;
            ne.typ := var_type;
        end procedure;

        procedure init_value_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := stim_to_stm_value(slc, inst_args.par_text_fields(2), machine_value_width);
            ne.values_org := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values_org(0) := stim_to_stm_value(slc, inst_args.par_text_fields(2), machine_value_width);
            ne.label_proc_ref := null;
            ne.label_proc_ref_org := null;
            ne.txt := null;
            ne.txt_enclosing_quote := character'val(126);
            ne.txt_org := null;
            ne.txt_enclosing_quote_org := character'val(126);
            ne.arr := null;
            ne.arr_org := null;
            ne.lines := null;
            ne.lines_org := null;
            ne.typ := var_type;
        end procedure;

    begin
        case var_type is
            when T_LINES =>
                init_lines_var;
                if debug then
                    print("add lines var " & ne.name);
                end if;
            when T_ARRAY =>
                init_array_var;
                if debug then
                    print("add array var " & ne.name);
                end if;
            when T_TEXT =>
                init_stm_text_var;
                if debug then
                    print("add text var " & ne.name);
                end if;
            when T_LABEL =>
                init_label_var;
                if debug then
                    print("add label var " & ne.name);
                end if;
            when T_CONST =>
                init_value_var;
                if debug then
                    print("add constant var" & ne.name);
                end if;
            when others =>
                init_value_var;
                if debug then
                    print("add value var " & ne.name);
                end if;
        end case;        

        s.left := 0;
        s.right := vars.last_element_num;           
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.right / 2 - 1;
            su.left := sl.right + 1;
            su.right := sl.right;
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(su.left).name, var_name) then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;    
        end loop;
        insert_before := -1;
        for i in 0 to vars.last_element_num - 1 loop
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(su.left).name, var_name) then
                insert_before := i;
                exit;
            end if;              
        end loop;
        insert_before := -1;
        for i in s.left to s.right loop
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(su.left).name, var_name) then
                insert_before := i;
                exit;
            end if;              
        end loop;
 
        if insert_before >= 0 then
           vars.element_ptrs(insert_before + 1 to vars.last_element_num + 1) := vars.element_ptrs(insert_before to vars.last_element_num);
           vars.element_ptrs(insert_before) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        else
           vars.element_ptrs(vars.last_element_num + 1) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        end if;                
    end procedure;

end package body;
