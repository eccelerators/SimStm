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
use work.tb_interpreter_util_pkg.all;
use work.tb_interpreter_basic_pkg.all;
use work.tb_instructions_pkg.all;

package body tb_interpreter_pkg is
    
    procedure search_inst_element_ptr( 
        variable inst_list : in stim_line_ptr;
        variable search_for_inst_element_number : in integer;
        variable last_searched_inst_element_number : inout integer;
        variable last_searched_inst_element_ptr : inout stim_line_ptr;
        variable inst_element_ptr : out stim_line_ptr
    ) is                               
        variable instr_ptr : stim_line_ptr;
    begin                                   
        -- get to the instruction indicated by the search_for_inst_element_number
        -- check to see if this number is before the last_searched_inst_element_number
        -- so search from start
        if last_searched_inst_element_number > search_for_inst_element_number then
            instr_ptr := inst_list;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = search_for_inst_element_number then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            instr_ptr := last_searched_inst_element_ptr;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = search_for_inst_element_number then
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
        variable inst_element_ptr : in stim_line_ptr;                                                                          
        variable file_list : in file_def_ptr;                             
        variable inst : out text_field;
        variable inst_len : out integer;
        variable par_text_fields : out parameter_text_field_array;  
        variable txt : out stm_text_ptr;
        variable txt_enclosing_quote : out character;
        variable file_name : out text_line;
        variable file_line : out integer
    ) is
        variable tmp_file_index : integer;
        variable tmp_file_def_ptr : file_def_ptr;
    begin 
        inst := inst_element_ptr.inst;  
        inst_len := fld_len(inst_element_ptr.inst); 
        par_text_fields := inst_element_ptr.inst_parameters;
        txt := instr_ptr.txt;
        txt_enclosing_quote := instr_ptr.txt_enclosing_quote; 
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
        variable file_name : in text_line;
        variable file_line : in integer;
        variable var_scope_par1 : in text_field;     
        variable var_scope_par_others : in text_field;         
        variable par_text_fields : in parameter_text_field_array;
        variable par_indexes : out parameter_index_array;
        variable par_values : out parameter_value_array
    ) is
        variable var_scope : text_field;
        variable valid : integer;      
    begin 
        for i in 1 to 6 loop
            var_scope := var_scope_par_others;
            if i = 1 then
                var_scope := var_scope_par1;
            end if;
            if par_text_fields(i) /= nul then
                if is_digit(par_text_fields(i)(1)) then
                    par_values(i) := stim_to_stm_value(par_text_fields(i), file_name, file_line, par_text_fields(i)'length);
                else
                    access_variable(var_list, var_scope, par_text_fields(i), par_indexes(i), par_values(i), valid);
                    assert valid /= 0
                    report lf & "variable number " & (integer'image(i)) & " on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;        
        end loop;             
    end procedure;
    
    
   procedure read_include_file(variable pass : in integer;
                                constant path_name : string;
                                variable name : text_line;
                                variable inst_line_num : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set_list : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_list : inout stim_line_ptr;
                                variable status : inout integer;
                                constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable file_line_num : integer; -- line number file
        variable inst_line_num : integer; -- line number program
        variable ts : token_text_field_array;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_ptr : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
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
        variable scope_flags : t_stm_scope_flags;      
        
    begin
        inst_line_num := inst_line_num;
        nul_scope(1) := nul;
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
        file_line_num := 1; -- initialize line number
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
        v_instr_ptr := inst_set_list;
        v_var_ptr := var_list;
        v_sequ_ptr := inst_list;
        scope := nul_scope;
        scope_left := nul_scope;
        -- while not the end of file read it
        while not endfile(include_file) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_line(l, ts, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t(1));
            if t(1)(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
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
                    report lf & " include instruction is missing included file name paramater , found at:" & lf & "line " & (integer'image(file_line_num)) & " in file " & include_file_path_name & lf
                    severity failure;
                end if;
                print("nested include found in : " & include_file_path_name);
                check_presence_instruction_file_name(file_list, text_line_crop(v_iname), present);
                if present then
                    print("nested include found: not loading file since already present " & text_line_crop(v_iname));
                else
                    print("nested include found: loading file " & path_name & v_iname);
                    read_include_file(pass, path_name, v_iname, inst_line_num, v_tmp_fn, v_instr_ptr, v_var_ptr, v_sequ_ptr, v_ostat, stm_value_width);
                    -- if include file not found
                    if v_ostat = 1 then
                        exit;
                    end if;
                end if;
            -- if there was valid tokens
            elsif valid /= 0 then            
                check_valid_inst(t(1), v_instr_ptr, valid, file_line_num, v_iname);                      
                if pass = 0 then  
                    add_on_constant_declaration(v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_name, scope, stm_value_width);
                elsif pass = 1 then                  
                    add_on_variable_declaration(v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_name, scope, stm_value_width);
                else
                    add_instruction(v_sequ_ptr, v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_iname, v_new_fn, scope, stm_value_width);                
                end if;
            end if;
            file_line_num := file_line_num + 1;
        end loop; -- end loop read file
        file_close(include_file);
        inst_line_num := inst_line_num;
        inst_set_list := v_instr_ptr;
        var_list := v_var_ptr;
        inst_list := v_sequ_ptr;
    end procedure;

    procedure read_instruction_file(variable pass : in integer;
                                    constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set_list : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_list : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr;
                                    constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable file_line_num : integer; -- line number file
        variable inst_line_num : integer; -- line number program
        variable ts : token_text_field_array;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_ptr : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;
        variable scope : t_stm_scope;

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
        file_line_num := 1;
        inst_line_num := 1;
        v_ostat := 0;
        v_instr_ptr := inst_set_list;
        v_var_ptr := var_list;
        v_sequ_ptr := inst_list;
        init_scope_flags(scope_flags);
        -- while not the end of file read it
        while not endfile(stimulus) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_line(l, ts, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t(1));
            -- if there is an include instruction
            if t(1)(1 to v_len) = "include" then
                -- if file name is in par2
                if valid = 2 then
                    v_iname := (others => nul);
                    for i in 1 to max_field_len loop
                        v_iname(i) := t2(i);
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
                    report lf & " include instruction has not file name included.  found on" & lf & "line " & (integer'image(file_line_num)) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                print("include found: loading file " & path_name & v_iname);
                read_include_file(pass, path_name, v_iname, inst_line_num, v_tmp_fn, v_instr_ptr, v_var_ptr, v_sequ_ptr, v_ostat, stm_value_width);
                -- if include file not found
                if v_ostat = 1 then
                    exit;
                end if;
            -- if there were valid tokens
            elsif valid /= 0 then             
                check_valid_inst(t(1), v_instr_ptr, valid, file_line_num, v_name);  
                if pass = 0 then  
                    add_on_constant_declaration(v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_name, scope, stm_value_width);
                elsif pass = 1 then                  
                    add_on_variable_declaration(v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_name, scope, stm_value_width);
                else
                    add_instruction(v_sequ_ptr, v_var_ptr, ts(1), ts(2 to 6), inst_line_num, t_txt, txt_enclosing_quote,
                                    file_line_num, v_name, v_fn_idx, scope, stm_value_width);                
                end if;
            end if;
            file_line_num := file_line_num + 1;
        end loop; -- end loop read file
        file_close(stimulus); -- close the file when done
        assert v_ostat = 0
        report lf & "include file specified on line " & (integer'image(file_line_num)) & " in file " & path_name & file_name & " was not found! test terminated" & lf
        severity failure;
        inst_set_list := v_instr_ptr;
        var_list := v_var_ptr;
        inst_list := v_sequ_ptr;
        file_list := v_tmp_fn;
    end procedure;
    
--    procedure access_inst_list(
--                               variable mode_is_check : in boolean;
--                               variable inst_list : in stim_line_ptr;
--                               variable var_list : in var_field_ptr;
--                               variable file_list : in file_def_ptr;
--                               variable program_line_number_counter : in integer;
--                               variable instruction : out text_field;
--                               variable instruction_len : out integer;
--                               variable instruction_scope : out text_field;
--                               variable instruction_scope_left : out text_field;
--                               variable p1_text_field : out text_field;
--                               variable p2_text_field : out text_field;
--                               variable p3_text_field : out text_field;
--                               variable p4_text_field : out text_field;
--                               variable p5_text_field : out text_field;
--                               variable p6_text_field : out text_field;   
--                               variable txt : out stm_text_ptr;
--                               variable txt_enclosing_quote : out character;
--                               variable fname : out text_line;
--                               variable file_line : out integer;
--                               variable in_proc_advanced_parameters : inout boolean;                               
--                               variable in_call_advanced_parameters : inout boolean;
--                               variable in_proc_advanced_label_parameters : inout boolean;
--                               variable in_call_advanced_label_parameters : inout boolean;
--                               variable in_call_advanced_label : inout boolean;
--                               variable called_proc : inout text_field;
--                               variable target_proc_after_par_bracket_code_line_to_execute : inout integer;
--                               variable target_call_code_line_to_execute : inout integer                       
--                               ) is
--
--        variable instr : text_field;
--        variable instr_scope : text_field;
--        variable instr_scope_left : text_field;
--        variable instr_text_field : text_field;
--        variable instr_len : integer;
--        variable instr_ptr : stim_line_ptr;
--        variable valid : integer;
--        variable file_name : text_line;
--        variable tmp_file_index : integer;
--        variable tmp_file_def_ptr : file_def_ptr;
--        variable tmp_label_ptr : text_field_ptr;
--        variable tmp_proc: text_field;
--
--    begin 
--
--        p1_index := -1;
--        p2_index := -1;
--        p3_index := -1;
--        p4_index := -1;
--        p5_index := -1;
--        p6_index := -1;
--        par_text_fields(1) := to_unsigned(0, par_text_fields(1)'length) - 1;
--        par_text_fields(2) := to_unsigned(0, par_text_fields(1)'length) - 1;
--        par_text_fields(3) := to_unsigned(0, par_text_fields(1)'length) - 1;
--        par_text_fields(4) := to_unsigned(0, par_text_fields(1)'length) - 1;
--        par_text_fields(5) := to_unsigned(0, par_text_fields(1)'length) - 1;
--        par_text_fields(6) := to_unsigned(0, par_text_fields(1)'length) - 1;   
--                
--        -- get to the instruction indicated by code_line_to_execute
--        -- check to see if this sequence is before the last
--        -- so search from start
--        if last_searched_inst_element_number > program_line_number_pointer then
--            instr_ptr := inst_list;
--            while instr_ptr.next_rec /= null loop
--                if instr_ptr.line_number = program_line_number_pointer then
--                    exit;
--                else
--                    instr_ptr := instr_ptr.next_rec;
--                end if;
--            end loop;
--        -- else is equal or greater, so search forward
--        else
--            instr_ptr := last_searched_inst_element_ptr;
--            while instr_ptr.next_rec /= null loop
--                if instr_ptr.line_number = program_line_number_pointer then
--                    exit;
--                else
--                    instr_ptr := instr_ptr.next_rec;
--                end if;
--            end loop;
--        end if;
--        -- update the last sequence number and record pointer
--        last_searched_inst_element_number := program_line_number_pointer;
--        last_searched_inst_element_ptr := instr_ptr;
--        
--        instr := instr_ptr.instruction;
--        instruction := instr;    
--        instr_scope := instr_ptr.inst_scope;
--        instruction_scope := instr_scope;
--        instr_scope_left := instr_ptr.inst_scope_left;
--        instruction_scope_left := instr_scope_left;
--        instr_len := fld_len(instr);
--        instruction_len := instr_len;  
--        p1_text_field := instr_ptr.inst_parameters_1; 
--        p2_text_field := instr_ptr.inst_parameters_2; 
--        p3_text_field := instr_ptr.inst_parameters_3; 
--        p4_text_field := instr_ptr.inst_parameters_4; 
--        p5_text_field := instr_ptr.inst_parameters_5; 
--        p6_text_field := instr_ptr.inst_parameters_6; 
--        file_line := instr_ptr.file_line;
--        -- recover the file name this line came from
--        tmp_file_def_ptr := file_list;
--        tmp_file_index := instr_ptr.file_idx;
--        while tmp_file_def_ptr.next_rec /= null loop
--            if tmp_file_def_ptr.rec_idx = tmp_file_index then
--                exit;
--            end if;
--            tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
--        end loop;
--        for i in 1 to fname'high loop
--            file_name(i) := tmp_file_def_ptr.file_name(i);
--            fname(i) := tmp_file_def_ptr.file_name(i);
--        end loop;
--        
--        if instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_OPEN 
--           or instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_NOPAR_0 
--           or instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_NOPAR_1 then 
--            access_variable_label_ptr(var_list, instr_scope, p1_text_field, p1_index, tmp_label_ptr, valid);
--            assert valid /= 0
--            report lf & "call label variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--            severity failure;       
--            text_field_ptr_to_text_field(tmp_label_ptr, tmp_proc);          
--            in_proc_advanced_label_parameters := true;
--            called_proc := tmp_proc; 
--            access_variable(var_list, instr_scope, tmp_proc, p1_index, par_text_fields(1), valid);
--            assert valid /= 0
--            report lf & "call label proc variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--            severity failure;
--        elsif instruction(1 to instr_len) = INSTR_CALL_PAR_OPEN then                    
--            in_proc_advanced_parameters := true;
--            target_call_code_line_to_execute := code_line_to_execute;
--            access_variable(var_list, instr_scope_left, p1_text_field, p1_index, par_text_fields(1), valid);
--            assert valid /= 0
--            report lf & "call proc() variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--            severity failure;
--            next_alternate_code_line_to_execute := to_integer(par_text_fields(1)(30 downto 0)) - 1;
--            called_proc := instr_ptr.inst_parameters_1; 
--        elsif instruction(1 to instr_len) = INSTR_CALL 
--              or instr(1 to instr_len) = INSTR_CALL_PAR_NOPAR_0 
--              or instr(1 to instr_len) = INSTR_CALL_PAR_NOPAR_1 then 
--              access_variable(var_list, instr_scope_left, p1_text_field, p1_index, par_text_fields(1), valid);
--              assert valid /= 0
--              report lf & "call proc: variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--              severity failure;
--              next_alternate_code_line_to_execute := to_integer(par_text_fields(1)(30 downto 0)) - 1;                     
--              called_proc := instr_ptr.inst_parameters_1;                                    
--        elsif instr_text_field(1 to instr_len) = INSTR_PAR_CLOSE 
--              or instr(1 to instr_len) = INSTR_VAR_POINTER_COPY_PAR_CLOSE 
--              or instr(1 to instr_len) = INSTR_ARRAY_POINTER_COPY_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_LABEL_EQU_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_FILE_POINTER_COPY_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_LINES_POINTER_COPY_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE
--              or instr(1 to instr_len) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
--            if in_proc_advanced_parameters then
--                target_proc_after_par_bracket_code_line_to_execute := code_line_to_execute;
--                next_alternate_code_line_to_execute := target_call_code_line_to_execute;  
--                in_proc_advanced_parameters := false;  
--                in_call_advanced_parameters := true;
--            elsif in_proc_advanced_label_parameters then
--                target_proc_after_par_bracket_code_line_to_execute := code_line_to_execute;
--                next_alternate_code_line_to_execute := target_call_code_line_to_execute;  
--                in_proc_advanced_label_parameters := false;  
--                in_call_advanced_label_parameters := true; 
--            elsif in_call_advanced_parameters then  
--                next_alternate_code_line_to_execute := target_proc_after_par_bracket_code_line_to_execute;
--                in_call_advanced_parameters := false;
--                in_call_advanced_label := true;
--            elsif in_call_advanced_label_parameters then  
--                next_alternate_code_line_to_execute := target_proc_after_par_bracket_code_line_to_execute;
--                in_call_advanced_label_parameters := false;
--                in_call_advanced_label := true;
--            end if;
--        else       
--            txt := instr_ptr.txt;
--            txt_enclosing_quote := instr_ptr.txt_enclosing_quote;        
--            if p1_text_field(1) /= nul then
--                if is_digit(p1_text_field(1)) then
--                    par_text_fields(1) := stim_to_stm_value(p1_text_field, file_name, file_line, par_text_fields(1)'length);
--                else
--                    access_variable(var_list, scope_left, p1_text_field, p1_index, par_text_fields(1), valid);
--                    assert valid /= 0
--                    report lf & "first variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--            if p2_text_field(1) /= nul then
--                if is_digit(p2_text_field(1)) then
--                    par_text_fields(2) := stim_to_stm_value(p2_text_field, file_name, file_line, par_text_fields(2)'length);
--                else
--                    access_variable(var_list, var_scope, p2_text_field, p2_index, par_text_fields(2), valid);
--                    assert valid /= 0
--                    report lf & "second variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--            if p3_text_field(1) /= nul then
--                if is_digit(p3_text_field(1)) then
--                    par_text_fields(3) := stim_to_stm_value(p3_text_field, file_name, file_line, par_text_fields(3)'length);
--                else
--                    access_variable(var_list, var_scope, p3_text_field, p3_index, par_text_fields(3), valid);
--                    assert valid /= 0
--                    report lf & "third variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--            if p4_text_field(1) /= nul then
--                if is_digit(p4_text_field(1)) then
--                    par_text_fields(4) := stim_to_stm_value(p4_text_field, file_name, file_line, par_text_fields(4)'length);
--                else
--                    access_variable(var_list, var_scope, p4_text_field, p4_index, par_text_fields(4), valid);
--                    assert valid /= 0
--                    report lf & "forth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--            if p5_text_field(1) /= nul then
--                if is_digit(p5_text_field(1)) then
--                    par_text_fields(5) := stim_to_stm_value(p5_text_field, file_name, file_line, par_text_fields(5)'length);
--                else
--                    access_variable(var_list, var_scope, p5_text_field, p5_index, par_text_fields(5), valid);
--                    assert valid /= 0
--                    report lf & "fifth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--            if p6_text_field(1) /= nul then
--                if is_digit(p6_text_field(1)) then
--                    par_text_fields(6) := stim_to_stm_value(p6_text_field, file_name, file_line, par_text_fields(6)'length);
--                else
--                    access_variable(var_list, var_scope, p6_text_field, p6_index, par_text_fields(6), valid);
--                    assert valid /= 0
--                    report lf & "sixth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
--                    severity failure;
--                end if;
--            end if;
--        end if;
               
    end procedure;
    
end package body;
