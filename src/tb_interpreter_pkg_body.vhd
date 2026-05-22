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
--   Interpreter implementation for parsing stimulus files and executing SimStm instructions.
--
-- Upstream reference:
--   https://github.com/sckoarn/VHDL-Test-Bench
-------------------------------------------------------------------------------

use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;

package body tb_interpreter_pkg is

    procedure collect_code_files(
        variable slc : src_locator;
        variable code_files : inout file_def_list;
        variable root_to_to_current_dir_path : text_line;
        variable stimulus_file : text_line       
    ) is
        constant debug : boolean := false;
        variable fos : file_open_status;
        variable tl : text_line;
        variable ts : token_text_field_array;
        variable txt_obj : text_object;
        variable valid : integer;
        variable il : integer;
        variable include_file_path : text_line;
        variable file_line : integer;
        file stimulus : text;
        variable acfn : text_line;
        variable next_root_to_to_current_dir_path : text_line;
        variable cf_ptr : file_def_element_ptr;
        variable already_included : boolean;
    begin
        normalize_relative_file_path(root_to_to_current_dir_path, stimulus_file, acfn, debug);
        file_open(fos, stimulus, acfn, read_mode);
        assert fos = open_ok
        report "unable to open stimulus_file " & acfn
        severity failure;
        already_included := false;
        for i in 0 to code_files.last_element_num loop
            cf_ptr := code_files.element_ptrs(i);
            if fld_equal(cf_ptr.absolute_file_name, acfn) then
                -- report "stimulus file " & acfn & " already included"
                -- severity warning;
                already_included := true;
            end if;
        end loop;
        if not already_included then
            append_code_file(slc, code_files, acfn);
            print("loading codefile " & acfn);
            file_line := 0;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, txt_obj, valid);
                il := fld_len(ts(1));
                if ts(1)(1 to il) = "include" then
                    assert txt_obj.txt /= null
                    report "include instruction is missing file name " & "file " & acfn & "line " & integer'image(file_line)
                    severity failure;
                    include_file_path := (others => nul);
                    for i in 1 to c_stm_text_len loop
                        include_file_path(i) := txt_obj.txt(i);
                        if txt_obj.txt(i) = txt_obj.txt_enclosing_quote then
                            include_file_path(i) := nul;
                            exit;
                        end if;
                    end loop;    
                    next_root_to_to_current_dir_path := get_path_stem(acfn);
                    if debug then                          
                        print("next_root_to_to_current_dir_path " & next_root_to_to_current_dir_path); 
                        print("include_file_path " & include_file_path);    
                    end if;    
                    collect_code_files(slc, code_files, next_root_to_to_current_dir_path, include_file_path);
                end if;
            end loop;
        end if;
        file_close(stimulus);
    end procedure;


    procedure parse_labels(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer;
        constant debug : boolean
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;
        variable tl : text_line;
        variable il : integer;
        variable txt_obj : text_object;
        variable txt_obj_ptr : text_object_ptr;
        variable valid_tokens : integer;
        variable valid_params : integer;
        variable iic : stm_inst_initial_context;
        file stimulus : text;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable vn : text_field;
        variable ven1 : integer;
        variable val2 : unsigned(machine_value_width - 1 downto 0);
        variable fn : text_line;
        variable slc : src_locator;
    begin
        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            fn := code_files.element_ptrs(i).file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            init_inst_initial_context(iic);
            if debug then
                print("parsing code file for labels " & crop(fn));
            end if;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, txt_obj, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic);
                    il := fld_len(ts(1));
                    if ts(1)(1 to il) = INSTR_LABEL then
                        ie := new inst_element;
                        ie.slc := slc;
                        ie.inst := ts(1);
                        ie.inst_len := il;
                        ie.inst_namespace := iic.namespace_name;
                        extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                        txt_obj_ptr := new text_object;
                        txt_obj_ptr.txt := txt_obj.txt;
                        txt_obj_ptr.txt_enclosing_quote := txt_obj.txt_enclosing_quote;
                        ie.inst_args.txt_obj := txt_obj_ptr;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        vn := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                        vn := append_scope(vn, iic.proc_name);
                        insert_var_element(ie.slc, vars, vn, ie.inst_args, T_LABEL, machine_value_width, debug, ven1);
                    end if;
                end if;
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;


    procedure parse_constants(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer;
        constant debug : boolean
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;
        variable tl : text_line;
        variable il : integer;
        variable txt_obj : text_object;
        variable txt_obj_ptr : text_object_ptr;
        variable valid_tokens : integer;
        variable valid_params : integer;
        variable iic : stm_inst_initial_context;
        file stimulus : text;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable vn : text_field;
        variable ven1 : integer;
        variable val2 : unsigned(machine_value_width - 1 downto 0);
        variable fn : text_line;
        variable slc : src_locator;
    begin
        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            fn := code_files.element_ptrs(i).file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            init_inst_initial_context(iic);
            if debug then
                print("parsing code file for constants " & crop(fn));
            end if;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, txt_obj, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic);
                    il := fld_len(ts(1));
                    if ts(1)(1 to il) = INSTR_CONST then
                        ie := new inst_element;
                        ie.slc := slc;
                        ie.inst := ts(1);
                        ie.inst_len := il;
                        ie.inst_namespace := iic.namespace_name;
                        extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                        txt_obj_ptr := new text_object;
                        txt_obj_ptr.txt := txt_obj.txt;
                        txt_obj_ptr.txt_enclosing_quote := txt_obj.txt_enclosing_quote;
                        ie.inst_args.txt_obj := txt_obj_ptr;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        vn := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                        vn := append_scope(vn, iic.proc_name);
                        insert_var_element(ie.slc, vars, vn, ie.inst_args, T_CONST, machine_value_width, debug, ven1);
                        val2 := ie.inst_args.par_literal_values(2);
                        vars.element_ptrs(ven1).values(0) := val2;
                        -- dump_var_pool_ordered(vars, machine_value_width);
                    end if;
                end if;
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;

    procedure parse_variables(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : in integer;
        constant debug : boolean
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;
        variable tl : text_line;
        variable il : integer;
        variable txt_obj : text_object;
        variable txt_obj_ptr : text_object_ptr;
        variable valid_tokens : integer;
        variable valid_params : integer;
        variable iic : stm_inst_initial_context;
        variable vn1 : text_field;
        variable ven1 : integer;
        variable ven2 : integer;
        variable val2 : unsigned(machine_value_width - 1 downto 0);
        variable var_type : stm_var_type;
        file stimulus : text;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable fn : text_line;
        variable slc : src_locator;
        variable empty_text_field : text_field := (others => nul);
    begin

        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            fn := code_files.element_ptrs(i).file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            init_inst_initial_context(iic);
            if debug then
                print("parsing code file for variables " & crop(fn));
            end if;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, txt_obj, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic);
                    il := fld_len(ts(1));
                    if ts(1)(1 to il) /= INSTR_CONST
                       and ts(1)(1 to il) /= INSTR_LABEL
                    then
                        ie := new inst_element;
                        ie.slc := slc;
                        ie.inst := ts(1);
                        ie.inst_len := il;
                        ie.inst_namespace := iic.namespace_name;
                        extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                        txt_obj_ptr := new text_object;
                        txt_obj_ptr.txt := txt_obj.txt;
                        txt_obj_ptr.txt_enclosing_quote := txt_obj.txt_enclosing_quote;
                        ie.inst_args.txt_obj := txt_obj_ptr;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        set_var_type(ie.inst, il, var_type);
                        if var_type /= T_NO_VAR then
                            vn1 := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                            vn1 := append_scope(vn1, iic.proc_name);
                            if ie.inst_args.par_types(2) = PAR_LIT or var_type = T_TEXT or var_type = T_LINES or var_type = T_LABEL then
                                insert_var_element(ie.slc, vars, vn1, ie.inst_args, var_type, machine_value_width, debug, ven1);
                            else
                                access_inst_par_index(ie, vars, 2, ie.inst_namespace, iic.called_proc_name, ven2);
                                if ven2 > -1 then
                                    access_inst_par_index(ie, vars, 2, ie.inst_namespace, empty_text_field, ven2);
                                end if;            
                                assert ven2 > -1
                                report "var not found " & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                                severity failure;                                 
                                val2 := vars.element_ptrs(ven2).values(0);
                                ie.inst_args.par_literal_values(2) := val2;
                                insert_var_element(ie.slc, vars, vn1, ie.inst_args, var_type, machine_value_width, debug, ven1);
                            end if;
                        end if;
                    end if;
                end if;
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;

    procedure parse_instructions_and_procs(
        variable code_files : in file_def_list;
        variable inst_defs : in inst_def_list;
        variable insts : inout inst_sequence;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer;
        constant debug : boolean
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;
        variable tl : text_line;
        variable il : integer;
        variable txt_obj : text_object;
        variable txt_obj_ptr : text_object_ptr;
        variable valid_tokens : integer;
        variable valid_params : integer;
        variable iic : stm_inst_initial_context;
        variable var_type : stm_var_type;
        variable proc_type : boolean;
        file stimulus : text;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable pen : integer;
        variable nn : text_field;
        variable pn : text_field;
        variable fn : text_line;
        variable slc : src_locator;
    begin

        for i in 0 to code_files.last_element_num loop
            afn := code_files.element_ptrs(i).absolute_file_name;
            fn := code_files.element_ptrs(i).file_name;
            file_open(fos, stimulus, afn, read_mode);
            assert fos = open_ok
            report "unable to open code file  " & afn
            severity failure;
            file_line := 0;
            init_inst_initial_context(iic);
            if debug then
                print("parsing code file for procs and instructions " & crop(fn));
            end if;
            while not endfile(stimulus) loop
                file_line := file_line + 1;
                file_read_line(stimulus, tl);
                tokenize_inst_line(tl, ts, txt_obj, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic);
                    il := fld_len(ts(1));
                    ie := new inst_element;
                    ie.slc := slc;
                    ie.inst := ts(1);
                    ie.inst_len := il;
                    ie.inst_namespace := iic.namespace_name;
                    extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                    txt_obj_ptr := new text_object;
                    txt_obj_ptr.txt := txt_obj.txt;
                    txt_obj_ptr.txt_enclosing_quote := txt_obj.txt_enclosing_quote;
                    ie.inst_args.txt_obj := txt_obj_ptr;
                    valid_params := valid_tokens - 1;
                    check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                    set_var_type(ie.inst, il, var_type);
                    set_proc_type(ie.inst, il, proc_type);
                    if var_type = T_NO_VAR and proc_type = false then
                        -- anything but a constant, variable or proc definition, thus always an instruction
                        append_inst(insts, ie, debug);
                    else
                        if var_type /= T_CONST then
                            -- constant definitions and declarations are already done in pass 0 and are never added as an instruction
                            -- variable definitions and declaration already done in pass 1 but need to be an instruction too in case of living in proc parameters or proc local area be reinitilized on each call.
                            -- procs refer to an inst element thus can only be done when instructions are parsed and have an element number assigned
                            if proc_type then
                                -- a new proc e.g., PROC A_PROCNAME, to be added as instruction
                                nn := ie.inst_namespace;
                                pn := ie.inst_args.par_text_fields(1);
                                assert not contains_dot(pn)
                                report "procedure names must'nt contain a dot "& " proc name " & crop(pn) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                                severity failure;
                                insert_proc_element(ie.slc, procs, nn, pn, debug, pen);
                                procs.element_ptrs(pen).pointer_to_ien := insts.last_element_num + 1;
                                append_inst(insts, ie, debug);
                            else
                                if iic.is_var_declaration then
                                    if iic.code_section = PROC_BODY or iic.code_section = PROC_PARAMS then
                                        -- any local var definition and declaration living in proc parameters or proc local area to be added as instruction
                                        append_inst(insts, ie, debug);
                                    end if;
                                else
                                    -- any other instruction
                                    append_inst(insts, ie, debug);
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end loop;
            file_close(stimulus);
        end loop;
    end procedure;

    procedure check_instructions_in_initial_context(
        variable insts : inout inst_sequence;
        variable vars : inout var_pool_ordered;
        variable procs : inout proc_pool_ordered;
        constant machine_value_width : integer       
    ) is
        variable iic : stm_inst_initial_context;
        variable par_scopes : parameter_text_field_array;
        variable par_value : unsigned(machine_value_width - 1 downto 0);
        variable slc : src_locator;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable ien : integer;
        variable pn : text_field;
        variable pen : integer;
        variable empty_text_field : text_field := (others => nul);
        variable found : boolean;
        constant debug : boolean := false;
        
    begin
        init_inst_initial_context(iic);
        for i in 0 to insts.last_element_num loop
            ien := i;
            if debug then  
--                if ien = 340 then 
--                    stop;
--                end if;
                print_inst_element(insts, ien);
            end if;
            ie := insts.element_ptrs(i);
            slc := ie.slc;
            ts(1) := ie.inst;
            for k in 1 to 6 loop
                ts(k + 1) := ie.inst_args.par_text_fields(k);
            end loop;
            track_inst_initial_context(slc, ts, vars, iic);
            if debug then 
                print_initial_instruction_context(iic);
            end if;
            if iic.code_section = PROC_BODY or iic.code_section = PROC_PARAMS then
                par_scopes := (others => iic.proc_name);
            end if;
            if iic.code_section = CALL_PARAMS then
                par_scopes := (1 => iic.called_proc_name, others => iic.proc_name);
            end if;
            if debug then 
                for k in 1 to 6 loop
                    print("par_scopes(" & integer'image(k) &") " & par_scopes(k));
                end loop;
            end if;
            if ie.inst(1 to ie.inst_len) /= INSTR_NAMESPACE
               and ie.inst(1 to ie.inst_len) /= INSTR_PROC_PAR_OPEN
               and ie.inst(1 to ie.inst_len) /= INSTR_PROC_NOPAR
               and ie.inst(1 to ie.inst_len) /= INSTR_INTERRUPT_NOPAR
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_PAR_OPEN
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_NOPAR
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_LABEL_PAR_OPEN
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_LABEL_NOPAR
            then
                for i in 1 to 6 loop
                    if ie.inst_args.par_text_fields(i)(1) /= nul then
                        case i is
                            when 1 =>                     
                                access_inst_par_value(ie, vars, i, ie.inst_namespace, par_scopes(i), found, par_value);
                                if not found then
                                    access_inst_par_value(ie, vars, i, ie.inst_namespace, empty_text_field, found, par_value);
                                end if;            
                                assert found 
                                report "variable not found " & crop(ie.inst_args.par_text_fields(i)) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                                severity failure;                                   
                            when 2 =>
                                if ie.inst(1 to ie.inst_len) = INSTR_LABEL 
                                    or ie.inst(1 to ie.inst_len) = INSTR_LABEL_SET 
                                then
                                    pn := ie.inst_args.par_text_fields(2);
                                    if contains_dot(pn) then
                                        access_proc_fqn(slc, procs, pn, pen);
                                    else
                                        access_proc_prepend_namespace(slc, procs, pn, ie.inst_namespace, pen);
                                    end if;                             
                                else
                                    if ie.inst(1 to ie.inst_len) /= INSTR_IF
                                        and ie.inst(1 to ie.inst_len) /= INSTR_ELSIF
                                    then
                                        access_inst_par_value(ie, vars, i, ie.inst_namespace, par_scopes(i), found, par_value);
                                        if not found then
                                            access_inst_par_value(ie, vars, i, ie.inst_namespace, empty_text_field, found, par_value);
                                        end if;            
                                        assert found 
                                        report "variable not found " & crop(ie.inst_args.par_text_fields(i)) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                                        severity failure; 
                                   end if;
                                end if;
                            when 3 to 6 =>
                                access_inst_par_value(ie, vars, i, ie.inst_namespace, par_scopes(i), found, par_value);
                                if not found then
                                    access_inst_par_value(ie, vars, i, ie.inst_namespace, empty_text_field, found, par_value);
                                end if;            
                                assert found 
                                report "variable not found " & crop(ie.inst_args.par_text_fields(i)) & " file name " & crop(ie.slc.file_name) & " file line " & integer'image(ie.slc.file_line)
                                severity failure; 
                        end case;
                    end if;
                end loop;
            end if;
        end loop;
    end procedure;

end package body;
