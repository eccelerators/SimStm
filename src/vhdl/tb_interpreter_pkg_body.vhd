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
 
    procedure access_inst_element_parameters(
        variable ie : inst_element;
        variable vars : in var_field_ptr;
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
                    par_values(i) := stim_to_stm_value(par_text_fields(i), ie.src_loc, par_text_fields(i)'length);
                else
                    access_var(vars, par_scopes(i), par_text_fields(i), par_indexes(i), par_values(i), valid);
                    assert valid /= 0
                    report "variable in parameter number " & (integer'image(i)) & " is not valid!!" & lf &
                    "file " & ie.src_loc.file_name & lf &
                    "line " & (integer'image(ie.src_loc.file_line))
                    severity failure;
                end if;
            end if;
        end loop;
    end procedure;
    
    procedure collect_code_files(
        variable code_files : inout file_def_list;
        constant absolute_code_file_name : in text_line
    ) is 
        variable fos : file_open_status;
        variable tl : text_line;
        variable ts : token_text_field_array;
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable il : integer;
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
            tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid);
            il := fld_len(ts(1));
            if ts(1)(1 to il) = "include" then
                assert txt /= null
                report "include instruction defines no file name as text parameter: " & lf &
                "file " & path_name & file_name & lf &
                "line " & integer'image(file_line)
                severity failure;            
                absolut_include_file_name := (others => nul);
                for i in 1 to c_stm_text_len loop
                    absolut_include_file_name(i) := txt(i);
                    if txt(i) = txt_enclosing_quote then
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
        variable machine_value_width : integer;
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
        variable iic : stm_inst_initial_context;
        variable var_type : stm_var_type;
    begin
        init_inst_initial_context(iic);
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                il := fld_len(ts(1));
                if valid_tokens /= 0 then
                    inst := ts(1);
                    ia.par_text_fields := extract_parameter_text_fields(ts);
                    ia.txt := txt;
                    ia.txt_enclosing_quote := txt_enclosing_quote;
                    slc.file_name := afn;
                    slc.file_line := file_line;
                    check_valid_inst(slc, inst_defs, inst, valid_tokens);
                    track_inst_initial_context(slc, inst, inst_args, vars, iic);
                    if inst(1 to il) = INSTR_CONST then
                        var_type := STM_CONST;
                        vn := textfield_dot_cat(iic.in_namespace_name, inst_args.par_text_fields(1), iic.in_proc_name);
                        insert_var_element(slc, vars, vn, inst_args, var_type, var_element_num, machine_value_width, debug);
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
        variable machine_value_width : in integer;
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
        variable valid_ckeck : integer;
        variable iic : stm_inst_initial_context;
        variable c_var_index : integer;
        variable c_var_value : unsigned(machine_value_width -1 downto 0);
        variable c_valid : integer;
        variable n_par_text_fields : parameter_text_field_array;       
        variable vn : text_field;
        variable var_type : stm_var_type;
    begin
        init_inst_initial_context(ipc);
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                il := fld_len(ts(1));
                if valid_tokens /= 0 then
                    inst := ts(1);
                    ia.par_text_fields := extract_parameter_text_fields(ts);
                    ia.txt := txt;
                    ia.txt_enclosing_quote := txt_enclosing_quote;
                    slc.file_name := afn;
                    slc.file_line := file_line;
                    check_valid_inst(slc, inst_defs, inst, valid_tokens);
                    track_inst_initial_context(slc, inst, inst_args, vars, iic);
                    set_var_type(inst, il, var_type);
                    if var_type /= STM_NO_VAR then
                        vn := textfield_dot_cat(iic.in_namespace_name, inst_args.par_text_fields(1), iic.in_proc_name);
                        if is_digit(par_text_fields(2)(1)) or var_type = STM_TEXT or var_type = STM_LINES or var_type = STM_LABEL then                   
                            insert_var_element(slc, vars, vn, inst_args, var_type, var_element_num, machine_value_width, debug);
                        else
                            access_var(var_list, var_scope, par_text_fields(2), c_var_index, c_var_value, c_valid);
                            assert c_valid /= 0
                            report "constant " & par_text_fields(2) & " to initialize variable " & par_text_fields(1) & ", var_scope:'" & var_scope & " not found"
                            severity failure;
                            n_par_text_fields := par_text_fields;
                            n_par_text_fields(2) := to_text_field(c_var_value);
                            insert_var_element(slc, vars, vn, inst_args, var_type, var_element_num, machine_value_width, debug);
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
        variable procs : inout proc_pool_ordered; 
        variable machine_value_width : integer;
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
        variable valid_ckeck : integer;
        variable iic : stm_inst_initial_context;
        variable var_type : stm_var_type;
        variable proc_type : boolean;
    begin
        init_inst_initial_context(iic);
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
                tokenize_inst_line(tl, ts, txt, txt_enclosing_quote, valid_tokens);
                il := fld_len(ts(1));
                if valid_tokens /= 0 then
                    inst := ts(1);
                    ia.par_text_fields := extract_parameter_text_fields(ts);
                    ia.txt := txt;
                    ia.txt_enclosing_quote := txt_enclosing_quote;
                    slc.file_name := afn;
                    slc.file_line := file_line;
                    check_valid_inst(slc, inst_defs, inst, valid_tokens);
                    track_inst_initial_context(slc, inst, inst_args, vars, iic);
                    set_var_type(inst, il, var_type);
                    set_proc_type(inst, il, proc_type);      
                    if var_type = STM_NO_VAR and proc_type = false then
                        -- anything but a constant, variable or proc definition, thus always an instruction
                        append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
                    else
                        if var_type /= STM_CONST_VALUE then 
                            -- constant definitions and declarations are already done in pass 0 and are never added as an instruction
                            -- variable definitions and declaration already done in pass 1 but need to be an instruction too in case of living in proc parameters or proc local area be reinitilized on each call.
                            -- procs refer to an inst element thus can only be done when instructions are parsed and have an element number assigned
                            if proc_type then
                                if inst_context.in_proc_advanced then
                                    -- a new proc e.g., PROC A_PROCNAME, to be added as instruction
                                    insert_proc_element(file_name, file_line, procs, par_text_fields(1), insts.last_element_num + 1);
                                    append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
                                end if;
                            else
                                if var_scope(var_scope'length) /= '.' then
                                    -- any other local var definition and declaration living in proc parameters or proc local area to be added as instruction
                                    append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
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
        variable machine_value_width : integer       
    ) is
        variable fos : file_open_status;
        variable afn : text_line;
        variable file_line : integer;        
        variable tl : text_line;
        variable len : integer;
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid_tokens : integer;
        variable valid_ckeck : integer;
        variable ipc : stm_inst_initial_context;
    begin
        init_inst_initial_context(ipc);
        for i in 0 to insts.last_element_num loop
            ie := insts.element_ptrs(i);
            track_inst_initial_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
            access_inst_element_parameters(var_list, file_line, file_name, par_scopes, par_text_fields, par_indexes, par_values);
        end loop;
    end procedure;
        
end package body;
