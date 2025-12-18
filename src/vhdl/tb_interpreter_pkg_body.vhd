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
use work.tb_instructions_pkg.all;

package body tb_interpreter_pkg is

    procedure add_instruction(variable pass : in integer;
                              variable inst_list : inout stim_line_ptr;
                              variable inst_pointers list : inout stim_line_ptr;
                              variable var_list : inout var_field_ptr;
                              variable scope : in text_field;
                              variable scope_left : in text_field;
                              variable inst : in text_field;
                              variable p1 : in text_field;
                              variable p2 : in text_field;
                              variable p3 : in text_field;
                              variable p4 : in text_field;
                              variable p5 : in text_field;
                              variable p6 : in text_field;
                              variable str_ptr : in stm_text_ptr;
                              variable txt_enclosing_quote : in character;
                              variable sequ_num : inout integer;
                              variable line_num : in integer;
                              variable file_name : in text_line;
                              variable file_idx : in integer;
                              constant stm_value_width : in integer) is
        variable temp_stim_line : stim_line_ptr;
        variable temp_current : stim_line_ptr;
        variable valid_instruction : integer;
        variable n_valid : integer;
        variable c_valid : integer;
        variable l : integer;
        variable stm_var_type : t_stm_var_type := NO_VAR_TYPE;
        variable is_new_proc_label : boolean := false;
        variable nul_scope : text_field;
        variable nul_source_label : text_field;
        variable label_ptr : text_field_ptr;
        variable temp_text_field : text_field; 
        variable n_temp_text_field : text_field; 
        variable c_var_index : integer;
        variable c_var_value : unsigned(stm_value_width -1 downto 0);
        variable n_var_index : integer;
        variable n_var_value : unsigned(stm_value_width -1 downto 0);
        variable debug : boolean := true;
        variable assigned_index : integer;
    begin
        valid_instruction := 0;
        l := fld_len(inst);
        temp_current := inst_list;
        label_ptr := null;
        -- take care of special cases
        if inst(1 to l) = INSTR_VAR then
            stm_var_type := STM_VALUE_TYPE;
        elsif inst(1 to l) = INSTR_CONST then
            stm_var_type := STM_CONST_VALUE_TYPE;
        elsif inst(1 to l) = INSTR_ARRAY then
            stm_var_type := STM_ARRAY_TYPE;
        elsif inst(1 to l) = INSTR_LINES then
            stm_var_type := STM_LINES_TYPE;
        elsif inst(1 to l) = INSTR_FILE then
            stm_var_type := STM_TEXT_TYPE;
        elsif inst(1 to l) = INSTR_BUS then
            stm_var_type := STM_BUS_TYPE;
        elsif inst(1 to l) = INSTR_SIGNAL then
            stm_var_type := STM_SIGNAL_TYPE;
        elsif inst(l) = ':' then
            stm_var_type := STM_PROC_TYPE;
        elsif inst(1 to l) = INSTR_PROC_PAR_OPEN then
            stm_var_type := STM_PROC_TYPE;
            is_new_proc_label := true;
        elsif inst(1 to l) = INSTR_PROC_PAR_NOPAR_0 then
            stm_var_type := STM_PROC_TYPE;
            is_new_proc_label := true;
        elsif inst(1 to l) = INSTR_PROC_PAR_NOPAR_1 then
            stm_var_type := STM_PROC_TYPE;
            is_new_proc_label := true;
        elsif inst(1 to l) = INSTR_LABEL then
            stm_var_type := STM_LABEL_TYPE;          
        end if;

        if pass = 0 then           
            if stm_var_type /= NO_VAR_TYPE and stm_var_type = STM_CONST_VALUE_TYPE then
                 -- constant definition and declaration, no instruction
                 l := fld_len(p1);
                 add_variable(var_list, scope, p1, p2, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                 if debug then
                    print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " constant '" & p1 & "' value '" & p2 & "' scope '" & scope  & "'");
                 end if;            
            end if;       
        elsif pass = 1 then
            if stm_var_type /= NO_VAR_TYPE and stm_var_type /= STM_CONST_VALUE_TYPE then         
                if stm_var_type /= STM_PROC_TYPE then      
                    if fld_len(scope) = 0 then -- global variable
                        --  global variable, definition and declaration, no instruction, may use an already declared constant of pass 1
                        l := fld_len(p1);                      
                        if is_digit(p2(1)) or stm_var_type = STM_TEXT_TYPE or stm_var_type = STM_LINES_TYPE or stm_var_type = STM_LABEL_TYPE then
                            add_variable(var_list, scope, p1, p2, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                            if debug then
                                print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " global var '" & p1 & "' value '" & p2 & "' scope '" & scope  & "'");
                            end if;
                        else
                            access_variable(var_list, scope, p2, c_var_index, c_var_value, c_valid);
                            assert c_valid /= 0
                            report lf & "error: Constant '" & p2(1 to fld_len(p2)) & "' to initialize variable '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not found !"
                            severity failure;
                            n_temp_text_field(1) := '0';
                            add_variable(var_list, scope, p1, n_temp_text_field, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);                          
                            access_variable(var_list, scope, p1, n_var_index, n_var_value, n_valid);
                            assert n_valid /= 0
                            report lf & "error: New variable '" & p2(1 to fld_len(p2)) & "' to initialize with constant '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not found !"
                            severity failure;
                            update_variable(var_list, n_var_index, c_var_value, n_valid);    
                            assert n_valid /= 0
                            report lf & "error: New variable '" & p2(1 to fld_len(p2)) & "' update with constant '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not successful !"
                            severity failure;     
                            if debug then
                                print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " global var '" & p1 & "' value '" & p2 & "' scope '" & scope  & "'");
                            end if;              
                        end if;
                    end if;
                end if;
            end if;         
        elsif pass = 2 then
            if stm_var_type = NO_VAR_TYPE then
                valid_instruction := 1; -- anything but a declartion, thus always an instruction
            else
                if stm_var_type /= STM_CONST_VALUE_TYPE then -- constant constant definition and declaration already done in pass 1       
                    if stm_var_type = STM_PROC_TYPE then
                        -- a proc label
                        if is_new_proc_label then
                            -- a new proc label e.g., PROC A_PROCNAME, to be added as instruction
                            l := fld_len(p1) + 1;
                            temp_text_field := p1;
                            temp_text_field(l) := ':';
                            temp_text_field(l + 1) := nul;
                            add_variable(var_list, nul_scope, temp_text_field, p2, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);                
                            if debug then
                                print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " proc label var () '" & p1 & " seq " & integer'image(sequ_num) & "' scope '" & scope  & "'");
                            end if; 
                            valid_instruction := 1; 
                        else
                            -- a conventional proc label e.g., PROCNAME: , not to be added as instruction
                            add_variable(var_list, nul_scope, inst, p1, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                            if debug then
                                print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " proc label label var : '" & inst & " seq " & integer'image(sequ_num) & " scope '" & scope  & "'");
                            end if;                                     
                        end if;                                        
                    else
                        -- any other var definition and declartion
                        if fld_len(scope) /= 0 then
                            -- any other local var definition and declaration, to be added as instruction
                            l := fld_len(p1);                      
                            if is_digit(p2(1)) or stm_var_type = STM_TEXT_TYPE or stm_var_type = STM_LINES_TYPE or stm_var_type = STM_LABEL_TYPE then
                                add_variable(var_list, scope, p1, p2, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);
                                if debug then
                                    print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " local var '" & p1 & "' value '" & p2 & "' scope '" & scope  & "'");
                                end if; 
                                valid_instruction := 1; 
                            else
                                access_variable(var_list, scope, p2, c_var_index, c_var_value, c_valid);
                                assert c_valid /= 0
                                report lf & "error: Constant '" & p2(1 to fld_len(p2)) & "' to initialize variable '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not found !"
                                severity failure;
                                n_temp_text_field(1) := '0';
                                add_variable(var_list, scope, p1, n_temp_text_field, sequ_num, line_num, file_name, l, stm_var_type, str_ptr, txt_enclosing_quote, stm_value_width, assigned_index);                        
                                access_variable(var_list, scope, p1, n_var_index, n_var_value, n_valid);
                                assert n_valid /= 0
                                report lf & "error: New variable '" & p2(1 to fld_len(p2)) & "' to initialize with constant '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not found !"
                                severity failure;
                                update_variable(var_list, n_var_index, c_var_value, n_valid);    
                                assert n_valid /= 0
                                report lf & "error: New variable '" & p2(1 to fld_len(p2)) & "' update with constant '" & p1(1 to fld_len(p1)) & "' scope:'" & scope(1 to fld_len(scope)) & "' not successful !"
                                severity failure;    
                                if debug then
                                    print("pass " & integer'image(pass) & " add idx "& integer'image(assigned_index) & " local var '" & p1 & "' value '" & p2 & "' scope '" & scope  & "'");
                                end if; 
                                valid_instruction := 1;                   
                            end if;         
                        end if;                 
                    end if;
                end if;
            end if;     
        end if;

        if valid_instruction = 1 then
            -- prepare the new record
            temp_stim_line := new stim_line;
            temp_stim_line.instruction := inst;
            temp_stim_line.inst_scope := scope;
            temp_stim_line.inst_scope_left := scope_left;
            temp_stim_line.inst_field_1 := p1;
            temp_stim_line.inst_field_2 := p2;
            temp_stim_line.inst_field_3 := p3;
            temp_stim_line.inst_field_4 := p4;
            temp_stim_line.inst_field_5 := p5;
            temp_stim_line.inst_field_6 := p6;
            temp_stim_line.txt := str_ptr;
            temp_stim_line.txt_enclosing_quote := txt_enclosing_quote;
            temp_stim_line.line_number := sequ_num;
            temp_stim_line.file_idx := file_idx;
            temp_stim_line.file_line := line_num; 
            if debug then
                print("pass " & integer'image(pass) & " add instruction " & inst & " seq " & integer'image(sequ_num) & " scope '" & scope  & "' scope_left '" & scope_left  & "'");
            end if;                     
            -- if is not the first instruction
            if inst_list /= null then
                while temp_current.next_rec /= null loop
                    temp_current := temp_current.next_rec;
                end loop;
                temp_current.next_rec := temp_stim_line;
                inst_list.num_of_lines := inst_list.num_of_lines + 1;
            -- other wise is first instruction to be added
            else
                inst_list := temp_stim_line;
                inst_list.num_of_lines := 1;
            end if;
            sequ_num := sequ_num + 1;
            -- print_inst(temp_stim_line);  -- for debug
        end if;
    end procedure;

    procedure add_variable(variable var_list : inout var_field_ptr;
                           variable scope : in text_field;
                           variable p1 : in text_field; -- should be var name
                           variable p2 : in text_field; -- should be value
                           variable sequ_num : in integer;
                           variable line_num : in integer;
                           variable name : in text_line;
                           variable length : in integer;
                           constant var_stm_type : in t_stm_var_type;
                           variable str_ptr : in stm_text_ptr;
                           variable txt_enclosing_quote : in character;
                           constant stm_value_width : in integer;
                           variable assigned_index : out integer) is
        variable temp_var : var_field_ptr;
        variable current_ptr : var_field_ptr;
        variable index : integer := 1;

        procedure init_stm_lines_var is
        begin
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_scope := scope; -- direct write of text_field
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
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_scope := scope; -- direct write of text_field
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
            temp_var.var_stm_array := new t_stm_array(0 to stim_to_integer(p2, name, line_num)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(p2, name, line_num)-1 loop
                temp_var.var_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            temp_var.var_org_stm_array := new t_stm_array(0 to stim_to_integer(p2, name, line_num)-1)(stm_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(p2, name, line_num)-1 loop
                temp_var.var_org_stm_array(i) := to_unsigned(0, stm_value_width);
            end loop;
            temp_var.var_stm_lines := null;
            temp_var.var_org_stm_lines := null;
            temp_var.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert str_ptr /= null
            report lf & "error: missing file name in file declaration " & (integer'image(line_num)) & " of file " & text_line_crop(name)
            severity failure;
            temp_var := new var_field;
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_scope := scope; -- direct write of text_field
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
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_scope := scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := stim_to_stm_value(p2, name, line_num, stm_value_width); -- convert text_field to unsigned
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := stim_to_stm_value(p2, name, line_num, stm_value_width); -- convert text_field to unsigned 
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
            temp_var.var_name := p1; -- direct write of text_field
            temp_var.var_scope := scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(0, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(0, stm_value_width);  
            temp_var.var_label := new text_field;
            text_field_to_text_field_ptr(p2, temp_var.var_label);
            temp_var.var_org_label := new text_field;
            text_field_to_text_field_ptr(p2, temp_var.var_org_label);      
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
        begin
            temp_var := new var_field;
            temp_var.var_name(1 to (length - 1)) := p1(1 to (length - 1));
            temp_var.var_scope := scope; -- direct write of text_field
            temp_var.var_index := index;
            temp_var.var_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_value(0) := to_unsigned(sequ_num, stm_value_width);
            temp_var.var_org_value := new t_stm_value(0 to 0)(stm_value_width - 1 downto 0);
            temp_var.var_org_value(0) := to_unsigned(sequ_num, stm_value_width);
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
                assert current_ptr.var_name /= p1 or current_ptr.var_scope /= scope
                report lf & "error: attemping to add a duplicate variable definition var_name:'" & current_ptr.var_name(1 to fld_len(current_ptr.var_name))  & "' var_scope:'" & current_ptr.var_scope(1 to fld_len(current_ptr.var_scope)) & "' on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
                severity failure;
                current_ptr := current_ptr.next_rec;
                index := index + 1;
            end loop;
            -- if we have defined the current before then die. this checks the last one
            assert current_ptr.var_name /= p1 or current_ptr.var_scope /= scope
                report lf & "error: attemping to add a duplicate variable definition var_name:'" & current_ptr.var_name(1 to fld_len(current_ptr.var_name))  & "' var_scope:'" & current_ptr.var_scope(1 to fld_len(current_ptr.var_scope)) & "' on line " & (integer'image(line_num)) & " of file " & text_line_crop(name)
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
    
    procedure search_instruction_line_ptr( 
            variable sequential_instruction_list : in stim_line_ptr;
            variable search_for_instruction_line_number : in integer;
            variable last_searched_instruction_line_number : inout integer;
            variable last_searched_instruction_line_ptr : inout stim_line_ptr;
            variable instruction_line_ptr : out stim_line_ptr
        ) is                               
        variable instr_ptr : stim_line_ptr;
    begin                                   
        -- get to the instruction indicated by the search_for_instruction_line_number
        -- check to see if this number is before the last_searched_instruction_line_number
        -- so search from start
        if last_searched_instruction_line_number > search_for_instruction_line_number then
            instr_ptr := sequential_instruction_list;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = search_for_instruction_line_number then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            instr_ptr := last_searched_instruction_line_ptr;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = search_for_instruction_line_number then
                    instruction_line_ptr := instr_ptr;
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        end if;
        -- update the last sequence number and record pointer
        last_searched_instruction_line_number := search_for_instruction_line_number;
        last_searched_instruction_line_ptr := instr_ptr;
    end procedure;

    procedure access_instruction_line(        
            variable instruction_line_ptr : in stim_line_ptr;                                                                          
            variable file_list : in file_def_ptr;                             
            variable instruction : out text_field;
            variable instruction_len : out integer;
            variable p1_text_field : out text_field;
            variable p2_text_field : out text_field;
            variable p3_text_field : out text_field;
            variable p4_text_field : out text_field;
            variable p5_text_field : out text_field;
            variable p6_text_field : out text_field;   
            variable txt : out stm_text_ptr;
            variable txt_enclosing_quote : out character;
            variable file_name : out text_line;
            variable file_line : out integer
        ) is
        variable tmp_file_index : integer;
        variable tmp_file_def_ptr : file_def_ptr;
    begin 
        instruction := instruction_line_ptr.instruction;  
        instruction_len := fld_len(instruction_line_ptr.instruction); 
        p1_text_field := instruction_line_ptr.inst_field_1; 
        p2_text_field := instruction_line_ptr.inst_field_2; 
        p3_text_field := instruction_line_ptr.inst_field_3; 
        p4_text_field := instruction_line_ptr.inst_field_4; 
        p5_text_field := instruction_line_ptr.inst_field_5; 
        p6_text_field := instruction_line_ptr.inst_field_6; 
        file_line := instruction_line_ptr.file_line;
        -- recover the file name this line came from
        tmp_file_def_ptr := file_list;
        tmp_file_index := instruction_line_ptr.file_idx;
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
    
    
    procedure access_inst_sequ(
                               variable mode_is_check : in boolean;
                               variable inst_sequ : in stim_line_ptr;
                               variable var_list : in var_field_ptr;
                               variable file_list : in file_def_ptr;
                               variable program_line_number_counter : in integer;
                               variable instruction : out text_field;
                               variable instruction_len : out integer;
                               variable instruction_scope : out text_field;
                               variable instruction_scope_left : out text_field;
                               variable p1_text_field : out text_field;
                               variable p2_text_field : out text_field;
                               variable p3_text_field : out text_field;
                               variable p4_text_field : out text_field;
                               variable p5_text_field : out text_field;
                               variable p6_text_field : out text_field;   
                               variable txt : out stm_text_ptr;
                               variable txt_enclosing_quote : out character;
                               variable fname : out text_line;
                               variable file_line : out integer;
                               variable in_proc_advanced_parameters : inout boolean;                               
                               variable in_call_advanced_parameters : inout boolean;
                               variable in_proc_advanced_label_parameters : inout boolean;
                               variable in_call_advanced_label_parameters : inout boolean;
                               variable in_call_advanced_label : inout boolean;
                               variable called_proc : inout text_field;
                               variable target_proc_after_par_bracket_code_line_to_execute : inout integer;
                               variable target_call_code_line_to_execute : inout integer                       
                               ) is

        variable instr : text_field;
        variable instr_scope : text_field;
        variable instr_scope_left : text_field;
        variable instr_text_field : text_field;
        variable instr_len : integer;
        variable instr_ptr : stim_line_ptr;
        variable valid : integer;
        variable file_name : text_line;
        variable tmp_file_index : integer;
        variable tmp_file_def_ptr : file_def_ptr;
        variable tmp_label_ptr : text_field_ptr;
        variable tmp_proc: text_field;

    begin 

        p1_index := -1;
        p2_index := -1;
        p3_index := -1;
        p4_index := -1;
        p5_index := -1;
        p6_index := -1;
        p1 := to_unsigned(0, p1'length) - 1;
        p2 := to_unsigned(0, p1'length) - 1;
        p3 := to_unsigned(0, p1'length) - 1;
        p4 := to_unsigned(0, p1'length) - 1;
        p5 := to_unsigned(0, p1'length) - 1;
        p6 := to_unsigned(0, p1'length) - 1;   
                
        -- get to the instruction indicated by code_line_to_execute
        -- check to see if this sequence is before the last
        -- so search from start
        if last_searched_instruction_line_number > program_line_number_pointer then
            instr_ptr := inst_sequ;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = program_line_number_pointer then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        -- else is equal or greater, so search forward
        else
            instr_ptr := last_searched_instruction_line_ptr;
            while instr_ptr.next_rec /= null loop
                if instr_ptr.line_number = program_line_number_pointer then
                    exit;
                else
                    instr_ptr := instr_ptr.next_rec;
                end if;
            end loop;
        end if;
        -- update the last sequence number and record pointer
        last_searched_instruction_line_number := program_line_number_pointer;
        last_searched_instruction_line_ptr := instr_ptr;
        
        instr := instr_ptr.instruction;
        instruction := instr;    
        instr_scope := instr_ptr.inst_scope;
        instruction_scope := instr_scope;
        instr_scope_left := instr_ptr.inst_scope_left;
        instruction_scope_left := instr_scope_left;
        instr_len := fld_len(instr);
        instruction_len := instr_len;  
        p1_text_field := instr_ptr.inst_field_1; 
        p2_text_field := instr_ptr.inst_field_2; 
        p3_text_field := instr_ptr.inst_field_3; 
        p4_text_field := instr_ptr.inst_field_4; 
        p5_text_field := instr_ptr.inst_field_5; 
        p6_text_field := instr_ptr.inst_field_6; 
        file_line := instr_ptr.file_line;
        -- recover the file name this line came from
        tmp_file_def_ptr := file_list;
        tmp_file_index := instr_ptr.file_idx;
        while tmp_file_def_ptr.next_rec /= null loop
            if tmp_file_def_ptr.rec_idx = tmp_file_index then
                exit;
            end if;
            tmp_file_def_ptr := tmp_file_def_ptr.next_rec;
        end loop;
        for i in 1 to fname'high loop
            file_name(i) := tmp_file_def_ptr.file_name(i);
            fname(i) := tmp_file_def_ptr.file_name(i);
        end loop;
        
        if instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_OPEN 
           or instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_NOPAR_0 
           or instr(1 to instr_len) = INSTR_CALL_LABEL_PAR_NOPAR_1 then 
            access_variable_label_ptr(var_list, instr_scope, p1_text_field, p1_index, tmp_label_ptr, valid);
            assert valid /= 0
            report lf & "error: call label variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
            severity failure;       
            text_field_ptr_to_text_field(tmp_label_ptr, tmp_proc);          
            in_proc_advanced_label_parameters := true;
            called_proc := tmp_proc; 
            access_variable(var_list, instr_scope, tmp_proc, p1_index, p1, valid);
            assert valid /= 0
            report lf & "error: call label proc variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
            severity failure;
        elsif instruction(1 to instr_len) = INSTR_CALL_PAR_OPEN then                    
            in_proc_advanced_parameters := true;
            target_call_code_line_to_execute := code_line_to_execute;
            access_variable(var_list, instr_scope_left, p1_text_field, p1_index, p1, valid);
            assert valid /= 0
            report lf & "error: call proc() variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
            severity failure;
            next_alternate_code_line_to_execute := to_integer(p1(30 downto 0)) - 1;
            variable next_alternate_scope := scope inout text_field;
            variable next_alternate_scope_left : inout text_field;
            called_proc := instr_ptr.inst_field_1; 
        elsif instruction(1 to instr_len) = INSTR_CALL 
              or instr(1 to instr_len) = INSTR_CALL_PAR_NOPAR_0 
              or instr(1 to instr_len) = INSTR_CALL_PAR_NOPAR_1 then 
              access_variable(var_list, instr_scope_left, p1_text_field, p1_index, p1, valid);
              assert valid /= 0
              report lf & "error: call proc: variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
              severity failure;
              next_alternate_code_line_to_execute := to_integer(p1(30 downto 0)) - 1;                     
              called_proc := instr_ptr.inst_field_1;                                    
        elsif instr_text_field(1 to instr_len) = INSTR_PAR_CLOSE 
              or instr(1 to instr_len) = INSTR_VAR_POINTER_COPY_PAR_CLOSE 
              or instr(1 to instr_len) = INSTR_ARRAY_POINTER_COPY_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_LABEL_EQU_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_FILE_POINTER_COPY_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_LINES_POINTER_COPY_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE
              or instr(1 to instr_len) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
            if in_proc_advanced_parameters then
                target_proc_after_par_bracket_code_line_to_execute := code_line_to_execute;
                next_alternate_code_line_to_execute := target_call_code_line_to_execute;  
                in_proc_advanced_parameters := false;  
                in_call_advanced_parameters := true;
            elsif in_proc_advanced_label_parameters then
                target_proc_after_par_bracket_code_line_to_execute := code_line_to_execute;
                next_alternate_code_line_to_execute := target_call_code_line_to_execute;  
                in_proc_advanced_label_parameters := false;  
                in_call_advanced_label_parameters := true; 
            elsif in_call_advanced_parameters then  
                next_alternate_code_line_to_execute := target_proc_after_par_bracket_code_line_to_execute;
                in_call_advanced_parameters := false;
                in_call_advanced_label := true;
            elsif in_call_advanced_label_parameters then  
                next_alternate_code_line_to_execute := target_proc_after_par_bracket_code_line_to_execute;
                in_call_advanced_label_parameters := false;
                in_call_advanced_label := true;
            end if;
        else       
            txt := instr_ptr.txt;
            txt_enclosing_quote := instr_ptr.txt_enclosing_quote;        
            if p1_text_field(1) /= nul then
                if is_digit(p1_text_field(1)) then
                    p1 := stim_to_stm_value(p1_text_field, file_name, file_line, p1'length);
                else
                    access_variable(var_list, scope_left, p1_text_field, p1_index, p1, valid);
                    assert valid /= 0
                    report lf & "error: first variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            if p2_text_field(1) /= nul then
                if is_digit(p2_text_field(1)) then
                    p2 := stim_to_stm_value(p2_text_field, file_name, file_line, p2'length);
                else
                    access_variable(var_list, scope, p2_text_field, p2_index, p2, valid);
                    assert valid /= 0
                    report lf & "error: second variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            if p3_text_field(1) /= nul then
                if is_digit(p3_text_field(1)) then
                    p3 := stim_to_stm_value(p3_text_field, file_name, file_line, p3'length);
                else
                    access_variable(var_list, scope, p3_text_field, p3_index, p3, valid);
                    assert valid /= 0
                    report lf & "error: third variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            if p4_text_field(1) /= nul then
                if is_digit(p4_text_field(1)) then
                    p4 := stim_to_stm_value(p4_text_field, file_name, file_line, p4'length);
                else
                    access_variable(var_list, scope, p4_text_field, p4_index, p4, valid);
                    assert valid /= 0
                    report lf & "error: forth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            if p5_text_field(1) /= nul then
                if is_digit(p5_text_field(1)) then
                    p5 := stim_to_stm_value(p5_text_field, file_name, file_line, p5'length);
                else
                    access_variable(var_list, scope, p5_text_field, p5_index, p5, valid);
                    assert valid /= 0
                    report lf & "error: fifth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
            if p6_text_field(1) /= nul then
                if is_digit(p6_text_field(1)) then
                    p6 := stim_to_stm_value(p6_text_field, file_name, file_line, p6'length);
                else
                    access_variable(var_list, scope, p6_text_field, p6_index, p6, valid);
                    assert valid /= 0
                    report lf & "error: sixth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                    severity failure;
                end if;
            end if;
        end if;
               
    end procedure;
    
    procedure access_instruction_line_parameters( 
            variable var_list : in var_field_ptr;
            variable file_name : in text_line;
            variable file_line : in integer;
            variable scope_p1 : in text_field;     
            variable scope_p_others : in text_field;         
            variable p1_text_field : in text_field;
            variable p2_text_field : in text_field;
            variable p3_text_field : in text_field;
            variable p4_text_field : in text_field;
            variable p5_text_field : in text_field;
            variable p6_text_field : in text_field;
            variable p1_index : out integer;
            variable p2_index : out integer;
            variable p3_index : out integer;
            variable p4_index : out integer;
            variable p5_index : out integer;
            variable p6_index : out integer;
            variable p1_value : out unsigned;
            variable p2_value : out unsigned;
            variable p3_value : out unsigned;
            variable p4_value : out unsigned;
            variable p5_value : out unsigned;
            variable p6_value : out unsigned
        ) is

        variable instr : text_field;
        variable instr_scope : text_field;
        variable instr_scope_left : text_field;
        variable instr_text_field : text_field;
        variable instr_len : integer;
        variable instr_ptr : stim_line_ptr;
        variable valid : integer;
        variable tmp_file_index : integer;
        variable tmp_file_def_ptr : file_def_ptr;
        variable tmp_label_ptr : text_field_ptr;
        variable tmp_proc: text_field;

    begin 
             
        if p1_text_field(1) /= nul then
            if is_digit(p1_text_field(1)) then
                p1 := stim_to_stm_value(p1_text_field, file_name, file_line, p1'length);
            else
                access_variable(var_list, scope_p1, p1_text_field, p1_index, p1, valid);
                assert valid /= 0
                report lf & "error: first variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        if p2_text_field(1) /= nul then
            if is_digit(p2_text_field(1)) then
                p2 := stim_to_stm_value(p2_text_field, file_name, file_line, p2'length);
            else
                access_variable(var_list, scope_p_others, p2_text_field, p2_index, p2, valid);
                assert valid /= 0
                report lf & "error: second variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        if p3_text_field(1) /= nul then
            if is_digit(p3_text_field(1)) then
                p3 := stim_to_stm_value(p3_text_field, file_name, file_line, p3'length);
            else
                access_variable(var_list, scope_p_others, p3_text_field, p3_index, p3, valid);
                assert valid /= 0
                report lf & "error: third variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        if p4_text_field(1) /= nul then
            if is_digit(p4_text_field(1)) then
                p4 := stim_to_stm_value(p4_text_field, file_name, file_line, p4'length);
            else
                access_variable(var_list, scope_p_others, p4_text_field, p4_index, p4, valid);
                assert valid /= 0
                report lf & "error: forth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        if p5_text_field(1) /= nul then
            if is_digit(p5_text_field(1)) then
                p5 := stim_to_stm_value(p5_text_field, file_name, file_line, p5'length);
            else
                access_variable(var_list, scope_p_others, p5_text_field, p5_index, p5, valid);
                assert valid /= 0
                report lf & "error: fifth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
        if p6_text_field(1) /= nul then
            if is_digit(p6_text_field(1)) then
                p6 := stim_to_stm_value(p6_text_field, file_name, file_line, p6'length);
            else
                access_variable(var_list, scope_p_others, p6_text_field, p6_index, p6, valid);
                assert valid /= 0
                report lf & "error: sixth variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name
                severity failure;
            end if;
        end if;
               
    end procedure;
    
    
    procedure read_include_file(variable pass : in integer;
                                constant path_name : string;
                                variable name : text_line;
                                variable sequ_numb : inout integer;
                                variable file_list : inout file_def_ptr;
                                variable inst_set : inout inst_def_ptr;
                                variable var_list : inout var_field_ptr;
                                variable inst_sequ : inout stim_line_ptr;
                                variable status : inout integer;
                                constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
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
        variable t1_len: integer;
        variable scope : text_field;
        variable scope_left : text_field;
        variable nul_scope : text_field;
        variable in_call_par : boolean := false;       
        
    begin
        sequ_line := sequ_numb;
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
            print("error: unable to open include file  " & text_line_crop(include_file_path_name));
            status := 1;
            return;
        end if;
        l_num := 1; -- initialize line number
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
        v_instr_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;
        scope := nul_scope;
        scope_left := nul_scope;
        -- while not the end of file read it
        while not endfile(include_file) loop
            file_read_line(include_file, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t1);
            if t1(1 to v_len) = "include" then
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
                    report lf & "error:  include instruction is missing included file name paramater , found at:" & lf & "line " & (integer'image(l_num)) & " in file " & include_file_path_name & lf
                    severity failure;
                end if;
                print("nested include found in : " & include_file_path_name);
                check_presence_instruction_file_name(file_list, text_line_crop(v_iname), present);
                if present then
                    print("nested include found: not loading file since already present " & text_line_crop(v_iname));
                else
                    print("nested include found: loading file " & path_name & v_iname);
                    read_include_file(pass, path_name, v_iname, sequ_line, v_tmp_fn, v_instr_ptr, v_var_prt, v_sequ_ptr, v_ostat, stm_value_width);
                    -- if include file not found
                    if v_ostat = 1 then
                        exit;
                    end if;
                end if;
            -- if there was valid tokens
            elsif valid /= 0 then
                t1_len := fld_len(t1);             
                check_valid_inst(t1, v_instr_ptr, valid, l_num, v_iname);                
                -- proc_(
                -- proc_() 
                -- proc_(_) 
                if t1(1 to t1_len) = INSTR_PROC_PAR_OPEN or t1(1 to t1_len) = INSTR_PROC_PAR_NOPAR_0 or t1(1 to t1_len) = INSTR_PROC_PAR_NOPAR_1 then
                    scope := t2;
                    scope_left := scope;
                end if;
                -- end proc
                -- end interrupt
                -- return
                if t1(1 to t1_len) = INSTR_END_PROC or t1(1 to t1_len) = INSTR_END_INTERRUPT then
                    scope := nul_scope;
                    scope_left := scope;
                end if;
                -- call_(
                -- call_() 
                -- call_(_) 
                if t1(1 to t1_len) = INSTR_CALL_PAR_OPEN then
                    scope_left := t2;
                    in_call_par := true;
                end if;
                -- ) 
                if t1(1 to t1_len) = INSTR_PAR_CLOSE and in_call_par then
                    scope_left := scope;
                    in_call_par := false;
                end if;      
                add_instruction(pass, v_sequ_ptr, v_var_prt, scope, scope_left, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote,
                                sequ_line, l_num, v_iname, v_new_fn, stm_value_width);

            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(include_file);
        sequ_numb := sequ_line;
        inst_set := v_instr_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
    end procedure;

    procedure read_instruction_file(variable pass : in integer;
                                    constant path_name : string;
                                    constant file_name : string;
                                    variable inst_set : inout inst_def_ptr;
                                    variable var_list : inout var_field_ptr;
                                    variable inst_sequ : inout stim_line_ptr;
                                    variable file_list : inout file_def_ptr;
                                    constant stm_value_width : in integer) is
        variable l : text_line; -- the line
        variable l_num : integer; -- line number file
        variable sequ_line : integer; -- line number program
        variable t1 : text_field;
        variable t2 : text_field;
        variable t3 : text_field;
        variable t4 : text_field;
        variable t5 : text_field;
        variable t6 : text_field;
        variable t7 : text_field;
        variable t_txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable valid : integer;
        variable v_ostat : integer;
        variable v_instr_ptr : inst_def_ptr;
        variable v_var_prt : var_field_ptr;
        variable v_sequ_ptr : stim_line_ptr;
        variable v_len : integer;
        variable v_stat : file_open_status;
        variable v_name : text_line;
        variable v_iname : text_line;
        variable v_tmp_fn : file_def_ptr;
        variable v_fn_idx : integer;
        variable t1_len: integer;
        variable scope : text_field;
        variable scope_left : text_field;
        variable nul_scope : text_field;
        variable in_call_par : boolean := false;

    begin
        nul_scope(1) := nul;
        -- open the stimulus_file and check
        file_open(v_stat, stimulus, path_name & file_name, read_mode);
        assert v_stat = open_ok
        report lf & "error: unable to open stimulus_file  " & path_name & file_name
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
        l_num := 1;
        sequ_line := 1;
        v_ostat := 0;
        v_instr_ptr := inst_set;
        v_var_prt := var_list;
        v_sequ_ptr := inst_sequ;
        scope := nul_scope;
        scope_left := nul_scope;
        -- while not the end of file read it
        while not endfile(stimulus) loop
            file_read_line(stimulus, l);
            --  tokenize the line
            tokenize_line(l, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote, valid);
            v_len := fld_len(t1);
            -- if there is an include instruction
            if t1(1 to v_len) = "include" then
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
                    report lf & "error:  include instruction has not file name included.  found on" & lf & "line " & (integer'image(l_num)) & " in file " & path_name & file_name & lf
                    severity failure;
                end if;
                print("include found: loading file " & path_name & v_iname);
                read_include_file(pass, path_name, v_iname, sequ_line, v_tmp_fn, v_instr_ptr, v_var_prt, v_sequ_ptr, v_ostat, stm_value_width);
                -- if include file not found
                if v_ostat = 1 then
                    exit;
                end if;
            -- if there were valid tokens
            elsif valid /= 0 then
                t1_len := fld_len(t1);             
                check_valid_inst(t1, v_instr_ptr, valid, l_num, v_name);                
                -- proc_(
                -- proc_() 
                -- proc_(_) 
                if t1(1 to t1_len) = INSTR_PROC_PAR_OPEN or t1(1 to t1_len) = INSTR_PROC_PAR_NOPAR_0 or t1(1 to t1_len) = INSTR_PROC_PAR_NOPAR_1 then
                    scope := t2;
                    scope_left := scope;
                end if;
                -- end proc
                -- end interrupt
                -- return
                if t1(1 to t1_len) = INSTR_END_PROC or t1(1 to t1_len) = INSTR_END_INTERRUPT then
                    scope := nul_scope;
                    scope_left := scope;
                end if;
                -- call_(
                -- call_() 
                -- call_(_) 
                if t1(1 to t1_len) = INSTR_CALL_PAR_OPEN then
                    scope_left := t2;
                    in_call_par := true;
                end if;
                -- ) 
                if t1(1 to t1_len) = INSTR_PAR_CLOSE and in_call_par then
                    scope_left := scope;
                    in_call_par := false;
                end if;      
                add_instruction(pass, v_sequ_ptr, v_var_prt, scope, scope_left, t1, t2, t3, t4, t5, t6, t7, t_txt, txt_enclosing_quote,
                                sequ_line, l_num, v_name, v_fn_idx, stm_value_width);
            end if;
            l_num := l_num + 1;
        end loop; -- end loop read file
        file_close(stimulus); -- close the file when done
        assert v_ostat = 0
        report lf & "include file specified on line " & (integer'image(l_num)) & " in file " & path_name & file_name & " was not found! test terminated" & lf
        severity failure;
        inst_set := v_instr_ptr;
        var_list := v_var_prt;
        inst_sequ := v_sequ_ptr;
        file_list := v_tmp_fn;
    end procedure;
    
end package body;
