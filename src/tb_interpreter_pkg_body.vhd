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
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable il : integer;
        variable tll : integer;
        variable include_file_path : text_line;
        variable file_line : integer;
        file stimulus : text;
        variable acfn : text_line;
        variable next_root_to_to_current_dir_path : text_line;
    begin
        normalize_relative_file_path(root_to_to_current_dir_path, stimulus_file, acfn, debug);
        file_open(fos, stimulus, acfn, read_mode);
        assert fos = open_ok
        report "unable to open stimulus_file " & acfn
        severity failure;
        append_code_file(slc, code_files, acfn);
        print("loading codefile " & acfn);
        file_line := 0;
        while not endfile(stimulus) loop
            file_line := file_line + 1;
            file_read_line(stimulus, tl);
            tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid);
            il := fld_len(ts(1));
            if ts(1)(1 to il) = "include" then
                assert txt /= null
                report "include instruction is missing file name: " & "file " & acfn & "line " & integer'image(file_line)
                severity failure;
                include_file_path := (others => nul);
                for i in 1 to c_stm_text_len loop
                    include_file_path(i) := txt(i);
                    if txt(i) = txt_enclosing_quote then
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
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic, false);
                    il := fld_len(ts(1));
                    if ts(1)(1 to il) = INSTR_LABEL then
                        ie := new inst_element;
                        ie.slc := slc;
                        ie.inst := ts(1);
                        ie.inst_len := il;
                        ie.inst_namespace := iic.namespace_name;
                        extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                        ie.inst_args.txt := txt;
                        ie.inst_args.txt_enclosing_quote := txt_enclosing_quote;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        vn := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                        vn := append_dot(vn);
                        insert_var_element(ie.slc, vars, vn, ie.inst_args, T_LABEL, machine_value_width, debug, ven1);
                        val2 := ie.inst_args.par_literal_values(2);
                        vars.element_ptrs(ven1).values(0) := val2;
                        vars.element_ptrs(ven1).values_org(0) := val2;
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
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic, true);
                    il := fld_len(ts(1));
                    if ts(1)(1 to il) = INSTR_CONST then
                        ie := new inst_element;
                        ie.slc := slc;
                        ie.inst := ts(1);
                        ie.inst_len := il;
                        ie.inst_namespace := iic.namespace_name;
                        extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                        ie.inst_args.txt := txt;
                        ie.inst_args.txt_enclosing_quote := txt_enclosing_quote;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        vn := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                        vn := append_local_scope(vn, iic.proc_name);
                        insert_var_element(ie.slc, vars, vn, ie.inst_args, T_CONST, machine_value_width, debug, ven1);
                        val2 := ie.inst_args.par_literal_values(2);
                        vars.element_ptrs(ven1).values(0) := val2;
                        vars.element_ptrs(ven1).values_org(0) := val2;
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
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic, true);
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
                        ie.inst_args.txt := txt;
                        ie.inst_args.txt_enclosing_quote := txt_enclosing_quote;
                        valid_params := valid_tokens - 1;
                        check_valid_inst(ie.slc, inst_defs, ie.inst, valid_params);
                        set_var_type(ie.inst, il, var_type);
                        if var_type /= T_NO_VAR then
                            vn1 := prepend_namespace(ie.inst_args.par_text_fields(1), iic.namespace_name);
                            vn1 := append_local_scope(vn1, iic.proc_name);
                            if ie.inst_args.par_types(2) = PAR_LIT or var_type = T_TEXT or var_type = T_LINES or var_type = T_LABEL then
                                insert_var_element(ie.slc, vars, vn1, ie.inst_args, var_type, machine_value_width, debug, ven1);
                            else
                                access_inst_par_index_prefer_local(ie, vars, 2, iic.called_proc_name, ven2);
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
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid_tokens : integer;
        variable valid_params : integer;
        variable iic : stm_inst_initial_context;
        variable var_type : stm_var_type;
        variable proc_type : boolean;
        file stimulus : text;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable pen : integer;
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                if valid_tokens /= 0 then
                    slc.file_name := fn;
                    slc.file_line := file_line;
                    track_inst_initial_context(slc, ts, vars, iic, true);
                    il := fld_len(ts(1));
                    ie := new inst_element;
                    ie.slc := slc;
                    ie.inst := ts(1);
                    ie.inst_len := il;
                    ie.inst_namespace := iic.namespace_name;
                    extract_parameters(slc, ts, ie.inst_args.par_text_fields, ie.inst_args.par_types, ie.inst_args.par_literal_values, machine_value_width);
                    ie.inst_args.txt := txt;
                    ie.inst_args.txt_enclosing_quote := txt_enclosing_quote;
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
                                pn := ie.inst_args.par_text_fields(1);
                                if not contains_dot(pn) then
                                    pn := prepend_namespace(pn, ie.inst_namespace);
                                end if;
                                insert_proc_element(ie.slc, procs, pn, debug, pen);
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
        variable pn_is_fqn : boolean;
        variable pen : integer;
    begin
        init_inst_initial_context(iic);
        for i in 0 to insts.last_element_num loop
            ien := i;
            -- print_inst_element(insts, ien);
            ie := insts.element_ptrs(i);
            slc := ie.slc;
            ts(1) := ie.inst;
            for k in 1 to 6 loop
                ts(k + 1) := ie.inst_args.par_text_fields(k);
            end loop;
            track_inst_initial_context(slc, ts, vars, iic, true);
            if iic.code_section = PROC_BODY or iic.code_section = PROC_PARAMS then
                par_scopes := (others => iic.proc_name);
            end if;
            if iic.code_section = CALL_PARAMS then
                par_scopes := (1 => iic.called_proc_name, others => iic.proc_name);
            end if;
            if ie.inst(1 to ie.inst_len) /= INSTR_NAMESPACE
               and ie.inst(1 to ie.inst_len) /= INSTR_PROC_PAR_OPEN
               and ie.inst(1 to ie.inst_len) /= INSTR_PROC_NOPAR
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_PAR_OPEN
               and ie.inst(1 to ie.inst_len) /= INSTR_CALL_NOPAR
            then
                for i in 1 to 6 loop
                    if ie.inst_args.par_text_fields(i)(1) /= nul then
                        case i is
                            when 1 =>
                                access_inst_par_value_prefer_local(ie, vars, 1, par_scopes(1), par_value);
                            when 2 =>
                                if ie.inst(1 to ie.inst_len) = INSTR_LABEL then
                                    pn := ie.inst_args.par_text_fields(2);
                                    if contains_dot(pn) then
                                        pn_is_fqn := true;
                                    else
                                        pn_is_fqn := false;
                                    end if;
                                    access_proc(slc, procs, ie.inst_namespace, pn, pn_is_fqn, pen);
                                else
                                    if ie.inst(1 to ie.inst_len) /= INSTR_IF
                                        and ie.inst(1 to ie.inst_len) /= INSTR_ELSIF
                                    then
                                        access_inst_par_value_prefer_local(ie, vars, 2, par_scopes(2), par_value);
                                    end if;
                                end if;
                            when 3 =>
                                access_inst_par_value_prefer_local(ie, vars, 3, par_scopes(3), par_value);
                            when 4 =>
                                access_inst_par_value_prefer_local(ie, vars, 4, par_scopes(4), par_value);
                            when 5 =>
                                access_inst_par_value_prefer_local(ie, vars, 5, par_scopes(5), par_value);
                            when 6 =>
                                access_inst_par_value_prefer_local(ie, vars, 6, par_scopes(6), par_value);
                        end case;
                    end if;
                end loop;
            end if;
        end loop;
    end procedure;

end package body;
