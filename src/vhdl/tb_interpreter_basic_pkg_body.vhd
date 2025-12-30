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

    procedure track_inst_context(
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable var_list : inout var_field_ptr;
        variable inst_context : inout t_stm_inst_context
    ) is
        variable il : integer;
        variable var_index : integer;
        variable tmp_label_ptr : text_field_ptr;
        variable tmp_proc : text_field;
        variable valid : integer;
    begin
        il := fld_len(inst);
        if inst(1 to il) = INSTR_NAMESPACE then
            inst_context.in_namespace := true;
            inst_context.in_namespace_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_NAMESPACE then
            inst_context.in_namespace := false;
            inst_context.in_namespace_name := (others => nul);
        end if;
        if inst(1 to il) = INSTR_PROC then
            inst_context.in_proc_conventional := true;
            inst_context.in_proc_name := (others => nul);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_OPEN then
            inst_context.in_proc_advanced := true;
            inst_context.in_proc_advanced_parameters := true;
            inst_context.in_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_NOPAR then
            inst_context.in_proc_advanced := true;
            inst_context.in_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_PROC then
            inst_context.in_proc_conventional := false;
            inst_context.in_proc_advanced := false;
            inst_context.in_proc_name := (others => nul);
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
            if inst_context.in_proc_advanced_parameters then
                inst_context.in_proc_advanced_parameters := false;
            end if;
            if inst_context.in_call_advanced_parameters then
                inst_context.in_call_advanced_parameters := false;
            end if;
            if inst_context.in_call_label_advanced_parameters then
                inst_context.in_call_label_advanced_parameters := false;
            end if;
        end if;
        if inst(1 to il) = INSTR_CALL_PAR_OPEN then
            inst_context.in_call_advanced_parameters := true;
            inst_context.in_called_proc_name := par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
            inst_context.in_call_label_advanced_parameters := true;
            inst_context.in_called_proc_name := par_text_fields(1);
            access_var_label_ptr(var_list, inst_context.in_namespace_name, inst_context.in_called_proc_name, var_index, tmp_label_ptr, valid);
            assert valid /= 0
            report lf & "initial context call label variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name & "line number " & (integer'image(file_line))
            severity failure;       
            text_field_ptr_to_text_field(tmp_label_ptr, tmp_proc);
            inst_context.in_proc_advanced_parameters := true;
            inst_context.in_called_proc_name := tmp_proc;
        end if;
    end procedure;

    procedure add_var_on_constant_declaration(
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    ) is
        variable stm_var_type : t_stm_var_type;
        variable il : integer;
        variable var_scope : text_field;
        variable assigned_index : integer;
        constant debug : boolean := false;
    begin
        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        var_scope := textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name);
        stm_var_type := STM_CONST_VALUE_TYPE;
        il := fld_len(inst);
        if inst(1 to il) = INSTR_CONST then
             --  global or local constant, definition and declaration
            add_var(var_list, var_scope, par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
            if debug then
                print("add idx " & integer'image(assigned_index) & " constant '" & par_text_fields(1) & "' value '" & par_text_fields(2) & "' var_scope '" & var_scope  & "'");
            end if;
        end if;
    end procedure;

    procedure add_var_on_non_local_variable_declaration(
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    ) is
        variable stm_var_type : t_stm_var_type;
        variable il : integer;
        variable var_scope : text_field;
        variable assigned_index : integer;
        variable c_var_index : integer;
        variable c_var_value : unsigned(stm_value_width -1 downto 0);
        variable c_valid : integer;
        variable n_par_text_fields : parameter_text_field_array;
        constant debug : boolean := false;
    begin
        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        var_scope := textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name);
        stm_var_type := NO_VAR_TYPE;
        il := fld_len(inst);
        if inst(1 to il) = INSTR_VAR then
            stm_var_type := STM_VALUE_TYPE;
        elsif inst(1 to il) = INSTR_ARRAY then
            stm_var_type := STM_ARRAY_TYPE;
        elsif inst(1 to il) = INSTR_LINES then
            stm_var_type := STM_LINES_TYPE;
        elsif inst(1 to il) = INSTR_FILE then
            stm_var_type := STM_TEXT_TYPE;
        elsif inst(1 to il) = INSTR_BUS then
            stm_var_type := STM_BUS_TYPE;
        elsif inst(1 to il) = INSTR_SIGNAL then
            stm_var_type := STM_SIGNAL_TYPE;
        elsif inst(1 to il) = INSTR_LABEL then
            stm_var_type := STM_LABEL_TYPE;
        end if;
        if stm_var_type /= NO_VAR_TYPE then
            if var_scope(var_scope'length) = '.' then
                -- global variable definition and declaration in var_scope "." or top of a "a_namespace."
                if is_digit(par_text_fields(2)(1)) or stm_var_type = STM_TEXT_TYPE or stm_var_type = STM_LINES_TYPE or stm_var_type = STM_LABEL_TYPE then
                    add_var(var_list, var_scope, par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                    if debug then
                        print("add idx " & integer'image(assigned_index) & " global var '" & par_text_fields(1) & "' value '" & par_text_fields(2) & "' var_scope '" & var_scope  & "'");
                    end if;
                else
                    access_var(var_list, var_scope, par_text_fields(2), c_var_index, c_var_value, c_valid);
                    assert c_valid /= 0
                    report lf & "Constant '" & par_text_fields(2)(1 to fld_len(par_text_fields(2))) & "' to initialize variable '" & par_text_fields(1)(1 to fld_len(par_text_fields(1))) & "' var_scope:'" & var_scope(1 to fld_len(var_scope)) & "' not found !"
                    severity failure;
                    n_par_text_fields := par_text_fields;
                    n_par_text_fields(2) := to_text_field(c_var_value);
                    add_var(var_list, var_scope, n_par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                    if debug then
                        print("add idx " & integer'image(assigned_index) & " global var '" & par_text_fields(1) & "' value '" & par_text_fields(2) & "' var_scope '" & var_scope  & "'");
                    end if;
                end if;
            end if;
        end if;
    end procedure;

    procedure add_inst(
        variable inst_list : inout stim_line_ptr;
        variable var_list : inout var_field_ptr;
        variable inst : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : inout integer;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        variable file_line : in integer;
        variable file_name : in text_line;
        variable file_idx : in integer;
        variable inst_context : inout t_stm_inst_context;
        constant stm_value_width : in integer
    ) is
        variable inst_list_element : stim_line_ptr;
        variable tmp_inst_list_element_ptr : stim_line_ptr;
        variable il : integer;
        variable pl : integer;
        variable var_scope : text_field;
        variable assigned_index : integer;
        variable stm_var_type : t_stm_var_type := NO_VAR_TYPE;
        variable c_var_index : integer;
        variable c_var_value : unsigned(stm_value_width -1 downto 0);
        variable c_valid : integer;
        variable n_par_text_fields : parameter_text_field_array;
        variable valid_instruction : integer;
        constant debug : boolean := false;
    begin
        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
        var_scope := textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name);
        valid_instruction := 0;
        il := fld_len(inst);
        if inst(1 to il) = INSTR_VAR then
            stm_var_type := STM_VALUE_TYPE;
        elsif inst(1 to il) = INSTR_CONST then
            stm_var_type := STM_CONST_VALUE_TYPE;
        elsif inst(1 to il) = INSTR_ARRAY then
            stm_var_type := STM_ARRAY_TYPE;
        elsif inst(1 to il) = INSTR_LINES then
            stm_var_type := STM_LINES_TYPE;
        elsif inst(1 to il) = INSTR_FILE then
            stm_var_type := STM_TEXT_TYPE;
        elsif inst(1 to il) = INSTR_BUS then
            stm_var_type := STM_BUS_TYPE;
        elsif inst(1 to il) = INSTR_SIGNAL then
            stm_var_type := STM_SIGNAL_TYPE;
        elsif inst(il) = ':' then
            stm_var_type := STM_PROC_TYPE;
        elsif inst(1 to il) = INSTR_PROC_PAR_OPEN then
            stm_var_type := STM_PROC_TYPE;
        elsif inst(1 to il) = INSTR_PROC_PAR_NOPAR then
            stm_var_type := STM_PROC_TYPE;
        elsif inst(1 to il) = INSTR_LABEL then
            stm_var_type := STM_LABEL_TYPE;
        end if;

        if stm_var_type = NO_VAR_TYPE then
            valid_instruction := 1; -- anything but a declaration, thus always an instruction
        else
            if stm_var_type /= STM_CONST_VALUE_TYPE then 
                -- constant definition and declaration already done
                -- variable definition but proc vars and local vars already done
                -- proc vars refer to an inst element thus can only be done when instructions are parsed and have an element number assigned.
                -- local vars must be reinitialized upon entry of the respective call thus must end as an instruction too.
                if stm_var_type = STM_PROC_TYPE then
                    -- a proc 
                    if inst_context.in_proc_advanced then
                        -- a new proc e.g., PROC A_PROCNAME, to be added as instruction
                        n_par_text_fields := par_text_fields;
                        pl := fld_len(par_text_fields(1)) + 1;
                        n_par_text_fields(1) := par_text_fields(1);
                        n_par_text_fields(1)(pl) := ':';
                        add_var(var_list, var_scope, par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                        if debug then
                            print("add idx " & integer'image(assigned_index) & " proc label var () '" & par_text_fields(1) & " seq " & integer'image(inst_list_elment_num) & "' var_scope '" & var_scope  & "'");
                        end if;
                        valid_instruction := 1;
                    elsif inst_context.in_proc_conventional then
                        -- a conventional proc e.g., PROCNAME: , not to be added as instruction
                        add_var(var_list, var_scope, par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                        if debug then
                            print("add idx " & integer'image(assigned_index) & " proc label label var : '" & inst & " seq " & integer'image(inst_list_elment_num) & " var_scope '" & var_scope  & "'");
                        end if;
                    end if;
                else
                    -- any other var definition and declaration
                    if var_scope(var_scope'length) /= '.' then
                        -- any other local var definition and declaration, to be added as instruction
                        pl := fld_len(par_text_fields(1));
                        if is_digit(par_text_fields(2)(1)) or stm_var_type = STM_TEXT_TYPE or stm_var_type = STM_LINES_TYPE or stm_var_type = STM_LABEL_TYPE then
                            add_var(var_list, var_scope, par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                            if debug then
                                print("add idx " & integer'image(assigned_index) & " local var '" & par_text_fields(1) & "' value '" & par_text_fields(2) & "' var_scope '" & var_scope  & "'");
                            end if;
                            valid_instruction := 1;
                        else
                            access_var(var_list, var_scope, par_text_fields(2), c_var_index, c_var_value, c_valid);
                            assert c_valid /= 0
                            report lf & "Constant '" & par_text_fields(2)(1 to fld_len(par_text_fields(2))) & "' to initialize variable '" & par_text_fields(1)(1 to fld_len(par_text_fields(1))) & "' var_scope:'" & var_scope(1 to fld_len(var_scope)) & "' not found !"
                            severity failure;
                            n_par_text_fields := par_text_fields;
                            n_par_text_fields(2) := to_text_field(c_var_value);
                            add_var(var_list, var_scope, n_par_text_fields, inst_list_elment_num, file_line, file_name, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                            if debug then
                                print("add idx " & integer'image(assigned_index) & " global var '" & par_text_fields(1) & "' value '" & par_text_fields(2) & "' var_scope '" & var_scope  & "'");
                            end if;
                            valid_instruction := 1;
                        end if;
                    end if;
                end if;
            end if;
        end if;

        if valid_instruction = 1 then
            -- prepare the new inst_list_element record
            inst_list_element := new stim_line;
            inst_list_element.inst := inst;
            inst_list_element.parameters := par_text_fields;
            inst_list_element.txt := str_ptr;
            inst_list_element.txt_enclosing_quote := txt_enclosing_quote;
            inst_list_element.element_number := inst_list_elment_num;
            inst_list_element.file_idx := file_idx;
            inst_list_element.file_line := file_line;
            if debug then
                print("add instruction " & inst & " element number " & integer'image(inst_list_elment_num) & " var_scope '" & var_scope & "'");
            end if;
            tmp_inst_list_element_ptr := inst_list;
            -- if it is not the first instruction
            if inst_list /= null then
                while tmp_inst_list_element_ptr.next_rec /= null loop
                    tmp_inst_list_element_ptr := tmp_inst_list_element_ptr.next_rec;
                end loop;
                tmp_inst_list_element_ptr.next_rec := inst_list_element;
                inst_list.element_count := inst_list.element_count + 1;
            -- otherwise it is first instruction to be added
            else
                inst_list := inst_list_element;
                inst_list.element_count := 1;
            end if;
            inst_list_elment_num := inst_list_elment_num + 1;
            -- print_inst(inst_list_element);  -- for debug
        end if;
    end procedure;

    procedure add_var(
        variable var_list : inout var_field_ptr;
        variable var_scope : in text_field;
        variable par_text_fields : in parameter_text_field_array;
        variable inst_list_elment_num : in integer;
        variable file_line : in integer;
        variable file_name : in text_line;
        constant var_stm_type : in t_stm_var_type;
        variable str_ptr : in stm_text_ptr;
        variable txt_enclosing_quote : in character;
        constant stm_value_width : in integer;
        variable assigned_index : out integer
    ) is
        variable temp_var : var_field_ptr;
        variable current_ptr : var_field_ptr;
        variable index : integer := 1;

        procedure init_stm_lines_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := par_text_fields(1); -- direct write of text_field
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_label := null;
            temp_var.var_org_label := null;
            temp_var.var_index := index;
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_org_stm_text := null;
            temp_var.var_org_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_org_stm_array := null;
            temp_var.var_stm_lines := new t_stm_lines;
            temp_var.var_stm_lines.stm_line_list := null;
            temp_var.var_stm_lines.size := 0;
            temp_var.var_org_stm_lines := new t_stm_lines;
            temp_var.var_org_stm_lines.stm_line_list := null;
            temp_var.var_org_stm_lines.size := 0;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_array_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := par_text_fields(1); -- direct write of text_field
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_label := null;
            temp_var.var_org_label := null;
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_org_stm_text := null;
            temp_var.var_org_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := new t_stm_array(0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1 loop
                temp_var.var_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            temp_var.var_org_stm_array := new t_stm_array(0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(par_text_fields(2), file_name, file_line)-1 loop
                temp_var.var_org_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert str_ptr /= null
            report lf & "missing file name in file declaration " & (integer'image(file_line)) & " of file " & text_line_crop(file_name)
            severity failure;
            temp_var := new var_field;
            temp_var.var_name := par_text_fields(1); -- direct write of text_field
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_label := null;
            temp_var.var_org_label := null;
            temp_var.var_stm_text := str_ptr;
            temp_var.var_stm_text_enclosing_quote := txt_enclosing_quote;
            temp_var.var_org_stm_text := str_ptr;
            temp_var.var_org_stm_text_enclosing_quote := txt_enclosing_quote;
            temp_var.var_stm_array := null;
            temp_var.var_org_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_value_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := par_text_fields(1); -- direct write of text_field
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := stim_to_stm_value(par_text_fields(2), file_name, file_line, stm_value_width); -- convert text_field to unsigned
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := stim_to_stm_value(par_text_fields(2), file_name, file_line, stm_value_width); -- convert text_field to unsigned
            temp_var.var_label := null;
            temp_var.var_org_label := null;
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_org_stm_text := null;
            temp_var.var_org_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_org_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_label_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := par_text_fields(1); -- direct write of text_field
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_label := new text_field;
            text_field_to_text_field_ptr(par_text_fields(2), temp_var.var_label);
            temp_var.var_org_label := new text_field;
            text_field_to_text_field_ptr(par_text_fields(2), temp_var.var_org_label);
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_org_stm_text := null;
            temp_var.var_org_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_org_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_proc_var is
            variable l : integer;
        begin
            temp_var := new var_field;
            l := fld_len(par_text_fields(1));
            temp_var.var_name(1 to (l - 1)) := par_text_fields(1)(1 to (l - 1));
            temp_var.var_scope := var_scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(inst_list_elment_num, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(inst_list_elment_num, stm_value_width);
            temp_var.var_label := null;
            temp_var.var_org_label := null;
            temp_var.var_stm_text := null;
            temp_var.var_stm_text_enclosing_quote := character'val(126);
            temp_var.var_org_stm_text := null;
            temp_var.var_org_stm_text_enclosing_quote := character'val(126);
            temp_var.var_stm_array := null;
            temp_var.var_org_stm_array := null;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;
    begin
        -- if this is not the first one
        if var_list /= null then
            current_ptr := var_list;
            index := index + 1;
            while current_ptr.next_rec /= null loop
                -- if we have defined the current before then die
                assert current_ptr.var_name /= par_text_fields(1) or current_ptr.var_scope /= var_scope
                report lf & "attemping to add a duplicate variable definition var_name:'" & current_ptr.var_name(1 to fld_len(current_ptr.var_name))  
                       & "' var_scope:'" & current_ptr.var_scope(1 to fld_len(current_ptr.var_scope)) & "' on line " & (integer'image(file_line)) & " of file " & text_line_crop(file_name)
                severity failure;
                current_ptr := current_ptr.next_rec;
                index := index + 1;
            end loop;
            -- if we have defined the current before then die. this checks the last one
            assert current_ptr.var_name /= par_text_fields(1) or current_ptr.var_scope /= var_scope
                report lf & "attemping to add a duplicate variable definition var_name:'" & current_ptr.var_name(1 to fld_len(current_ptr.var_name))  
                       & "' var_scope:'" & current_ptr.var_scope(1 to fld_len(current_ptr.var_scope)) & "' on line " & (integer'image(file_line)) & " of file " & text_line_crop(file_name)
            severity failure;
            if var_stm_type = STM_LINES_TYPE then
                init_stm_lines_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_ARRAY_TYPE then
                init_stm_array_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_TEXT_TYPE then
                init_stm_text_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_PROC_TYPE then
                init_proc_var;
                current_ptr.next_rec := temp_var;
            elsif var_stm_type = STM_LABEL_TYPE then
                init_label_var;
                current_ptr.next_rec := temp_var;
            else
                init_value_var;
                current_ptr.next_rec := temp_var;
            end if;
        -- this is the first one
        else
            if var_stm_type = STM_LINES_TYPE then
                init_stm_lines_var;
            elsif var_stm_type = STM_ARRAY_TYPE then
                init_stm_array_var;
            elsif var_stm_type = STM_TEXT_TYPE then
                init_stm_text_var;
            elsif var_stm_type = STM_PROC_TYPE then
                init_proc_var;
            elsif var_stm_type = STM_LABEL_TYPE then
                init_label_var;
            else
                init_value_var;
            end if;
            var_list := temp_var;
        end if;
        assigned_index := index;
    end procedure;

end package body;
