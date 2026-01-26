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

    procedure track_inst_initial_context(
        variable slc : src_locator;
        variable inst : in text_field;
        variable inst_args : in inst_arguments;
        variable vars : in var_pool_ordered;
        variable iic : inout stm_inst_initial_context
    ) is
        variable il : integer;
        variable vn : text_field;
        variable ven : integer;
        variable tmp_label_ptr : text_field_ptr;
        variable tmp_proc : text_field;
    begin
        il := fld_len(inst);
        if inst(1 to il) = INSTR_NAMESPACE then
            iic.namespace_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_NAMESPACE then
            iic.namespace_name := (others => nul);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_OPEN then
            iic.code_section := IN_PROC_PARAMS;
            iic.proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_PROC_PAR_NOPAR then
            iic.code_section := IN_PROC_BODY;
            iic.proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_END_PROC then
            iic.code_section := IN_PROC_PARAMS;
        end if;

        if inst(1 to il) = INSTR_CALL_PAR_OPEN then
            iic.code_section := IN_CALL_PARAMS;
            iic.called_proc_name := inst_args.par_text_fields(1);
        end if;
        if inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
            iic.code_section := IN_CALL_PARAMS;
            vn := textfield_dot_cat(iic.namespace_name, inst_args.par_text_fields(1), iic.proc_name);
            access_var_label_ptr(vars, vn, ven, tmp_label_ptr);
            text_field_ptr_to_text_field(tmp_label_ptr, tmp_proc);
            iic.called_proc_name := tmp_proc;
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
            if iic.code_section = IN_PROC_PARAMS then
                iic.code_section := IN_PROC_BODY;
            end if;
            if iic.code_section = IN_CALL_PARAMS then
                iic.code_section := IN_PROC_BODY;
            end if;
        end if;
    end procedure;
             
    procedure insert_proc_element(
        variable slc : src_locator;
        variable procs : inout proc_pool_ordered;
        variable proc_name : in text_field;
        variable proc_inst_element_num : in integer;
        constant debug : boolean
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
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(i), proc_name) then
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
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(i), proc_name) then
                    s.left := sl.left;
                    s.right := sl.right;
                else
                    s.left := su.left;
                    s.right := su.right;
                end if;    
            end loop;
            insert_before := -1;
            for i in 0 to procs.last_element_num - 1 loop
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(i), proc_name) then
                    insert_before_proc_element_num := i;
                    exit;
                end if;              
            end loop;
            insert_before := -1;
            for i in s.left to s.right loop
                if order_is_less_than_failure_on_equal(slc, procs.element_ptrs(i), proc_name) then
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
        if debug then
            print("add proc " & proc_name & ", proc element_num " & integer'image(procs.last_element_num + 1) & ", pointing to inst element num " & integer'image(proc_inst_element_num));
        end if;           
    end procedure;
    
    procedure insert_var_element(
        variable slc : src_locator;
        variable vars : inout var_pool_ordered;
        variable var_name : in text_field;
        variable inst_args : inst_arguments;
        constant var_type : in stm_var_type;
        constant machine_value_width : in integer;
        variable debug : boolean
    ) is
        variable ne : var_element_ptr;
        variable su : slice;
        variable sl : slice;
        
        procedure inistm_lines_var is
        begin
            ne := new var_element;
            ne.var_slc := slc;
            ne.var_name := var_name;
            ne.var_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, machine_value_width);
            ne.var_org_value := new stm_value(machine_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, machine_value_width);
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_index := index;
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := null;
            ne.var_org_stm_array := null;
            ne.var_stm_lines := new stm_lines;
            ne.var_stm_lines.stm_line_list := null;
            ne.var_stm_lines.size := 0;
            ne.var_org_stm_lines := new stm_lines;
            ne.var_org_stm_lines.stm_line_list := null;
            ne.var_org_stm_lines.size := 0;
            ne.var_stm_type := var_stm_type;
        end procedure;

        procedure inistm_array_var is
        begin
            ne := new var_element;
            ne.var_slc := slc;
            ne.var_name := var_name;
            ne.var_index := index;
            ne.var_value := new stm_value(0 tostm_valueue_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, machine_value_width);
            ne.var_org_value := new stm_value(0 to 0)(stm_stm_value - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, machine_value_width);
            ne.var_label := null;
            ne.var_org_label := null;
            ne.var_stm_text := null;
            ne.var_stm_text_enclosing_quote := character'val(126);
            ne.var_org_stm_text := null;
            ne.var_org_stm_text_enclosing_quote := character'val(126);
            ne.var_stm_array := new stm_array(0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1)(machine_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(slc, par_text_fields(2)) - 1 loop
                ne.var_stm_array(i) := to_unsigned(0, machine_value_width);
            end loop;
            ne.var_org_stm_array := new stm_array(0 to stim_to_integer(slc, inst_args.par_text_fields(2)) - 1)(machine_value_width - 1 downto 0);
            for i in 0 to stim_to_integer(slc, par_text_fields(2)) - 1 loop
                ne.var_org_stm_array(i) := to_unsigned(0, machine_value_width);
            end loop;
            ne.var_stm_lines := null;
            ne.var_org_stm_lines := null;
            ne.var_stm_type := var_stm_type;
        end procedure;

        procedure init_stm_text_var is
        begin
            assert str_ptr /= null
            report lf & "missing file name in file declaration " & (integer'image(file_line)) & " of file " & text_line_crop(file_name)
            severity failure;
            ne := new var_element;
            ne.var_slc := slc;
            ne.var_name := var_name;
            ne.var_index := index;
            ne.var_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);    
            ne.var_value(0) := to_unsigned(0, machine_value_width);
            ne.var_org_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, machine_value_width);
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
        end procedure;
        
        procedure init_label_var is
        begin
            ne := new var_element;
            ne.var_slc := slc;
            ne.var_name := var_name;
            ne.var_index := index;
            ne.var_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_value(0) := to_unsigned(0, machine_value_width);
            ne.var_org_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_org_value(0) := to_unsigned(0, machine_value_width);
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
        end procedure;

        procedure init_value_var is
        begin
            ne := new var_element;
            ne.var_slc := slc;
            ne.var_name := var_name;
            ne.var_index := index;
            ne.var_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_value(0) := stim_to_stm_value(slc, par_text_fields(2), machine_value_width);
            ne.var_org_value := new stm_value(0 to 0)(machine_value_width - 1 downto 0);
            ne.var_org_value(0) := stim_to_stm_value(slc, par_text_fields(2), machine_value_width);
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
        end procedure;

    begin
        case var_stm_type is
            when T_LINES =>
                inistm_lines_var;
                if debug then
                    print("add lines var " & vars.element_ptrs(ven).var_name);
                end if;
            when T_ARRAY =>
                inistm_array_var;
                if debug then
                    print("add array var " & vars.element_ptrs(ven).var_name & ", value " & par_text_fields(2));
                end if;
            when T_TEXT =>
                init_stm_text_var;
                if debug then
                    print("add text var " & vars.element_ptrs(ven).var_name & ", text " & txt_enclosing_quote & str_ptr & txt_enclosing_quote);
                end if;
            when T_LABEL =>
                init_label_var;
                if debug then
                    print("add label var " & vars.element_ptrs(ven).var_name & ", value " & par_text_fields(2));
                end if;
            when T_CONST =>
                init_label_var;
                if debug then
                    print("add constant var " & vars.element_ptrs(ven).var_name & ", value " & par_text_fields(2));
                end if;
            when others =>
                init_value_var;
                if debug then
                    print("add value var " & vars.element_ptrs(ven).var_name & ", value " & par_text_fields(2));
                end if;
        end case;        

        s.left := 0;
        s.right := vars.last_element_num;           
        while s.right - s.left > 8 loop
            sl.left := s.left;
            sl.right := s.right / 2 - 1;
            su.left := sl.right + 1;
            su.right := sl.right;
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(i), var_name) then
                s.left := sl.left;
                s.right := sl.right;
            else
                s.left := su.left;
                s.right := su.right;
            end if;    
        end loop;
        insert_before := -1;
        for i in 0 to vars.last_element_num - 1 loop
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(i), var_name) then
                insert_before_var_element_num := i;
                exit;
            end if;              
        end loop;
        insert_before := -1;
        for i in s.left to s.right loop
            if order_is_less_than_failure_on_equal(slc, vars.element_ptrs(i), var_name) then
                insert_before_var_element_num := i;
                exit;
            end if;              
        end loop;
 
        if insert_before_var_element_num >= 0 then
           vars.element_ptrs(i + 1 to vars.last_element_num + 1) := vars.element_ptrs(i to vars.last_element_num);
           vars.element_ptrs(i) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        else
           vars.element_ptrs(vars.last_element_num + 1) := ne;
           vars.last_element_num := vars.last_element_num + 1;
        end if;                
    end procedure;
    
    function search_var_element_number( 
        vars : var_pool_ordered;
        var_name : text_field
    ) return integer is
        variable su : slice;
        variable sl : slice;
        variable en : integer;     
    begin
        en := -1;
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
        for i in s.left to s.right loop
            if vars.element_ptrs(i) = var_name then
                en := i;
                exit;
            end if;              
        end loop;
        return en;
    end function;
    
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
            var_type := T_CONST_VALUE;
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
        elsif inst(1 to inst_len) = INSTR_PROC_PAR_NOPAR then
            proc_type := true;
        end if;
    end procedure;
    
end package body;
