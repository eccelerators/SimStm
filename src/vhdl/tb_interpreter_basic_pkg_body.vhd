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

package body tb_interpreter_basic_pkg is

    procedure track_inst_parse_context(
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable var_list : inout var_field_ptr;
        variable inst_parse_context : inout stm_inst_parse_context
    ) is
        variable il : integer;
        variable var_index : integer;
        variable tmp_label_ptr : text_field_ptr;
        variable tmp_proc : text_field;
        variable valid : integer;
    begin
        il := fld_len(inst);
        if inst(1 to il) = INSTR_NAMESPACE then
            inst_parse_context.in_namespace := true;
            inst_parse_context.in_namespace_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_NAMESPACE then
            inst_parse_context.in_namespace := false;
            inst_parse_context.in_namespace_name := (others => nul);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_OPEN then
            inst_parse_context.in_proc_parameters := true;
            inst_parse_context.in_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_NOPAR then
            inst_parse_context.in_proc_parameters := false;
            inst_parse_context.in_proc_body := true;
            inst_parse_context.in_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_PROC then
            inst_parse_context.in_proc_body := false;
            inst_parse_context.in_proc_name := (others => nul);
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
            if inst_parse_context.in_proc_parameters then
                inst_parse_context.in_proc_parameters := false;
                inst_parse_context.in_proc_body := true;
            end if;
            if inst_parse_context.in_call_parameters then
                inst_parse_context.in_call_parameters := false;
            end if;
            if inst_parse_context.in_call_label_advanced_parameters then
                inst_parse_context.in_call_label_advanced_parameters := false;
            end if;
        end if;
        if inst(1 to il) = INSTR_CALL_PAR_OPEN then
            inst_parse_context.in_call_parameters := true;
            inst_parse_context.in_called_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
            inst_parse_context.in_call_label_parameters := true;
            access_var_label_ptr(var_list, inst_parse_context.in_namespace_name, inst_parse_context.in_called_proc_name, var_index, tmp_label_ptr, valid);
            assert valid /= 0
            report lf & "initial context call label variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name & "line number " & (integer'image(file_line))
            severity failure;       
            text_field_ptr_to_text_field(tmp_label_ptr, tmp_proc);
            inst_parse_context.in_called_proc_name := tmp_proc;
        end if;
    end procedure;

    procedure add_var_on_constant_declaration(
        variable file_name : in text_line;
        variable file_line : in integer;
        variable vars : inout var_pool_ordered;
        variable inst_parse_context : inout stm_inst_parse_context;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer
    ) is
        variable var_type : t_stm_var_type;
        variable il : integer;
        variable var_scope : text_field;
        variable assigned_index : integer;
        constant debug : boolean := false;
    begin
        track_inst_parse_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        var_scope := textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name);
        var_type := STM_CONST_VALUE_TYPE;
        il := fld_len(inst);
        if inst(1 to il) = INSTR_CONST then
             -- constant definition and declaration
            insert_var_element(file_name, file_line, vars, var_scope, par_text_fields, var_type, str_ptr, txt_enclosing_quote, stm_value_width);
            if debug then
                print("add constant " & par_text_fields(1) & ", value '" & par_text_fields(2) & ", var_scope " & var_scope);
            end if;
        end if;
    end procedure;

    procedure add_var_on_variable_declaration(
        variable file_name : in text_line;
        variable file_line : in integer;
        variable vars : inout var_pool_ordered;
        variable inst_parse_context : inout stm_inst_parse_context;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer
    ) is
        variable var_type : t_stm_var_type;
        variable il : integer;
        variable var_scope : text_field;
        variable assigned_index : integer;
        variable c_var_index : integer;
        variable c_var_value : unsigned(stm_value_width -1 downto 0);
        variable c_valid : integer;
        variable n_par_text_fields : parameter_text_field_array;
        constant debug : boolean := false;
    begin
        track_inst_parse_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        var_scope := textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name);
        var_type := STM_NO_VAR;
        il := fld_len(inst);
        set_var_type(inst, il, var_type);
        if var_type /= STM_NO_VAR then
            -- variable definition and declaration
            if is_digit(par_text_fields(2)(1)) or var_type = STM_TEXT_TYPE or var_type = STM_LINES_TYPE or var_type = STM_LABEL_TYPE then                   
                insert_var_element(file_name, file_line, vars, var_scope, par_text_fields, var_type, str_ptr, txt_enclosing_quote, stm_value_width);
                if debug then
                    print("add var " & par_text_fields(1) & ", value " & par_text_fields(2) & ", var_scope " & var_scope);
                end if;
            else
                access_var(var_list, var_scope, par_text_fields(2), c_var_index, c_var_value, c_valid);
                assert c_valid /= 0
                report "constant " & par_text_fields(2) & " to initialize variable " & par_text_fields(1) & ", var_scope:'" & var_scope & " not found"
                severity failure;
                n_par_text_fields := par_text_fields;
                n_par_text_fields(2) := to_text_field(c_var_value);
                insert_var_element(file_name, file_line, vars, var_scope, n_par_text_fields, var_type, str_ptr, txt_enclosing_quote, stm_value_width);
                if debug then
                    print("add var " & par_text_fields(1) & ", value " & par_text_fields(2) & ", var_scope " & var_scope);
                end if;
            end if;
        end if;
    end procedure;

    procedure add_inst_and_proc_on_proc(
        variable file_name : in text_line;
        variable file_line : in integer;
        variable insts : inout inst_sequence; 
        variable procs : inout var_field_ptr;
        variable inst_parse_context : inout stm_inst_parse_context;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;  
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character
    ) is
        variable il : integer;
        variable var_type : t_stm_var_type;
        variable proc_type : boolean;
        constant debug : boolean := false;
    begin
        track_inst_parse_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        il := fld_len(inst);
        set_var_type(inst, il, var_type);
        set_proc_type(inst, il, proc_type);
        if var_type = STM_NO_VAR and proc_type = false then
            -- anything but a constant, variable or proc definition, thus always an instruction
            append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
            if debug then
                print("add instruction " & inst & ", element number " & integer'image(insts.last_element_num));
            end if;
        else
            if var_type /= STM_CONST_VALUE then 
                -- constant definitions and declarations are already done in pass 0 and are never added as an instruction
                -- variable definitions and declaration already done in pass 1 but need to be an instruction too in case of living in proc parameters or proc local area be reinitilized on each call.
                -- procs refer to an inst element thus can only be done when instructions are parsed and have an element number assigned
                if proc_type then
                    if inst_context.in_proc_advanced then
                        -- a new proc e.g., PROC A_PROCNAME, to be added as instruction
                        insert_proc_element(file_name, file_line, procs, par_text_fields(1), insts.last_element_num + 1);
                        if debug then
                            print("add proc " & par_text_fields(1) & ", inst_element_num " & integer'image(insts.last_element_num + 1));
                        end if;
                        append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
                        if debug then
                            print("add instruction " & inst & ", element number " & integer'image(insts.last_element_num));
                        end if;
                    end if;
                else
                    if var_scope(var_scope'length) /= '.' then
                        -- any other local var definition and declaration living in proc parameters or proc local area to be added as instruction
                        append_inst(file_name, file_line, insts, par_text_fields, str_ptr, txt_enclosing_quote);
                        if debug then
                            print("add instruction " & inst & ", element number " & integer'image(insts.last_element_num));
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end procedure;
          
    procedure insert_proc_element(
        variable procs : inout proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_inst_element_num : in integer;
        variable file_name : in text_line;
        variable file_line : in integer
    ) is
        variable ne : proc_element_ptr;
        variable su : slice;
        variable sl : slice;
        variable is_equ : boolean;
        variable is_less : boolean;
    begin
        ne := new proc_element_ptr;    
        ne.proc_name := proc_name;
        ne.proc_inst_element_num := proc_inst_element_num;
        ne.file_name := file_name;
        ne.file_line := file_line;
        if procs.last_element_num < 8 then
            insert_before := -1;
            for i in 0 to procs.last_element_num loop
                if order_is_less_than_failure_on_equal(procs.element_ptrs(i), proc_name, file_name, file_line) then
                    insert_before_proc_element_num := i;
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
                if order_is_less_than_failure_on_equal(procs.element_ptrs(i), proc_name, file_name, file_line) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;    
            end loop;
            insert_before := -1;
            for i in 0 to procs.last_element_num - 1 loop
                if order_is_less_than_failure_on_equal(procs.element_ptrs(i), proc_name, file_name, file_line) then
                    insert_before_proc_element_num := i;
                    exit;
                end if;              
            end loop;
            insert_before := -1;
            for i in s.left to s.right loop
                if order_is_less_than_failure_on_equal(procs.element_ptrs(i), proc_name, file_name, file_line) then
                    insert_before_proc_element_num := i;
                    exit;
                end if;              
            end loop;
        end if;  
        if insert_before_proc_element_num >= 0 then
           procs.element_ptrs(i + 1 to procs.last_element_num + 1) := procs.element_ptrs(i to procs.last_element_num);
           procs.element_ptrs(i) := ne;
           procs.last_element_num := procs.last_element_num + 1;
        else
           procs.element_ptrs(procs.last_element_num + 1) := ne;
           procs.last_element_num := procs.last_element_num + 1;
        end if;                
    end procedure;
    
    procedure insert_var_element(
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable file_name : in text_line;
        variable file_line : in integer;
        variable var_scope : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        constant var_stm_type : in t_stm_var_type;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer
    ) is
        variable ne : var_element_ptr;
        variable su : slice;
        variable sl : slice;
        
        procedure init_stm_lines_var is
        begin
            ne := new var_element;
            ne.var_name := par_text_fields(1); -- direct write of text_field
            ne.var_scope := var_scope; -- direct write of text_field
            ne.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, stm_value_width);
            ne.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, stm_value_width);
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_index := index;
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := null;
            ne.var_org_stm_array := null;
            ne.var_stm_lines := new t_stm_lines;
            ne.var_stm_lines.stm_line_list := null;
            ne.var_stm_lines.size := 0;
            ne.var_org_stm_lines := new t_stm_lines;
            ne.var_org_stm_lines.stm_line_list := null;
            ne.var_org_stm_lines.size := 0;
            ne.var_stm_type := var_stm_type;
            ne.file_name := file_name;
            ne.file_line := file_line;
        end procedure;

        procedure init_stm_array_var is
        begin
            ne := new var_element;
            ne.var_name := par_text_fields(1); -- direct write of text_field
            ne.var_scope := var_scope; -- direct write of text_field
            ne.var_index := index;
            ne.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, stm_value_width);
            ne.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, stm_value_width);
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := new t_stm_array(0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1 loop
                ne.var_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            ne.var_org_stm_array := new t_stm_array(0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1 loop
                ne.var_org_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            ne.var_stm_lines := null;
            ne.var_org_stm_lines := null;
            ne.var_stm_type := var_stm_type;
            ne.file_name := file_name;
            ne.file_line := file_line;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert str_ptr /= null
            report lf & "missing file name in file declaration " & (integer'image(file_line)) & " of file " & text_line_crop(file_name)
            severity failure;
            ne := new var_element;
            ne.var_name := par_text_fields(1); -- direct write of text_field
            ne.var_scope := var_scope; -- direct write of text_field
            ne.var_index := index;
            ne.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, stm_value_width);
            ne.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, stm_value_width);
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_stm_text := str_ptr;
            ne.var_stm_text_enclosing_quote := txt_enclosing_quote;
            ne.var_org_stm_text := str_ptr;
            ne.var_org_stm_text_enclosing_quote := txt_enclosing_quote;
            ne.var_stm_array := null;
            ne.var_org_stm_array := null;
            ne.var_stm_lines := null;
            ne.var_org_stm_lines := null;
            ne.var_stm_type := var_stm_type;
            ne.file_name := file_name;
            ne.file_line := file_line;
        end procedure;
        
        procedure init_label_var is
        begin
            ne := new var_element;
            ne.var_name := par_text_fields(1); -- direct write of text_field
            ne.var_scope := var_scope; -- direct write of text_field
            ne.var_index := index;
            ne.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, stm_value_width);
            ne.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, stm_value_width);
            ne.var_label := new text_field;
            text_field_to_text_field_ptr(par_text_fields(2), ne.var_label);
            ne.var_org_label := new text_field;
            text_field_to_text_field_ptr(par_text_fields(2), ne.var_org_label);
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := null;
            ne.var_org_stm_array := null;
            ne.var_stm_lines := null;
            ne.var_org_stm_lines := null;
            ne.var_stm_type := var_stm_type;
            ne.file_name := file_name;
            ne.file_line := file_line;
        end procedure;

        procedure init_value_var is
        begin
            ne := new var_element;
            ne.var_name := par_text_fields(1); -- direct write of text_field
            ne.var_scope := var_scope; -- direct write of text_field
            ne.var_index := index;
            ne.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_value(0) := stim_to_stm_value(par_text_fields(2), file_name, file_line, stm_value_width); -- convert text_field to unsigned
            ne.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            ne.var_org_value(0) := stim_to_stm_value(par_text_fields(2), file_name, file_line, stm_value_width); -- convert text_field to unsigned
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := null;
            ne.var_org_stm_array := null;
            ne.var_stm_lines := null;
            ne.var_org_stm_lines := null;
            ne.var_stm_type := var_stm_type;
            ne.file_name := file_name;
            ne.file_line := file_line;
        end procedure;

    begin
        case var_stm_type is
            when STM_LINES_TYPE =>
                init_stm_lines_var;
            when STM_ARRAY_TYPE =>
                init_stm_array_var;
            when STM_TEXT_TYPE =>
                init_stm_text_var;
            when STM_LABEL_TYPE =>
                init_label_var;
            when others =>
                init_value_var;
        end case;        
        if vars.last_element_num < 8 then
            insert_before := -1;
            for i in 0 to vars.last_element_num loop
                if order_is_less_than_failure_on_equal(vars.element_ptrs(i), var_name, file_name, file_line) then
                    insert_before_var_element_num := i;
                    exit;
                end if;              
            end loop;
        else
            s.left := 0;
            s.right := vars.last_element_num;           
            while s.right - s.left > 8 loop
                sl.left := s.left;
                sl.right := s.right / 2 - 1;
                su.left := sl.right + 1;
                su.right := sl.right;
                if order_is_less_than_failure_on_equal(vars.element_ptrs(i), var_name, file_name, file_line) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;    
            end loop;
            insert_before := -1;
            for i in 0 to vars.last_element_num - 1 loop
                if order_is_less_than_failure_on_equal(vars.element_ptrs(i), var_name, file_name, file_line) then
                    insert_before_var_element_num := i;
                    exit;
                end if;              
            end loop;
            insert_before := -1;
            for i in s.left to s.right loop
                if order_is_less_than_failure_on_equal(vars.element_ptrs(i), var_name, file_name, file_line) then
                    insert_before_var_element_num := i;
                    exit;
                end if;              
            end loop;
        end if;  
        if insert_before_var_element_num >= 0 then
           vars.element_ptrs(i + 1 to vars.last_element_num + 1) := vars.element_ptrs(i to vars.last_element_num);
           vars.element_ptrs(i) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        else
           vars.element_ptrs(vars.last_element_num + 1) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        end if;                
    end procedure;

end package body;
