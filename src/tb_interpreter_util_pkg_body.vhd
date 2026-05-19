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
--   Interpreter utility helper subprogram implementations.
--
-- Upstream reference:
--   https://github.com/sckoarn/VHDL-Test-Bench
-------------------------------------------------------------------------------

use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;

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
        variable txt_obj : out text_object;
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
        constant DEBUG : boolean := false;

    begin
        tmp_text_line := (others => nul);
        j := 1;
        for i in 1 to text_line'high - 1 loop
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
            if j > text_line'high then
                exit;
            end if;
        end loop;

        if DEBUG then
            dump_text_line(itext_line, "itext_line ");
        end if;

        -- null outputs
        itokens := (others => (others => nul));
        txt_obj.txt := null;
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
                txt_obj.txt_enclosing_quote := c(1);
                txt_ptr_tmp := new stm_text;
                next;
            end if;
            -- if we have found a txt string
            if txt_found = 1 and tmp_text_line(i) /= nul then
                -- if string too long, prevent tool hang, truncate and notify
                assert j <= c_stm_text_len
                report ("tokenize_line: code line larger than c_stm_text_len")
                severity failure;
                -- till the very end of tmp_text_line
                if tmp_text_line(i) /= nul then
                    txt_str(j) := tmp_text_line(i);
                    txt_ptr_copy(txt_ptr_tmp, txt_obj.txt, txt_str);
                    j := j + 1;
                else
                    exit;
                end if;
            -- if is a character store in the right token
            elsif is_space(tmp_text_line(i)) = false and tmp_text_line(i) /= nul then
                token_index := token_index + 1;
                current_token(token_index) := tmp_text_line(i);
            -- else is a space, deal with parameters
            elsif is_space(tmp_text_line(i + 1)) = false and tmp_text_line(i + 1) /= nul then
                for k in 0 to 8 loop
                    if k = 0 and token_number = 0 then
                        if token_index /= 0 then
                            itokens(k + 1) := current_token;
                            if DEBUG then
                                print("0k" & integer'image(k) & " " & current_token(1 to fld_len(current_token)));
                            end if;
                            current_token := (others => nul);
                            token_number := k + 1;
                            valid := 1;
                            token_index := 0;
                            exit;
                        end if;
                    elsif k = token_number then
                        itokens(k + 1) := current_token;
                        if DEBUG then
                            print("ek" & integer'image(k) & " " & current_token(1 to fld_len(current_token)));
                        end if;
                        current_token := (others => nul);
                        token_number := k + 1;
                        valid := k + 1;
                        token_index := 0;
                        exit;
                    end if;
                end loop;
            end if;
            -- break from loop if is null
            if tmp_text_line(i) = nul then
                if token_index /= 0 then
                    for k in 0 to 8 loop
                        if k = token_number then
                            itokens(k + 1) := current_token;
                            if DEBUG then
                                print("nk" & integer'image(k) & " " & current_token(1 to fld_len(current_token)));
                            end if;
                            valid := k + 1;
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
                for k in 0 to 8 loop
                    if k = token_number then
                        itokens(k + 1) := current_token;
                        if DEBUG then
                            print("ck" & integer'image(k) & " " & current_token(1 to fld_len(current_token)));
                        end if;
                        valid := k + 1;
                        exit;
                    end if;
                end loop;
            end if;
        end if;
        if DEBUG then
            for y in 1 to valid loop
                print("itokens(" & integer'image(y) & ") " & itokens(y)(1 to fld_len(itokens(y))));
            end loop;
        end if;
        token_merge_words(itokens, valid, otokens, ovalid);
        if DEBUG then
            for y in 1 to ovalid loop
                print("otokens(" & integer'image(y) & ") " & otokens(y)(1 to fld_len(otokens(y))));
            end loop;

            print("-----");
        end if;
    end procedure;

    procedure format(
        variable ie : in inst_element_ptr;
        variable procs : in proc_pool_ordered;
        variable vars : in var_pool_ordered;
        variable rcs : in stm_array_of_runtime_context;
        variable sp : in integer;
        variable txt_obj_ptr : in text_object_ptr;
        variable txt_formatted : out stm_text;
        constant machine_value_width : in integer
    ) is
        variable pen : integer;
        variable ven : integer;
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
        variable tmp_field : text_field;
        variable cut_field : text_field;
        variable var_label_proc_ref_ptr : text_field_ptr;
        variable var_label_proc_ref : text_field;
        variable tmp_i : integer;
        variable input_txt : stm_text;

        variable insert_var : boolean;
        variable format_number : base;
        variable format_string : boolean;
        variable insert_call_stack_label : boolean;
        variable previous_level : integer;
        variable insert_call_stack_file_name : boolean;
        variable insert_call_stack_file_line : boolean;
        variable stack_called_file_name : text_line;
        variable stack_called_file_line : integer;
        variable stack_called_proc : text_field;
        variable called_proc_namespace : text_field;
        variable called_proc_name : text_field;
        variable empty_text_field : text_field := (others => nul);
        variable found : boolean;

    begin
        if txt_obj_ptr = null then
            return;
        end if;
        txt_to_string(txt_obj_ptr.txt, input_txt);
        -- determine variables tail_start in src string
        src_i := 1;
        src_tail_begin := 0;
        while src_i <= c_stm_text_len loop
            if src_i > 1 then
                if txt_obj_ptr.txt(src_i - 1) = '\' and txt_obj_ptr.txt(src_i) = txt_obj_ptr.txt_enclosing_quote then
                    src_i := src_i + 1;
                else
                    if txt_obj_ptr.txt(src_i) = txt_obj_ptr.txt_enclosing_quote then
                        src_tail_begin := src_i;
                        exit;
                    end if;
                    src_i := src_i + 1;
                end if;
            else
                if txt_obj_ptr.txt(src_i) = txt_obj_ptr.txt_enclosing_quote then
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
                if txt_obj_ptr.txt(src_i) = '\' and txt_obj_ptr.txt(src_i + 1) = txt_obj_ptr.txt_enclosing_quote then
                    src_i := src_i + 1;
                end if;
            end if;

            -- copy until next '{'
            while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                if txt_obj_ptr.txt(src_i) = '{' then
                    exit;
                else
                    dest_txt_str(dest_i) := txt_obj_ptr.txt(src_i);
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
                        if dest_txt_str(f_src_i) = '\' and dest_txt_str(f_src_i + 1) = txt_obj_ptr.txt_enclosing_quote then
                            -- skip '/' before txt_ptr.txt_enclosing_quote
                            f_src_i := f_src_i + 1;
                            f_dest_txt_str(f_dest_i) := dest_txt_str(f_src_i);
                            f_src_i := f_src_i + 1;
                            f_dest_i := f_dest_i + 1;
                        else
                            -- don't skip '/' before others but txt_ptr.txt_enclosing_quote
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
                txt_formatted := f_dest_txt_str;
                return;
            end if;
            -- place to embed a var found
            insert_call_stack_label := false;
            insert_call_stack_file_name := false;
            insert_call_stack_file_line := false;
            if txt_obj_ptr.txt(src_i) = '{' then
                src_i := src_i + 1;
                format_string := false;
                format_number := hex;
                insert_var := true;
                while src_i < src_tail_begin and dest_i <= c_stm_text_len loop
                    if txt_obj_ptr.txt(src_i) = '}' then
                        -- default insert variable hex
                        exit;
                    else
                        -- skip until next '}'
                        if txt_obj_ptr.txt(src_i) = ':' then
                            -- insert variable decimal, binary or octal
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if txt_obj_ptr.txt(src_i) = 'd' then
                                format_number := dec;
                            elsif txt_obj_ptr.txt(src_i) = 'b' then
                                format_number := bin;
                            elsif txt_obj_ptr.txt(src_i) = 'o' then
                                format_number := oct;
                            elsif txt_obj_ptr.txt(src_i) = 's' then
                                format_string := true;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        elsif txt_obj_ptr.txt(src_i) = '@' then
                            insert_var := false;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            if txt_obj_ptr.txt(src_i) = 'c' then
                                insert_call_stack_label := true;
                            elsif txt_obj_ptr.txt(src_i) = 'f' then
                                insert_call_stack_file_name := true;
                            elsif txt_obj_ptr.txt(src_i) = 'l' then
                                insert_call_stack_file_line := true;
                            else
                                assert (false)
                                report "wrong format descriptor in {...} brackets " & stm_text_crop(input_txt)
                                severity failure;
                            end if;
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                            previous_level := c2int(txt_obj_ptr.txt(src_i));
                            src_i := src_i + 1;
                            if src_i = src_tail_begin then
                                exit;
                            end if;
                        else
                            assert (false)
                            report "wrong format descriptor in {...} brackets " & stm_text_crop(input_txt)
                            severity failure;
                        end if;
                    end if;
                end loop;
            end if;
            if txt_obj_ptr.txt(src_i) = '}' then
                src_i := src_i + 1;
            else
                assert (false)
                report "format descriptor is missing closing curly bracket " & stm_text_crop(input_txt)
                severity failure;
            end if;

            if insert_var then
                while src_tail_i <= c_stm_text_len loop
                    if is_txt_var_first_character(txt_obj_ptr.txt(src_tail_i)) then
                        exit;
                    else
                        src_tail_i := src_tail_i + 1;
                    end if;
                end loop;
                assert is_txt_var_first_character(txt_obj_ptr.txt(src_tail_i))
                report "format descriptor is missing variable for substitution " & stm_text_crop(input_txt) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                severity failure; 
                tmp_field := (others => nul);
                tmp_i := 1;
                tmp_field(tmp_i) := txt_obj_ptr.txt(src_tail_i);
                src_tail_i := src_tail_i + 1;
                tmp_i := tmp_i + 1;
                -- parse to the next space
                while txt_obj_ptr.txt(src_tail_i) /= ' ' and txt_obj_ptr.txt(src_tail_i) /= nul and txt_obj_ptr.txt(src_tail_i) /= ht loop
                    tmp_field(tmp_i) := txt_obj_ptr.txt(src_tail_i);
                    src_tail_i := src_tail_i + 1;
                    tmp_i := tmp_i + 1;
                end loop;
                
                pen := rcs(sp).pen_of_called_proc;
                called_proc_namespace := procs.element_ptrs(pen).proc_namespace;
                called_proc_name := procs.element_ptrs(pen).proc_name;
                assert pen > -1
                report "format find proc name failed " & stm_text_crop(input_txt)  & " current sp " & integer'image(sp) & " level to go up " & integer'image(previous_level) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                severity failure;   
                if format_string then
                    k := 4;
                    while tmp_field(k) /= nul loop
                        cut_field(k - 3) := tmp_field(k);
                        k := k + 1;
                    end loop;                  
                    if contains_dot(cut_field) then
                        access_var_index(vars, cut_field, IS_FQN, empty_text_field, empty_text_field, ven);
                    else
                        access_var_index(vars, cut_field, IS_NOT_FQN, called_proc_namespace, called_proc_name, ven);
                        if ven < 0 then
                            access_var_index(vars, cut_field, IS_NOT_FQN, called_proc_namespace, empty_text_field, ven);
                        end if;                                        
                    end if; 
                    assert ven > -1
                    report "format find var label " & crop(cut_field) & " to insert by format failed" & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                    severity failure;                     
                    index_var_label(vars, ven, var_label_proc_ref_ptr);  
                    text_field_ptr_to_text_field(var_label_proc_ref_ptr, var_label_proc_ref);           
                    dest_txt_str := ew_str_cat(dest_txt_str, var_label_proc_ref);                    
                else
                    if contains_dot(tmp_field) then
                        access_var_value(vars, tmp_field, IS_FQN, empty_text_field, empty_text_field, found, v1);
                    else
                        access_var_value(vars, tmp_field, IS_NOT_FQN, called_proc_namespace, called_proc_name, found, v1);
                        if not found then
                            access_var_value(vars, tmp_field, IS_NOT_FQN, called_proc_namespace, empty_text_field, found, v1);
                        end if;          
                    end if; 
                    assert found
                    report "format find var value " & crop(tmp_field) & " to insert by format failed" & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                    severity failure;  
                    dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(v1, format_number));              
                end if;             
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
                
            elsif insert_call_stack_file_name then
                pen := rcs(sp - previous_level).pen_of_called_proc;
                assert pen > -1
                report "format insert file name from call stack failed " & stm_text_crop(input_txt)  & " current sp " & integer'image(sp) & " level to go up " & integer'image(previous_level) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                severity failure;               
                stack_called_file_name := procs.element_ptrs(pen).slc.file_name;
                dest_txt_str := ew_str_cat_text_line(dest_txt_str, stack_called_file_name);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_file_line then
                pen := rcs(sp - previous_level).pen_of_called_proc;
                assert pen > -1
                report "format insert file line from call stack failed " & stm_text_crop(input_txt)  & " current sp " & integer'image(sp) & " level to go up " & integer'image(previous_level) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                severity failure;
                stack_called_file_line := procs.element_ptrs(pen).slc.file_line;
                dest_txt_str := ew_str_cat(dest_txt_str, ew_to_text_field(stack_called_file_line, dec));
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            elsif insert_call_stack_label then
                pen := rcs(sp - previous_level).pen_of_called_proc;
                assert pen > -1
                report "format insert procedure name from call stack failed " & stm_text_crop(input_txt)  & " current sp " & integer'image(sp)  & " level to go up " & integer'image(previous_level) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                severity failure;
                stack_called_proc := procs.element_ptrs(pen).proc_name;
                dest_txt_str := ew_str_cat(dest_txt_str, stack_called_proc);
                k := 1;
                while dest_txt_str(k) /= nul loop
                    k := k + 1;
                end loop;
                dest_i := k;
            end if;
        end loop;
        assert false
        report "format ended abnormally " & stm_text_crop(input_txt)  & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
        severity failure;
    end procedure;

    procedure access_inst_par_index(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        constant par_num : in integer;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable ven : out integer
    ) is
        variable vn : text_field;
        variable scope_namespace : text_field;
        variable scope_proc_name : text_field;
    begin
        vn := ie.inst_args.par_text_fields(par_num);
        if ie.inst_args.par_types(par_num) = PAR_FQN then
            vn := append_dot(vn);
        else
           if contains_dot(scope) then
                split_namespace_proc(scope, scope_namespace, scope_proc_name);
                vn := prepend_namespace(vn, scope_namespace);
                vn := append_scope(vn, scope_proc_name);
           else
                vn := prepend_namespace(ie.inst_args.par_text_fields(par_num), namespace);
                vn := append_scope(vn, scope);
            end if;  
        end if;  
        search_var_element_number(vars, vn, ven);
    end procedure;
    
    procedure access_inst_par_value(
        variable ie : in inst_element_ptr;
        variable vars : in var_pool_ordered;
        constant par_num : in integer;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable found : out boolean;
        variable val : out unsigned
    ) is
        variable ptf : text_field;
        variable ven : integer;
    begin
        found := false;
        ptf := ie.inst_args.par_text_fields(par_num);
        if ie.inst_args.par_types(par_num) = PAR_LIT then
            val := stim_to_stm_value(ie.slc, ptf, val'length);
            found := true;
        else
            access_inst_par_index(ie, vars, par_num, namespace, scope, ven);
            if ven > -1 then
                val := vars.element_ptrs(ven).values(0);
                found := true;
            end if;       
        end if;
    end procedure;
    
    procedure access_var_index(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        constant is_fqn : in boolean;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable ven : out integer
    ) is
        variable vn : text_field;
    begin
        if is_fqn then
            vn := var_name;
            vn := append_dot(vn);
        else
            vn := prepend_namespace(var_name, namespace);
            vn := append_scope(vn, scope);
        end if;       
        search_var_element_number(vars, vn, ven);
    end procedure;
    
    procedure access_var_value(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        constant is_fqn : in boolean;
        variable namespace : in text_field;
        variable scope : in text_field;
        variable found : out boolean;
        variable val : out unsigned
    ) is
        variable ven : integer;
    begin
        found := false;
        access_var_index(vars, var_name, is_fqn, namespace, scope, ven);
        if ven > -1 then
            val := vars.element_ptrs(ven).values(0);
            found := true;
        end if;
    end procedure;
    
    procedure access_proc_prepend_namespace(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable namespace : in text_field;
        variable proc_element_num : out integer
    ) is
        variable pn : text_field;
        variable pen : integer;
    begin
        pn := prepend_namespace(proc_name, namespace);
        search_proc_element_number(procs, pn, pen);
        assert pen >= 0
        report "access proc, couldn't find proc " & proc_name & " file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
        proc_element_num := pen;
    end procedure;
    
    procedure access_proc_fqn(
        variable slc : in src_locator;
        variable procs : in proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_element_num : out integer
    ) is
        variable pen : integer;
    begin
        search_proc_element_number(procs, proc_name, pen);
        assert pen >= 0
        report "access proc, couldn't find proc " & proc_name & " file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
        severity failure;
        proc_element_num := pen;
    end procedure;

    procedure index_var_value(
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

    procedure index_var_txt(
        variable vars : in var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : out text_object_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "index var text, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        var_txt_obj := vars.element_ptrs(var_element_num).txt_obj;
    end procedure;

    procedure index_var_arr(
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

    procedure index_var_label(
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

    procedure index_var_lines(
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
    
    procedure init_var_value(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_value : in unsigned;
        constant machine_value_width : integer
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "init var values, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        vars.element_ptrs(var_element_num).values := null;
        vars.element_ptrs(var_element_num).values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
        vars.element_ptrs(var_element_num).values(0) := var_value;
    end procedure;

    procedure update_var_value(
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
    
    procedure init_var_txt(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : in text_object_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "init var text, var element number " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        vars.element_ptrs(var_element_num).txt_obj := var_txt_obj;
    end procedure;

    procedure update_var_txt(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_txt_obj : in text_object_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "update var text, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        vars.element_ptrs(var_element_num).txt_obj := var_txt_obj;
    end procedure;

    procedure init_var_arr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_arr_len : in unsigned;
        constant machine_value_width : integer
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "init var array, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        deallocate(vars.element_ptrs(var_element_num).arr);
        vars.element_ptrs(var_element_num).arr := new stm_array(0 to to_integer(var_arr_len(30 downto 0) - 1))(machine_value_width - 1 downto 0);
    end procedure;

    procedure update_var_arr(
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

    procedure init_var_label(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable par_text_field : in text_field
    ) is
        variable label_proc_ref : text_field_ptr;
    begin
        assert var_element_num <= vars.last_element_num
        report "init var label, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        label_proc_ref := new text_field;
        text_field_to_text_field_ptr(par_text_field, label_proc_ref);
        vars.element_ptrs(var_element_num).label_proc_ref := label_proc_ref;
    end procedure;
    
    procedure init_var_label_ptr(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_label_proc_ref : in text_field_ptr
    ) is
        variable label_proc_ref : text_field_ptr;
        variable tf : text_field;
    begin
        assert var_element_num <= vars.last_element_num
        report "update var label, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        text_field_ptr_to_text_field(var_label_proc_ref, tf);
        label_proc_ref := new text_field;
        text_field_to_text_field_ptr(tf, label_proc_ref);
        vars.element_ptrs(var_element_num).label_proc_ref := label_proc_ref;
    end procedure;

    procedure update_var_label(
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

    procedure init_var_lines(
        variable vars : inout var_pool_ordered;
        variable var_element_num : in integer;
        variable var_lines : in stm_lines_ptr
    ) is
    begin
        assert var_element_num <= vars.last_element_num
        report "init var lines, var element number, " & integer'image(var_element_num) & "greater than vars last element number & integer'image(vars.last_element_num)"
        severity failure;
        vars.element_ptrs(var_element_num).lines := var_lines;
    end procedure;

    procedure update_var_lines(
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

    procedure print_inst_element(
        variable insts : in inst_sequence;
        variable inst_element_num : in integer
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
        print(".... instruction element number " & crop(to_text_field(inst_element_num)) & "(" & crop(to_text_field_hex(inst_element_num)) & ")");
        print(".... instruction namespace " & crop(insts.element_ptrs(inst_element_num).inst_namespace));
        print(".... instruction file name " & crop(insts.element_ptrs(inst_element_num).slc.file_name));
        print(".... instruction file linenumber " & crop(to_text_field(insts.element_ptrs(inst_element_num).slc.file_line)));
        for i in 1 to 6 loop
            pl := fld_len(insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
            if pl > 0 then
                print(".... par" & integer'image(i) & " " & insts.element_ptrs(inst_element_num).inst_args.par_text_fields(i));
                if insts.element_ptrs(inst_element_num).inst_args.par_types(i) = PAR_LIT then
                    print(".... par_type" & integer'image(i) & " PAR_LIT");
                elsif insts.element_ptrs(inst_element_num).inst_args.par_types(i) = PAR_FQN then
                    print(".... par_type" & integer'image(i) & " PAR_FQN");
                else
                    print(".... par_type" & integer'image(i) & " PAR_NM");
                end if;
                print(".... par_literal_value" & integer'image(i) & " " & crop(to_text_field_hex(insts.element_ptrs(inst_element_num).inst_args.par_literal_values(i))));
            end if;
        end loop;
        txt_to_string(insts.element_ptrs(inst_element_num).inst_args.txt_obj.txt, txt);
        eq := insts.element_ptrs(inst_element_num).inst_args.txt_obj.txt_enclosing_quote;
        print(".... text " & eq & txt & eq);
    end procedure;

    procedure dump_inst_sequence(
        variable insts : in inst_sequence
    ) is
        variable ien : integer;
    begin
        print("++++ --dump_inst_sequence-----------------------------------------------------");
        for i in 0 to insts.last_element_num loop
            ien := i;
            print_inst_element(insts, ien);
        end loop;
    end procedure;

    procedure dump_var_pool_ordered(
        variable vars : in var_pool_ordered;
        constant machine_value_width : in integer
    ) is
        variable ven : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump variables start -----------------------------------------");
        for i in 0 to vars.last_element_num loop
            ven := i;
            dump_var_element(vars, ven, machine_value_width);
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
        report "dump  var element, var element number, " & integer'image(var_element_num) & "greater than vars last element number " & integer'image(vars.last_element_num)
        severity failure;
        write(std_line, string'("Hello, world!"));
        print("-----------------------------------------------------------------");
        print("---- var definition in file " & crop(vars.element_ptrs(var_element_num).slc.file_name));
        print("---- var definition in line " & integer'image(vars.element_ptrs(var_element_num).slc.file_line));
        print("---- var name " & crop(vars.element_ptrs(var_element_num).name));
        print("---- var element num " & crop(to_text_field(var_element_num)) & "(" & crop(to_text_field_hex(var_element_num)) & ")");
        print("---- var_value: " & crop(to_text_field_hex(vars.element_ptrs(var_element_num).values(0))));
        if vars.element_ptrs(var_element_num).typ = T_VALUE then
            print("---- var type: T_VALUE");
        elsif vars.element_ptrs(var_element_num).typ = T_CONST then
            print("---- var type: T_CONST");
        elsif vars.element_ptrs(var_element_num).typ = T_VALUE then
            print("---- var type: T_VALUE");
        elsif vars.element_ptrs(var_element_num).typ = T_TEXT then
            print("---- var type: T_TEXT");
            txt_to_string(vars.element_ptrs(var_element_num).txt_obj.txt, tmp_str);
            eq := vars.element_ptrs(var_element_num).txt_obj.txt_enclosing_quote;
            print("---- var_txt " & eq & crop(tmp_str) & eq);
        elsif vars.element_ptrs(var_element_num).typ = T_ARRAY then
            print("---- var_stm_type: T_ARRAY");
            stm_array := vars.element_ptrs(var_element_num).arr;
            for i in 0 to stm_array'high loop
                array_index := i;
                array_value := stm_array(array_index);
                print("-------- index " & crop(to_text_field(array_index)) & ", value " & crop(to_text_field_hex(array_value)));
            end loop;
        elsif vars.element_ptrs(var_element_num).typ = T_LINES then
            print("---- var_stm_type: T_LINES");
            assert vars.element_ptrs(var_element_num).lines /= null
            report " dump  var element, stm_lines_ptr pointer is null "
            severity failure;
            print("-------- stm_lines.size " & crop(to_text_field(vars.element_ptrs(var_element_num).lines.size)));
            stm_line_ptr := vars.element_ptrs(var_element_num).lines.line_list;
            while stm_line_ptr /= null loop
                print("-------- stm_line_ptr.line_number " & crop(to_text_field(stm_line_ptr.line_number)));
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
                    print("-------- stm_line_ptr.line_content'length before reading " & crop(to_text_field(stm_line_ptr.line_content'length)));
                    array_index := 0;
                    tmp_std_line_print := new string'(stm_line_ptr.line_content.all);
                    while success loop
                        hread(tmp_std_line_print, value_std_logic_vector, success);
                        if success then
                            array_value := unsigned(value_std_logic_vector);
                            print("-------- index " & crop(to_text_field(array_index)) & ", value " & crop(to_text_field_hex(array_value)));
                        end if;
                        array_index := array_index + 1;
                    end loop;
                    print("-------- stm_line_ptr.line_content'length after reading " & crop(to_text_field(stm_line_ptr.line_content'length)));
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
                print("---- var_label_proc_ref " & tmp_label);
            else
                print("---- var_label_proc_ref: missing");
            end if;
            print("---- var_stm_type: T_LABEL");
        elsif vars.element_ptrs(var_element_num).typ = T_NO_VAR then
            print("---- var_stm_type: T_NO_VAR");
        end if;
    end procedure;

    procedure dump_proc_pool_ordered(
        variable procs : in proc_pool_ordered
    ) is
        variable pen : integer;
    begin
        print("---- -----------------------------------------------------------------");
        print("---- -- dump procedures start ----------------------------------------");
        for i in 0 to procs.last_element_num loop
            pen := i;
            dump_proc_element(procs, pen);
        end loop;
    end procedure;

    procedure dump_proc_element(
        variable procs : in proc_pool_ordered;
        variable proc_element_num : in integer
    ) is
    begin
        assert proc_element_num <= procs.last_element_num
        report "dump  proc element, proc element number, " & integer'image(proc_element_num) & "greater than vars last element number " & integer'image(procs.last_element_num)
        severity failure;
        print("-----------------------------------------------------------------");
        print("---- proc definition in file " & crop(procs.element_ptrs(proc_element_num).slc.file_name));
        print("---- proc definition in line " & integer'image(procs.element_ptrs(proc_element_num).slc.file_line));
        print("---- proc name fqn " & procs.element_ptrs(proc_element_num).proc_fqn);
        print("---- proc element num " & crop(to_text_field(proc_element_num)) & "(" & to_text_field_hex(proc_element_num) & ")");
        print("---- proc_pointer_to_ien " & crop(to_text_field(procs.element_ptrs(proc_element_num).pointer_to_ien)) & "(" & crop(to_text_field_hex(procs.element_ptrs(proc_element_num).pointer_to_ien)) & ")");
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
        print(".... file element num " & integer'image(file_element_num));
        print(".... absolute file name " & text_line_crop(files.element_ptrs(file_element_num).absolute_file_name));
        print(".... file name " & files.element_ptrs(file_element_num).file_name);
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

    procedure print_initial_instruction_context(
        variable iic : in stm_inst_initial_context
    ) is
    begin
        case iic.code_section is
            when NONE =>
                print("code section NONE");
            when PROC_BODY =>
                print("code section PROC_PARAMS");
            when PROC_PARAMS =>
                print("code section IN_PROC_BODY");
            when CALL_PARAMS =>
                print("code section IN_CALL_PARAMS");
        end case;
        print("namespace name " & crop(iic.namespace_name));
        print("proc name " & crop(iic.proc_name));
        print("called proc name " & crop(iic.called_proc_name));
    end procedure;

    procedure print_runtime_context(
        variable rc : in stm_runtime_context;
        constant prefix_lines : string
    ) is
    begin
        case rc.call_process_state is
            when IN_NONE =>
                print(prefix_lines & "call_process_state IN_NONE");
            when IN_PROC_PARAMS =>
                print(prefix_lines & "call_process_state IN_PROC_PARAMS");
            when IN_PROC_BODY =>
                print(prefix_lines & "call_process_state IN_PROC_BODY");
            when IN_CALL_PARAMS =>
                print(prefix_lines & "call_process_state IN_CALL_PARAMS");
        end case;
        print(prefix_lines & "pen_of_called_proc " & integer'image(rc.pen_of_called_proc));
        print(prefix_lines & "ien_of_call " & integer'image(rc.ien_of_call));
        print(prefix_lines & "ien_of_proc_params_end " & integer'image(rc.ien_of_proc_params_end));
        print(prefix_lines & "ien_of_called_proc " & integer'image(rc.ien_of_called_proc));
        print(prefix_lines & "loop_num " & integer'image(rc.loop_num));
        print(prefix_lines & "loop_if_enter_level " & integer'image(rc.loop_if_enter_level));
    end procedure;

    procedure search_var_element_number(
        variable vars : in var_pool_ordered;
        variable var_name : in text_field;
        variable ien : out integer
    ) is
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable en : integer;
        variable cmp_name : text_field;
        variable is_equ : boolean;
        variable is_less : boolean;
    begin
        en := -1;
        s.left := 0;
        s.right := vars.last_element_num;
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.left + (s.right - s.left) / 2 - 1;
            su.left := sl.right + 1;
            su.right := s.right;
            cmp_name := vars.element_ptrs(sl.right).name;
            fld_order(var_name, cmp_name, is_equ, is_less);
            if is_less or is_equ then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;
        end loop;
        for i in s.left to s.right loop
            cmp_name := vars.element_ptrs(i).name;
            if cmp_name = var_name then
                en := i;
                exit;
            end if;
        end loop;
        ien := en;
    end procedure;

    procedure search_proc_element_number(
        variable procs : in proc_pool_ordered;
        variable proc_fqn : in text_field;
        variable pen : out integer
    ) is
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable en : integer;
        variable cmp_name : text_field;
        variable is_equ : boolean;
        variable is_less : boolean;
    begin
        en := -1;
        s.left := 0;
        s.right := procs.last_element_num;
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.left + (s.right - s.left) / 2 - 1;
            su.left := sl.right + 1;
            su.right := s.right;
            cmp_name := procs.element_ptrs(sl.right).proc_fqn;
            fld_order(proc_fqn, cmp_name, is_equ, is_less);
            if is_less or is_equ then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;
        end loop;
        for i in s.left to s.right loop
            cmp_name := procs.element_ptrs(i).proc_fqn;
            if cmp_name = proc_fqn then
                en := i;
                exit;
            end if;
        end loop;
        pen := en;
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
        variable slc : in src_locator;
        variable ts : in token_text_field_array;
        variable vars : in var_pool_ordered;
        variable iic : inout stm_inst_initial_context
    ) is
        variable inst : text_field;
        variable il : integer;
        variable ven : integer;
        variable pn : text_field;
        variable pn_ptr : text_field_ptr;
        variable ie : inst_element_ptr;
        variable empty_text_field : text_field := (others => nul);
    begin
        inst := ts(1);
        il := fld_len(inst);
        if inst(1 to il) = INSTR_NAMESPACE then
            iic.namespace_name := ts(2);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_OPEN then
            iic.code_section := PROC_PARAMS;
            iic.proc_name := ts(2);
        end if;
        if inst(1 to il) = INSTR_PROC_NOPAR then
            iic.code_section := PROC_BODY;
            iic.proc_name := ts(2);
        end if;
        if inst(1 to il) = INSTR_END_PROC then
            iic.code_section := NONE;
            iic.proc_name := (others => nul);
            iic.called_proc_name := (others => nul);
        end if;

        if inst(1 to il) = INSTR_CALL_PAR_OPEN then
            iic.code_section := CALL_PARAMS;
            iic.called_proc_name := ts(2);
        end if;
        if inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
            iic.code_section := CALL_PARAMS;
            ie := new inst_element;
            ie.slc := slc;
            ie.inst := inst;
            ie.inst_len := il;
            ie.inst_namespace := iic.namespace_name;
            ie.inst_args.par_text_fields(1) := ts(2);
            access_inst_par_index(ie, vars, 1, ie.inst_namespace, iic.proc_name, ven);
            if ven < 0 then
                access_inst_par_index(ie, vars, 1, ie.inst_namespace, empty_text_field, ven);
            end if;            
            assert ven > -1
            report "var not found " & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
            severity failure;                                     
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
    end procedure;

    procedure insert_proc_element(
        variable slc : in src_locator;
        variable procs : inout proc_pool_ordered;
        variable proc_namespace : in text_field;
        variable proc_name : in text_field;
        constant debug : boolean;
        variable pen : out integer
    ) is
        variable ne : proc_element_ptr;
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable insert_before : integer;
        variable ne_num : integer;
        variable cmp_name : text_field;
        variable proc_fqn : text_field;
    begin
        ne := new proc_element;
        ne.proc_namespace := proc_namespace;
        ne.proc_name := proc_name;      
        proc_fqn := prepend_namespace(proc_name, proc_namespace);   
        ne.proc_fqn := proc_fqn;
        ne.slc := slc;

        insert_before := -1;
        if procs.last_element_num >= 0 then
            s.left := 0;
            s.right := procs.last_element_num;
            while s.right - s.left > 8 loop
                sl.left := s.left;
                sl.right := s.left + (s.right - s.left) / 2 - 1;
                su.left := sl.right + 1;
                su.right := s.right;
                cmp_name := procs.element_ptrs(sl.right).proc_fqn;
                if order_is_less_than_failure_on_equal(slc, proc_fqn, cmp_name) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;
            end loop;
            for i in s.left to s.right loop
                cmp_name := procs.element_ptrs(i).proc_fqn;
                if order_is_less_than_failure_on_equal(slc, proc_fqn, cmp_name) then
                    insert_before := i;
                    exit;
                end if;
            end loop;
        end if;

        if insert_before >= 0 then
            procs.element_ptrs(insert_before + 1 to procs.last_element_num + 1) := procs.element_ptrs(insert_before to procs.last_element_num);
            ne_num := insert_before;
        else
            ne_num := procs.last_element_num + 1;
        end if;
        procs.element_ptrs(ne_num) := ne;
        procs.last_element_num := procs.last_element_num + 1;
        if debug then
            print("add proc " & proc_fqn);
        end if;
        pen := ne_num;
    end procedure;

    procedure insert_var_element(
        variable slc : in src_locator;
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable inst_args : inst_arguments;
        constant var_type : in stm_var_type;
        constant machine_value_width : in integer;
        constant debug : in boolean;
        variable ven : out integer
    ) is
        variable ne : var_element_ptr;
        variable s : slice;
        variable su : slice;
        variable sl : slice;
        variable insert_before : integer;
        variable ne_num : integer;
        variable cmp_name : text_field;

        procedure init_lines_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.txt_obj := null;
            ne.arr := null;
            ne.lines := new stm_lines;
            ne.lines.line_list := null;
            ne.lines.size := 0;
            ne.typ := var_type;
        end procedure;

        procedure init_array_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.txt_obj := null;
            ne.arr := new stm_array(0 to to_integer(inst_args.par_literal_values(2)(30 downto 0)) - 1)(machine_value_width - 1 downto 0);
            for i in 0 to to_integer(inst_args.par_literal_values(2)(30 downto 0)) - 1 loop
                ne.arr(i) := to_unsigned(0, machine_value_width);
            end loop;
            ne.lines := null;
            ne.typ := var_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert inst_args.txt_obj /= null
            report "missing file name in file declaration " & "file " & crop(slc.file_name) & " line " & integer'image(slc.file_line)
            severity failure;
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := null;
            ne.txt_obj := inst_args.txt_obj;
            ne.arr := null;
            ne.lines := null;
            ne.typ := var_type;
        end procedure;

        procedure init_label_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := to_unsigned(0, machine_value_width);
            ne.label_proc_ref := new text_field;
            text_field_to_text_field_ptr(inst_args.par_text_fields(2), ne.label_proc_ref);
            ne.txt_obj := null;
            ne.arr := null;
            ne.lines := null;
            ne.typ := var_type;
        end procedure;

        procedure init_value_var is
        begin
            ne := new var_element;
            ne.slc := slc;
            ne.name := var_name;
            ne.values := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.values(0) := inst_args.par_literal_values(2);
            ne.label_proc_ref := null;
            ne.txt_obj := null;
            ne.arr := null;
            ne.lines := null;
            ne.typ := var_type;
        end procedure;

    begin
        case var_type is
            when T_LINES =>
                init_lines_var;
            when T_ARRAY =>
                init_array_var;
            when T_TEXT =>
                init_stm_text_var;
            when T_LABEL =>
                init_label_var;
            when T_CONST =>
                init_value_var;
            when others =>
                init_value_var;
        end case;

        insert_before := -1;
        if vars.last_element_num >= 0 then
            s.left := 0;
            s.right := vars.last_element_num;
            while s.right - s.left > 8 loop
                sl.left := s.left;
                sl.right := s.left + (s.right - s.left) / 2 - 1;
                su.left := sl.right + 1;
                su.right := s.right;
                cmp_name := vars.element_ptrs(sl.right).name;
                if order_is_less_than_failure_on_equal(slc, var_name, cmp_name) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;
            end loop;
            for i in s.left to s.right loop
                cmp_name := vars.element_ptrs(i).name;
                if order_is_less_than_failure_on_equal(slc, var_name, cmp_name) then
                    insert_before := i;
                    exit;
                end if;
            end loop;
        end if;

        if insert_before >= 0 then
            vars.element_ptrs(insert_before + 1 to vars.last_element_num + 1) := vars.element_ptrs(insert_before to vars.last_element_num);
            ne_num := insert_before;
        else
            ne_num := vars.last_element_num + 1;
        end if;
        vars.element_ptrs(ne_num) := ne;
        vars.last_element_num := vars.last_element_num + 1;
        if debug then
            print("add var #" & integer'image(ne_num) & "(" & integer'image(vars.last_element_num) & ") " & var_type_to_string(var_type) & " " & ne.name & " " & crop(slc.file_name) & " " & integer'image(slc.file_line));
        end if;
        ven := ne_num;
    end procedure;

end package body;
