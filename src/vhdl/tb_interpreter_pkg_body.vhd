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
use work.tb_interpreter_util_pkg.all;
use work.tb_interpreter_basic_pkg.all;

package body tb_interpreter_pkg is

    procedure search_inst_element_ptr(
        variable inst_list : in inst_element_ptr;
        variable search_for_inst_element_number : in integer;
        variable last_searched_inst_element_number : inout integer;
        variable last_searched_inst_element_ptr : inout inst_element_ptr;
        variable inst_element_ptr : out inst_element_ptr
    ) is
        variable instr_ptr : inst_element_ptr;
    begin
        -- get to the instruction indicated by the search_for_inst_element_number
        -- check to see if this number is before the last_searched_inst_element_number
        -- so search from start
        if last_searched_inst_element_number > search_for_inst_element_number then
            instr_ptr := inst_list;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.element_number = search_for_inst_element_number then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            instr_ptr := last_searched_inst_element_ptr;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.element_number = search_for_inst_element_number then
                    inst_element_ptr := instr_ptr;
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        end if;
        -- update the last sequence number and record pointer
        last_searched_inst_element_number := search_for_inst_element_number;
        last_searched_inst_element_ptr := instr_ptr;
    end procedure;
    
    procedure get_inst_element_ptr(
        variable inst_list : in inst_element_ptr;
        variable search_for_inst_element_number : in integer;
        variable last_searched_inst_element_number : inout integer;
        variable last_searched_inst_element_ptr : inout inst_element_ptr;
        variable inst_element_ptr : out inst_element_ptr
    ) is
        variable instr_ptr : inst_element_ptr;
    begin
        -- get to the instruction indicated by the search_for_inst_element_number
        -- check to see if this number is before the last_searched_inst_element_number
        -- so search from start
        if last_searched_inst_element_number > search_for_inst_element_number then
            instr_ptr := inst_list;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.element_number = search_for_inst_element_number then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            instr_ptr := last_searched_inst_element_ptr;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.element_number = search_for_inst_element_number then
                    inst_element_ptr := instr_ptr;
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        end if;
        -- update the last sequence number and record pointer
        last_searched_inst_element_number := search_for_inst_element_number;
        last_searched_inst_element_ptr := instr_ptr;
    end procedure;

    procedure access_inst_element_ptr(
        variable inst_element_ptr : in inst_element_ptr;
        variable file_list : in file_def_ptr;
        variable inst : out text_field;
        variable inst_len : out integer;
        variable par_text_fields : out parameter_text_field_array;
        variable txt : out stm_text_ptr;
        variable txt_enclosing_quote : out character;
        variable file_line : out integer;
        variable file_name : out text_line
    ) is
        variable tmp_file_index : integer;
        variable tmp_file_def_ptr : file_def_ptr;
    begin
        inst := inst_element_ptr.inst;
        inst_len := fld_len(inst_element_ptr.inst);
        par_text_fields := inst_element_ptr.parameters;
        txt := inst_element_ptr.txt;
        txt_enclosing_quote := inst_element_ptr.txt_enclosing_quote;
        file_line := inst_element_ptr.file_line;
        -- recover the file name this line came from
        tmp_file_def_ptr := file_list;
        tmp_file_index := inst_element_ptr.file_idx;
        while tmp_file_def_ptr.next_rec /= null loop
            if tmp_file_def_ptr.rec_idx = tmp_file_index then
                exit;
            end if;
            tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
        end loop;
        for i in 1 to file_name'high loop
            file_name(i) := tmp_file_def_ptr.file_name(i);
        end loop;
    end procedure;

    procedure access_inst_element_parameters(
        variable var_list : in var_field_ptr;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable par_scopes : in parameter_scope_text_field_array;
        variable par_text_fields : in parameter_text_field_array;
        variable par_indexes : out parameter_index_array;
        variable par_values : out parameter_value_array
    ) is
        variable valid : integer;
    begin
        for i in 1 to 6 loop
            if par_text_fields(i)(1) /= nul then
                if is_digit(par_text_fields(i)(1)) then
                    par_values(i) := stim_to_stm_value(par_text_fields(i), file_name, file_line, par_text_fields(i)'length);
                else
                    access_var(var_list, par_scopes(i), par_text_fields(i), par_indexes(i), par_values(i), valid);
                    assert valid /= 0
                    report lf & "variable number " & (integer'image(i)) & " on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
        end loop;
    end procedure;
    
    procedure collect_code_files(
        constant absolute_code_file_name : in text_line;
        variable code_files : inout file_def_list
    ) is 
        variable fos : file_open_status;
        variable absolut_file_name : text_line;
        variable tl : text_line;
        variable ts : token_text_field_array;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable len : integer;
        variable absolut_include_file_name : text_line;
        variable file_line : integer; 
    begin
        file_open(fos, stimulus, absolute_code_file_name, read_mode);
        assert fos = open_ok
        report "unable to open stimulus_file " & absolute_code_file_name
        severity failure; 
        append_code_file(path_name, file_name, code_files);
        print("loading codefile " & absolut_include_file_name);
        file_line := 0;  
        while not endfile(stimulus) loop
            file_line := file_line + 1;
            file_read_line(stimulus, tl);
            tokenize_inst_line(tl, ts, t_txt, txt_enclosing_quote, valid);
            len := fld_len(ts(1));
            if ts(1)(1 to len) = "include" then
                assert t_txt /= null
                report "include instruction defines no file name: " & lf &
                "file " & path_name & file_name & lf &
                "line " & integer'image(file_line)
                severity failure;            
                absolut_include_file_name := (others => nul);
                for i in 1 to c_stm_text_len loop
                    absolut_include_file_name(i) := t_txt(i);
                    if t_txt(i) = txt_enclosing_quote then
                        absolut_include_file_name(i) := nul;
                        exit;
                    end if;
                end loop;
                collect_code_files(absolut_include_file_name, code_files);
            end if;
        end loop;   
    end procedure;  
    
      
    procedure parse_constants(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered; 
        variable inst_parse_context : t_stm_inst_parse_context;
        variable machine_value_width : integer       
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;        
        variable tl : text_line;
        variable len : integer;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid_tokenize : integer;
        variable valid_ckeck : integer;
    begin
        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, t_txt, txt_enclosing_quote, valid_tokenize);
                len := fld_len(ts(1));
                if valid_tokenize /= 0 then
                    inst := ts(1);
                    extract_parameters(ts, ps);
                    check_valid_inst(inst, inst_def_list, valid, file_line, afn);
                    add_var_on_constant_declaration(afn, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, machine_value_width);
                end if;            
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;
    
    
    procedure parse_variables(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered; 
        variable inst_parse_context : t_stm_inst_parse_context;
        variable machine_value_width : integer       
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;        
        variable tl : text_line;
        variable len : integer;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid_tokenize : integer;
        variable valid_ckeck : integer;
    begin
        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, t_txt, txt_enclosing_quote, valid_tokenize);
                len := fld_len(ts(1));
                if valid_tokenize /= 0 then
                    inst := ts(1);
                    extract_parameters(ts, ps);
                    check_valid_inst(inst, inst_def_list, valid, file_line, afn);
                    add_var_on_variable_declaration(afn, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, machine_value_width);
                end if;            
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;
    
    procedure parse_instructions_and_procs(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered; 
        variable inst_parse_context : t_stm_inst_parse_context;
        variable machine_value_width : integer       
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;        
        variable tl : text_line;
        variable len : integer;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid_tokenize : integer;
        variable valid_ckeck : integer;
    begin
        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, t_txt, txt_enclosing_quote, valid_tokenize);
                len := fld_len(ts(1));
                if valid_tokenize /= 0 then
                    inst := ts(1);
                    extract_parameters(ts, ps);
                    check_valid_inst(inst, inst_def_list, valid, file_line, afn);
                    add_inst_and_proc_on_proc(v_iname, file_line, insts, procs, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                 end if;            
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;
        
        
        
            
    

    procedure read_instruction_file(
        variable pass : in integer;
        constant path_name : string;
        constant file_name : string;
        variable inst_defs : inout inst_def_ptr;
        variable vars : inout var_pool_ordered;
        variable procss : inout proc_pool_ordered;
        variable insts : inout inst_sequence;
        variable s : inout inst_sequence; 
        variable var_list : inout var_field_ptr;
        variable file_list : inout file_def_ptr;
        constant stm_value_width : in integer
    ) is
        variable inst_context : t_stm_inst_context;
        variable inst : text_field;
        variable ps : parameter_text_field_array;        
        variable l : text_line; 
        variable file_line : integer; 
        
        variable ts : token_text_field_array;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_ptr : var_field_ptr;
        variable v_sequ_ptr : inst_element_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;

    begin
        -- open the stimulus_file and check
        file_open(v_stat, stimulus, path_name & file_name, read_mode);
        assert v_stat = open_ok
        report lf & "unable to open stimulus_file  " & path_name & file_name
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
        --  nul the text line
        v_tmp_fn.file_name := (others => nul);
        for i in 1 to path_name'high loop
            v_tmp_fn.file_name(i) := path_name(i);
        end loop;
        for i in 1 to file_name'high loop
            v_tmp_fn.file_name(i + path_name'high) := file_name(i);
        end loop;
        v_tmp_fn.next_rec := null;
        file_line := 1;
        inst_element_num := 1;
        v_ostat := 0;
        v_instr_ptr := inst_def_list;
        v_var_ptr := var_list;
        v_sequ_ptr := inst_list;
        init_inst_context(inst_context);
        -- while not the end of file read it
        while not endfile(stimulus) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_inst_line(l, ts, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(ts(1));
            -- if there is an include instruction
            if ts(1)(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := ts(2)(i);
                    end loop;
                -- elsif the text string is not null
                elsif t_txt /= null then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if t_txt(i) = txt_enclosing_quote then
                            v_iname(i) := nul;
                            exit;
                        end if;
                    end loop;
                else
                    assert false
                    report lf & " include instruction has not file name included.  found on" & lf & "line " & integer'image(file_line) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                print("include found: loading file " & path_name & v_iname);
                read_include_file(pass, path_name, v_iname, insts, v_tmp_fn, v_instr_ptr, v_var_ptr, v_sequ_ptr, v_ostat, stm_value_width);
                -- if include file not found
                if v_ostat = 1 then
                    exit;
                end if;
            -- if there were valid tokens
            elsif valid /= 0 then
                inst := ts(1);
                for i in 1 to 6 loop 
                    ps(i) := ts(i + 1);
                end loop;
                check_valid_inst(inst, v_instr_ptr, valid, file_line, v_name);
                case pass is
                    when 0 =>
                        add_var_on_constant_declaration(v_iname, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                    when 1 =>
                        add_var_on_variable_declaration(v_iname, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                    when others =>
                        add_inst_and_proc_on_proc(v_iname, file_line, insts, procs, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                end if;
            end if;
            file_line := file_line + 1;
        end loop; -- end loop read file
        file_close(stimulus); -- close the file when done
        assert v_ostat = 0
        report lf & "include file specified on line " & (integer'image(file_line)) & " in file " & path_name & file_name & " was not found! test terminated" & lf
        severity failure;
        inst_def_list := v_instr_ptr;
        var_list := v_var_ptr;
        inst_list := v_sequ_ptr;
        file_list := v_tmp_fn;
    end procedure;

    procedure read_include_file(
        variable pass : in integer;
        constant path_name : string;
        variable name : text_line;
        variable inst_element_num : inout integer;
        variable file_list : inout file_def_ptr;
        variable inst_def_list : inout inst_def_ptr;
        variable var_list : inout var_field_ptr;
        variable inst_list : inout inst_element_ptr;
        variable status : inout integer;
        constant stm_value_width : in integer
    ) is
        variable inst_context : t_stm_inst_context;
        variable l : text_line; -- the line
        variable file_line : integer; -- line number file
        variable inst : text_field;
        variable ps : parameter_text_field_array; 
        variable ts : token_text_field_array;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_ptr : var_field_ptr;
        variable v_sequ_ptr : inst_element_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_tmp_fn_ptr : file_def_ptr;
        variable v_new_fn : integer;
        variable v_tmp_fn : file_def_ptr;
        variable present : boolean;
        variable v_iname : text_line;
        variable include_file_path_name : text_line;
        variable v_ostat : integer;
        file include_file : text; -- file declaration for includes

    begin
        inst_element_num := inst_element_num;
        v_tmp_fn_ptr := file_list;
        for i in 1 to path_name'high loop
            include_file_path_name(i) := path_name(i);
        end loop;
        for i in 1 to max_str_len - path_name'high loop
            include_file_path_name(i + path_name'high) := name(i);
        end loop;
        --  open include file
        file_open(v_stat, include_file, text_line_crop(include_file_path_name), read_mode);
        if v_stat /= open_ok then
            print("unable to open include file  " & text_line_crop(include_file_path_name));
            status := 1;
            return;
        end if;
        file_line := 1; -- initialize line number
        --  the file is opened, put it on the file name ll
        while v_tmp_fn_ptr.next_rec /= null loop
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
        v_instr_ptr := inst_def_list;
        v_var_ptr := var_list;
        v_sequ_ptr := inst_list;
        -- while not the end of file read it
        while not endfile(include_file) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_inst_line(l, ts, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(ts(1));
            if ts(1)(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := ts(2)(i);
                    end loop;
                -- elsif the text string is not null
                elsif t_txt /= null then
                    v_iname := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        v_iname(i) := t_txt(i);
                        if t_txt(i) = txt_enclosing_quote then
                            v_iname(i) := nul;
                            exit;
                        end if;
                    end loop;
                else
                    assert false
                    report lf & " include instruction is missing included file name paramater , found at:" & lf & "line " & (integer'image(file_line)) & " in file " & include_file_path_name & lf
                    severity failure;
                end if;
                print("nested include found in : " & include_file_path_name);
                check_presence_inst_file_name(file_list, v_iname, present);
                if present then
                    print("nested include found: not loading file since already present " & text_line_crop(v_iname));
                else
                    print("nested include found: loading file " & path_name & v_iname);
                    read_include_file(pass, path_name, v_iname, inst_element_num, v_tmp_fn, v_instr_ptr, v_var_ptr, v_sequ_ptr, v_ostat, stm_value_width);
                    -- if include file not found
                    if v_ostat = 1 then
                        exit;
                    end if;
                end if;
            -- if there were valid tokens
            elsif valid /= 0 then
                inst := ts(1);
                for i in 1 to 6 loop 
                    ps(i) := ts(i + 1);
                end loop;
                check_valid_inst(inst, v_instr_ptr, valid, file_line, v_iname);
                case pass is
                    when 0 =>
                        add_var_on_constant_declaration(v_iname, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                    when 1 =>
                        add_var_on_non_local_variable_declaration(v_iname, file_line, vars, inst_parse_context, inst, ps, t_txt, txt_enclosing_quote, stm_value_width);
                    when others =>
                        add_var_on_variable_declaration(v_iname, file_line, insts, procs, inst, ps, t_txt, txt_enclosing_quote, file_line, v_iname, v_new_fn, inst_context, stm_value_width);
                end if;
            end if;
            file_line := file_line + 1;
        end loop; -- end loop read file
        file_close(include_file);
        inst_element_num := inst_element_num;
        inst_def_list := v_instr_ptr;
        var_list := v_var_ptr;
        inst_list := v_sequ_ptr;
    end procedure;

end package body;
