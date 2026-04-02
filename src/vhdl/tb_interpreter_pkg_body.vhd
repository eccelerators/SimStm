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
use work.tb_interpreter_util_pkg.all;

package body tb_interpreter_pkg is
    
    procedure collect_code_files(
        variable slc : src_locator;
        variable code_files : inout file_def_list;
        constant stimulus_path : string;
        variable stimulus_file : string
    ) is 
        variable fos : file_open_status;
        variable tl : text_line;
        variable ts : token_text_field_array;
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable il : integer;
        variable tll : integer;
        variable include_file_name : text_line;
        variable file_line : integer; 
        file stimulus : text;
        variable absolute_code_file_name : text_line;
    begin
        absolute_code_file_name := combine_to_absolute_file_name(stimulus_path, stimulus_file);
        file_open(fos, stimulus, absolute_code_file_name, read_mode);
        assert fos = open_ok
        report "unable to open stimulus_file " & absolute_code_file_name
        severity failure; 
        append_code_file(slc, code_files, stimulus_path, stimulus_file);
        print("loading codefile " & absolute_code_file_name);
        file_line := 0;  
        while not endfile(stimulus) loop
            file_line := file_line + 1;
            file_read_line(stimulus, tl);
            tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid);
            il := fld_len(ts(1));
            if ts(1)(1 to il) = "include" then
                assert txt /= null
                report "include instruction defines no file name as text parameter: " & 
                "file " & stimulus_path & stimulus_file & 
                "line " & integer'image(file_line)
                severity failure;            
                include_file_name := (others => nul);
                for i in 1 to c_stm_text_len loop
                    include_file_name(i) := txt(i);
                    if txt(i) = txt_enclosing_quote then
                        include_file_name(i) := nul;
                        exit;
                    end if;
                end loop;
                tll := text_line_len(include_file_name);
                collect_code_files(slc, code_files, stimulus_path, include_file_name(1 to tll));
            end if;
        end loop;
        file_close(stimulus);  
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
        variable val2 : unsigned(machine_value_width -1 downto 0);  
        variable fn : text_field;
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
                    track_inst_initial_context(slc, ts, vars, iic);
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
                        val2 := stim_to_stm_value(ie.slc, ie.inst_args.par_text_fields(2), machine_value_width);
                        vars.element_ptrs(ven1).values(0) := val2;
                        vars.element_ptrs(ven1).values_org(0) := val2;
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
        variable val2 : unsigned(machine_value_width -1 downto 0);    
        variable var_type : stm_var_type;
        file stimulus : text; 
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
        variable fn : text_field;
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
                    track_inst_initial_context(slc, ts, vars, iic);
                    il := fld_len(ts(1));       
                    if ts(1)(1 to il) /= INSTR_CONST then
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
                            if  ie.inst_args.par_types(2) = PAR_LIT or var_type = T_TEXT or var_type = T_LINES or var_type = T_LABEL then                                              
                                insert_var_element(ie.slc, vars, vn1, ie.inst_args, var_type, machine_value_width, debug, ven1);
                            else
                                access_inst_par_index_prefer_local(ie, vars, 2, iic.called_proc_name, ven2);
                                val2 := vars.element_ptrs(ven2).values(0);
                                ie.inst_args.par_text_fields(2) := to_text_field(val2);                              
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
        variable fn : text_field;
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
                    track_inst_initial_context(slc, ts, vars, iic);
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
                                insert_proc_element(ie.slc, procs, ie.inst_args.par_text_fields(1), debug, pen);
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
        variable par_value : unsigned(machine_value_width downto 0);
        variable slc : src_locator;
        variable ts : token_text_field_array;
        variable ie : inst_element_ptr;
    begin
        init_inst_initial_context(iic);
        for i in 0 to insts.last_element_num loop
            ie := insts.element_ptrs(i);
            slc := ie.slc;            
            ts(1) := ie.inst;
            for k in 1 to 6 loop
                ts(k + 1) := ie.inst_args.par_text_fields(k);
            end loop;                                   
            track_inst_initial_context(slc, ts, vars, iic);
            if iic.code_section = PROC_BODY or iic.code_section = PROC_PARAMS then
                par_scopes := (others => iic.proc_name);
            end if;
            if iic.code_section = CALL_PARAMS then
                par_scopes := (1 => iic.called_proc_name, others => iic.proc_name);
            end if;
            for i in 1 to 6 loop
                if ie.inst_args.par_text_fields(i)(1) /= nul then
                    case i is
                        when 1 => 
                            access_inst_par_value_prefer_local(ie, vars, 1, par_scopes(1), par_value);
                        when 2 => 
                            access_inst_par_value_prefer_local(ie, vars, 2, par_scopes(2), par_value);
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
        end loop;
    end procedure;
        
end package body;
