-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- Author: sckoarn 
--
-- Date:  
--
-- Id:  
--
-- Source:  
--
-- Description :  The the testbench template file.
--
------------------------------------------------------------------------------
--  This file is a template used to generate test bench _bhv.vhd  file.
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
-- https://github.com/sckoarn/VHDL-Test-Bench/blob/main/source/template_tb_bhv.tmpl
--
-- Adapt to new fix SimStm language
--
-- Export code to be modified by the user into packages
-- ----------------------------------------------------------------------------

library std;
use std.textio.all;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;
use work.tb_interpreter_basic_pkg.all;
use work.tb_interpreter_pkg.all;
use work.tb_bus_pkg.all;
use work.tb_signals_pkg.all;

entity tb_simstm is
    generic(
        stimulus_path : in string;
        stimulus_file : in string;
        stimulus_main_entry_label : in string := "testMain";
        machine_value_width : integer := 64;
        machine_address_width : integer := 32
    );
    port(
        executing_line : out integer;
        executing_file : out text_line;
        verify_passes : out std_logic_vector(31 downto 0);
        verify_failures : out std_logic_vector(31 downto 0);
        bus_timeout_passes : out std_logic_vector(31 downto 0);
        bus_timeout_failures : out std_logic_vector(31 downto 0);
        marker : out std_logic_vector(15 downto 0);
        signals_out : out t_signals_out;
        signals_in : in t_signals_in := signals_in_init;
        bus_down : out t_bus_down;
        bus_up : in t_bus_up := bus_up_init
    );
end;

architecture behavioural of tb_simstm is
    function ld(m : integer) return natural is
    begin
        if m < 0 then
            return 31;
        end if;
        for n in 0 to integer'high loop
            if (2 ** n >= m) then
                return n;
            end if;
        end loop;
    end function;

    -- LD function
    --          0 => as best approximation => 0 + Warning
    --          1 => 2^0   => 0
    --   11,   10 => 2^1   => 1
    --  111,  100 => 2^2   => 2
    -- 1111, 1000 => 2^3   => 3
    function ld(m : unsigned) return unsigned is
    begin

        for n in m'high downto 0 loop
            if (m(n) = '1') then
                return to_unsigned(n, m'length);
            end if;
        end loop;

        report "warning: ld of 0 is approximated as 0" severity warning;
        return to_unsigned(0, m'length);
    end function;

    procedure line_to_text_field(variable l : in line; variable tf : out text_field) is
    begin
        for i in 1 to tf'length loop
            tf(i) := nul;
        end loop;
        assert tf'length > l'length;
        if l'length > 0 then
            for i in 1 to l'length loop
                tf(i) := l.all(i);
            end loop;
        end if;
    end procedure;

begin
    --------------------------------------------------------------------------------
    --! Read_file Process:
    --! This process is the main process of the testbench.  This process reads
    --! the stimulus file, parses it, creates lists of records, then uses these
    --! lists to execute user instructions.  There are two passes through the
    --! script.  Pass one reads in the stimulus text file, checks it, creates
    --! lists of valid instructions, valid list of variables and finally a list
    --! of user instructions(the sequence).  The second pass through the file,
    --! records are drawn from the user inst list, variables are converted
    --! to integers and put through the elsif structure for exicution.

    read_files : process       
        variable inst_defs : inst_def_list;
        variable code_files : file_def_list; 
        variable insts : inst_sequence;
        variable vars : var_pool_ordered;
        variable procs : proc_pool_ordered;
        variable absolute_code_file_name : text_line;
        variable inst : text_field;
        variable il : integer;
        variable inst_parse_context : t_stm_inst_parse_context;
        variable par_text_fields : parameter_text_field_array;
        variable par_indexes : parameter_index_array;
        variable par_values : parameter_value_array(1 to 6)(machine_value_width - 1 downto 0);
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable file_line : integer; -- line number in the stimulus file
        variable tmp_file_line : integer; -- line number in the stimulus file
        variable file_name : text_line; -- the file name the line came from
        variable tmp_file_name : text_line; -- the file name the line came from
        variable ien : integer := 0; -- sequence number
        variable ie_ptr : inst_element_ptr;

        variable sp : integer := 0; -- call stack pointer
        variable rc_stack : t_stm_array_of_runtime_context; -- call stack

        variable act_loop_num : integer := 0;
        variable act_curr_loop_count : integer := 0;
        variable act_term_loop_count : integer := 0;
--        variable stack_loop_num : stack_int_array := (others => 0);
--        variable stack_curr_loop_count : stack_int_array_array := (others => (others => 0));
--        variable stack_term_loop_count : stack_int_array_array := (others => (others => 0));
--        variable stack_loop_line : stack_int_array_array := (others => (others => 0));
--        variable stack_loop_if_enter_level : stack_int_array := (others => 0);
        variable loglevel : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);
        variable resume : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);
        variable verify_passes_count : integer := 0;
        variable verify_failure_count : integer := 0;
        variable bus_timeout_passes_count : integer := 0;
        variable bus_timeout_failure_count : integer := 0;
        variable expected_verify_failure_count : integer := 0;
        variable expected_bus_timeout_failure_count : integer := 0;
        variable if_level : integer := 0;
        variable if_state : boolean_array := (others => false);
        variable num_of_if_in_false_if_leave : int_array := (others => 0);
        variable valid : integer;
        variable interrupt_number_entered_stack_pointer : integer := -1;
        variable interrupt_number_entered_stack : interrupt_array := (others => 0);
        variable interrupt_entry_call_stack_ptr_stack : interrupt_array := (others => 0);
        variable v_set_interrupt_in_service : std_logic := '0';

        variable successfull : boolean := false;

        -- random generator seed variables
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;

        --  scratchpad variables
        variable temp_int : integer;
        variable temp_int_b : integer;
        variable stm_value : unsigned(machine_value_width - 1 downto 0);
        variable stm_value_b : unsigned(machine_value_width - 1 downto 0);
        variable par_scopes : parameter_scope_text_field_array;
        variable var_scope : text_field;
        variable var_index : integer;
        variable number_found : integer;
        variable stm_value_ptr : t_stm_value_ptr;

        variable temp_marker : std_logic_vector(15 downto 0) := (others => '0');

        variable trc_on : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);

        file stimulus : text; -- file main file
        variable v_stat : file_open_status;

        -- Bus
        type bus_timeout_array is array (0 to 127) of time;
        variable bus_timeouts : bus_timeout_array := (others => 1 sec);

        -- Array
        variable var_stm_array : t_stm_array_ptr;

        -- Label
        variable var_stm_label : text_field_ptr;

        -- Text
        variable var_stm_text : stm_text_ptr;
        variable var_stm_text_enclosing_quote : character;
        variable var_stm_text_out : stm_text_ptr;
        variable var_stm_text_substituded : stm_text;
        variable var_stm_text_substituded_ptr : stm_text_ptr;

        -- File
        file user_file_0 : text;
        file user_file_1 : text;
        file user_file_2 : text;
        file user_file_3 : text;
        variable user_file_name_0 : stm_text_ptr;
        variable user_file_name_1 : stm_text_ptr;
        variable user_file_name_2 : stm_text_ptr;
        variable user_file_name_3 : stm_text_ptr;
        variable user_file_in_use_0 : boolean;
        variable user_file_in_use_1 : boolean;
        variable user_file_in_use_2 : boolean;
        variable user_file_in_use_3 : boolean;
        variable user_file_path_string : stm_text;
        variable user_file_append_done : boolean;
        variable user_file_open_done : boolean;
        variable user_std_line : line;
        variable tmp_std_line : line;
        variable stm_lines_append_valid : integer := 0;

        -- Lines
        variable var_stm_lines : t_stm_lines_ptr;

        variable main_proc_name : text_field;
        variable main_inst_element : integer := 0;
        variable main_entered : integer := 0;

        variable interrupt_requests : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');
        variable interrupt_in_service : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');

        variable interrupt_number : integer := 0;
        variable branch_to_interrupt : boolean := false;
        variable branch_to_interrupt_proc : text_field;
        variable branch_to_interrupt_proc_std_txt_io_line : line;
        variable branch_to_interrupt_instruction_element_number : integer := 0;

        variable tmp_called_proc : text_field;
        variable no_scope : text_field;
        variable none : text_field;
        variable pass : integer;
        
        variable ipc : t_stm_inst_parse_context;
        variable rc : t_stm_runtime_context;

    begin
        nul_scope(1) := nul;
        marker <= (others => '0');
        verify_passes <= (others => '0');
        verify_failures <= (others => '0');
        bus_timeout_passes <= (others => '0');
        bus_timeout_failures <= (others => '0');
        signals_out <= signals_out_init;
        bus_down <= bus_down_init;

        wait for 0 ns;

        init_const_text_field(stimulus_main_entry_label, main_proc_name);
        init_const_text_field(".", no_scope);
        init_const_text_field("no_proc", no_proc);
        init_const_text_line("no_file", no_file);
        define_instructions(inst_def_list);
        init_inst_parse_context(inst_context);
        init_inst_sequence(insts);
        
        make_absolut_code_file_name(stimulus_path, stimulus_file, absolute_code_file_name);
        print("collect_code_files");
        collect_code_files(absolute_code_file_name, code_files);
        print("parsing constants");
        parse_constants(code_files);
        print("parsing variables");
        parse_variables(code_files);
        print("parsing instructions and procs");
        parse_instructions_and_procs(code_files);
        print("parsing done");

        init_inst_parse_context(inst_context);
        ien := 0;
        last_searched_inst_element_number := 0;
        last_searched_inst_element_ptr := inst_list;
        print("Checking if all variables are initially defined for all instructions");
        while ien < inst_list.element_count loop
            ien := ien + 1;
            search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
            access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
            track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
            if inst_context.in_call_advanced_parameters
                or inst_context.in_call_label_advanced_parameters then
                par_scopes(2) := inst_context.in_called_proc_name;
            end if;
            access_inst_element_parameters(var_list, file_line, file_name, par_scopes, par_text_fields, par_indexes, par_values);
        end loop;

        ien := 0;
        last_searched_inst_element_number := 0;
        last_searched_inst_element_ptr := inst_list;

        sp := 0;
        for i in 0 to stack'length - 1 loop
            init_runtime_context(rcs(i));
        end loop;
        
        -- using the inst list, get the inst element and execute it as per the statements in the elsif tree.
        while ien < inst_list.element_count loop

            verify_passes <= std_logic_vector(to_unsigned(verify_passes_count, 32));
            verify_failures <= std_logic_vector(to_unsigned(verify_failure_count, 32));
            bus_timeout_passes <= std_logic_vector(to_unsigned(bus_timeout_passes_count, 32));
            bus_timeout_failures <= std_logic_vector(to_unsigned(bus_timeout_failure_count, 32));

            get_interrupt_requests(signals_in, interrupt_requests);
            if interrupt_requests > 0 then
                if not inst_context.in_proc_advanced_parameters and not inst_context.in_call_advanced_parameters then
                    resolve_interrupt_requests(interrupt_requests, interrupt_in_service, interrupt_number, branch_to_interrupt, branch_to_interrupt_proc_std_txt_io_line);
                end if;
            end if;

            if main_entered = 0 then
                -- main entry points have no parameters and have the form 'proc testMainSomething ()'.
                -- main tests mustn't reach their end proc but must be terminated by a reasonable finish instruction inside the proc                  
                access_var(var_list, nul_scope, main_proc_name, var_index, main_inst_element, valid, machine_value_width);
                assert valid /= 0
                report lf & "Entry point proc Main:'" & main_proc_name(1 to fld_len(main_proc_name)) & "' scope:'.' not found !"
                severity failure;  
                ien := main_inst_element;
                search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                print("exec main entry line " & (integer'image(file_line)) & " " & inst(1 to il) & " in file " & text_line_crop(file_name));
                main_entered := 1;
                sp := sp + 1; 
                init_runtime_context(rcs(sp));    
                rcs(sp).inst_element_number_of_called_proc := ien;                     
                rcs(sp).called_proc := main_proc_name;
                rcs(sp).called_in_file_line := file_line;
                rcs(sp).called_in_file_name := file_name;

            elsif branch_to_interrupt then
                if (sp >= 31) then
                    assert false
                    report " line " & (integer'image(file_line)) & " interrupt enter stack over run, calls to deeply nested!!"
                    severity failure;
                end if;
                if (sp >= 31) then
                    assert false
                    report " line " & (integer'image(file_line)) & " interrupt enter interrupt number stack over run, interrupts to deeply nested!!"
                    severity failure;
                end if;
                interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer + 1;
                interrupt_number_entered_stack(interrupt_number_entered_stack_pointer) := interrupt_number;
                interrupt_entry_call_stack_ptr_stack(interrupt_number_entered_stack_pointer) := sp;
                v_set_interrupt_in_service := '1';
                set_interrupt_in_service(interrupt_in_service, interrupt_number, v_set_interrupt_in_service, signals_out);               
                line_to_text_field(branch_to_interrupt_proc_std_txt_io_line, branch_to_interrupt_proc);
                access_var(var_list, nul_scope, branch_to_interrupt_proc, var_index, branch_to_interrupt_instruction_element_number, valid, machine_value_width);
                assert valid /= 0
                report lf & "Interrupt entry point branch_to_interrupt_proc not found !"
                severity failure;
                ien := branch_to_interrupt_instruction_element_number;
                search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                sp := sp + 1; 
                init_runtime_context(rcs(sp));   
                rcs(sp).inst_element_number_of_called_proc := ien;                     
                rcs(sp).called_proc := main_proc_name;
                rcs(sp).called_in_file_line := file_line;
                rcs(sp).called_in_file_name := file_name;                             
                wait for 0 ns;

            else

                ien := ien + 1;
                search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                access_inst_element_parameters(var_list, file_name, file_line, rcs(sp).par_scopes, par_text_fields, par_indexes, par_values);
                if trc_on(3) = '1' then
                    dump_file_defs(file_list);
                end if;
                if trc_on(2) = '1' then
                    dump_vars(var_list, machine_value_width);
                end if;
                if trc_on(1) = '1' then
                    print_inst_element_number(inst_list, ien, file_list);
                end if;

                executing_line <= file_line;
                executing_file <= file_name;
                wait for 100 ps;

                if trc_on(0) = '1' then
                    print("exec line " & (integer'image(file_line)) & " " & inst(1 to il) & " (" & text_line_crop(file_name) & ")");
                end if;

                -- namespace "a_namespace"
                if inst(1 to il) = INSTR_NAMESPACE then
                    null; -- This inst was implemented while reading the file

                -- end namespace
                elsif inst(1 to il) = INSTR_END_NAMESPACE then
                    null; -- This inst was implemented while reading the file

                -- include "an_include.stm"
                elsif inst(1 to il) = INSTR_INCLUDE then
                    null; -- This inst was implemented while reading the file
                --
                -- const a_const_num 0x03
                -- const a_constB a_constA
                -- const a_constC a_varA
                elsif inst(1 to il) = INSTR_CONST then
                    null; -- This inst was implemented while reading the file

                -- var a_varA 0x05
                -- var a_varB a_varA
                -- var a_varC a_constA
                elsif inst(1 to il) = INSTR_VAR then
                    -- This inst has been executed for global variables while reading the file
                    reinit_and_update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " equ cannot update variable, it may be a constant ?"
                    severity failure;

                -- array an_array 16
                elsif inst(1 to il) = INSTR_ARRAY then
                    -- This inst has been executed for global arrays while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    for i in 0 to var_stm_array'length - 1 loop
                        var_stm_array(i) := to_unsigned(0, machine_value_width);
                    end loop;

                -- label a_label a_proc_label
                elsif inst(1 to il) = INSTR_LABEL then
                    -- This inst has been executed for global labels while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, var_stm_label, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " label not found"
                    severity failure;

                -- file a_fileA "file_name"
                -- file a_fileB "file_name{}{}" file_user_index1 file_user_index2
                elsif inst(1 to il) = INSTR_FILE then
                    -- This inst has been executed for global files while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    if var_stm_text_substituded_ptr = user_file_name_0 and user_file_in_use_0 then
                        file_close(user_file_0);
                        user_file_in_use_0 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_1 and user_file_in_use_1 then
                        file_close(user_file_1);
                        user_file_in_use_1 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_2 and user_file_in_use_2 then
                        file_close(user_file_2);
                        user_file_in_use_2 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_3 and user_file_in_use_3 then
                        file_close(user_file_3);
                        user_file_in_use_3 := false;
                    else
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " trying to end file not started or already ended for read"
                        severity failure;
                    end if;

                -- signal a_signal
                elsif inst(1 to il) = INSTR_SIGNAL then
                    -- This inst has been executed for global signals while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report "signal_pointer not a signal object name??"
                    severity failure;

                -- bus a_bus
                elsif inst(1 to il) = INSTR_BUS then
                    -- This inst has been executed for global busses while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report "bus_pointer not a bus object name??"
                    severity failure;

                -- lines a_lines
                elsif inst(1 to il) = INSTR_LINES then
                    -- This inst has been executed for global lines while reading the file
                    index_and_reinit_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    while var_stm_lines.size > 0 loop
                        temp_int := 0;
                        stm_lines_delete(var_stm_lines, temp_int, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines delete all not successful"
                        severity failure;
                    end loop;

                -- equ operand1_equ_target operand2
                -- equ operand1_equ_target 0xF0
                elsif inst(1 to il) = INSTR_EQU or inst(1 to il) =  INSTR_EQU_PAR_CLOSE then
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " equ cannot update variable, it may be a constant ?"
                    severity failure;
                    if inst(1 to il) = INSTR_EQU_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- d_var s_var
                -- d_var s_var )
                elsif inst(1 to il) = INSTR_VAR_POINTER_COPY or inst(1 to il) = INSTR_VAR_POINTER_COPY_PAR_CLOSE then
                    index_var_value_ptr(var_list, par_indexes(2), var_scope, stm_value_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " var not found"
                    severity failure;
                    update_var_value_ptr(var_list, par_indexes(1), stm_value_ptr, valid);
                    assert valid /= 0
                    report "var_pointer not a var name??"
                    severity failure;
                    if inst(1 to il) = INSTR_VAR_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- add operand1_and_target operand2
                -- add operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_ADD then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add not a valid variable??"
                    severity failure;
                    stm_value := stm_value + par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add cannot update variable, it may be a constant ?"
                    severity failure;

                -- sub operand1_and_target operand2
                -- sub operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_SUB then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub not a valid variable??"
                    severity failure;
                    stm_value := stm_value - par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub cannot update variable, it may be a constant ?"
                    severity failure;

                -- mul operand1_and_target operand2
                -- mul operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_MUL then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := resize(resize(stm_value, machine_value_width * 2) * resize(par_values(2), machine_value_width * 2), machine_value_width);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul cannot update variable, it may be a constant ?"
                    severity failure;

                -- div operand1_and_target operand2
                -- div operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_DIV then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := stm_value / par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " div cannot update variable, it may be a constant ?"
                    severity failure;

                -- rem operand1_and_target operand2
                -- rem operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_REM then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := stm_value rem par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " div cannot update variable, it may be a constant ?"
                    severity failure;

                -- and operand1_and_target operand2
                -- and operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_AND then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := stm_value and par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " and cannot update variable, it may be a constant ?"
                    severity failure;

                -- or operand1_and_target operand2
                -- or operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_OR then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := stm_value or par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " or cannot update variable, it may be a constant ?"
                    severity failure;

                -- xor operand1_and_target operand2
                -- xor operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_XOR then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := stm_value xor par_values(2);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " xor cannot update variable, it may be a constant ?"
                    severity failure;

                -- shl operand1_and_target operand2
                -- shl operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_SHL then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := shift_left(stm_value, to_integer(par_values(2)(30 downto 0)));
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul cannot update variable, it may be a constant ?"
                    severity failure;

                -- shr operand1_and_target operand2
                -- shr operand1_and_target 0xF0
                elsif inst(1 to il) = INSTR_SHR then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := shift_right(stm_value, to_integer(par_values(2)(30 downto 0)));
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul cannot update variable, it may be a constant ?"
                    severity failure;

                -- inv operand1_and_target
                elsif inst(1 to il) = INSTR_INV then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := not stm_value;
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " inv cannot update variable, it may be a constant ?"
                    severity failure;

                -- ld operand1_and_target
                elsif inst(1 to il) = INSTR_LD then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value := ld(stm_value);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " ld cannot update variable, it may be a constant ?"
                    severity failure;

                -- array set an_array array_position 0x07
                -- array set an_array array_position a_varA
                -- array set an_array 5 0x07
                -- array set an_array 3 a_varA
                elsif inst(1 to il) = INSTR_ARRAY_SET then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    assert var_stm_array'length > par_values(2)
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " index is out of array size"
                    severity failure;
                    var_stm_array(to_integer(par_values(2)(30 downto 0))) := par_values(3);

                -- array get an_array array_position a_varB
                elsif inst(1 to il) = INSTR_ARRAY_GET then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    assert var_stm_array'length > par_values(2)
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " index is out of array size"
                    severity failure;
                    stm_value := var_stm_array(to_integer(par_values(2)(30 downto 0)));
                    update_var(var_list, par_indexes(3), stm_value, valid);
                    assert valid /= 0
                    report "array_get not a valid variable??"
                    severity failure;

                --  array size an_array array_size
                elsif inst(1 to il) = INSTR_ARRAY_SIZE then
                    temp_int := 0;
                    index_var(var_list, par_indexes(1), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    stm_value := to_unsigned(var_stm_array'length, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report "array_size not a valid variable??"
                    severity failure;

                -- array pointer an_array another_array
                -- array pointer an_array another_array )
                elsif inst(1 to il) = INSTR_ARRAY_POINTER_COPY or inst(1 to il) =  INSTR_ARRAY_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), var_stm_array, valid);
                    assert valid /= 0
                    report "array_pointer not a array name??"
                    severity failure;
                    if inst(1 to il) = INSTR_ARRAY_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- array verify a_var array_position var_expected_value var_mask_value
                -- array verify a_var array_position 0x0002 0x00FF
                -- array verify a_var 5 var_expected_value var_mask_value
                -- array verify a_var 5 0x0002 0x00FF
                elsif inst(1 to il) = INSTR_ARRAY_VERIFY then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array not found"
                    severity failure;
                    assert var_stm_array'length > par_values(2)
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " index is out of array size"
                    severity failure;
                    verify_passes_count := verify_passes_count + 1;
                    stm_value := var_stm_array(to_integer(par_values(2)(30 downto 0)));
                    if (par_values(4) and stm_value) /= (par_values(4) and par_values(3)) then
                        print("index    = 0x" & to_hstring(par_values(2)));
                        print("read     = 0x" & to_hstring(stm_value));
                        print("expected = 0x" & to_hstring(par_values(3)));
                        print("mask     = 0x" & to_hstring(par_values(4)));
                        if resume(0) = '0' then
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & text_line_crop(file_name)
                            severity failure;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & text_line_crop(file_name)
                            severity error;
                            verify_failure_count := verify_failure_count + 1;
                        end if;
                    end if;

                -- label pointer copy a_label another_label
                -- label pointer copy a_label another_label )
                elsif inst(1 to il) = INSTR_LABEL_POINTER_COPY or inst(1 to il) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, var_stm_label, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " label not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), var_stm_label, valid);
                    assert valid /= 0
                    report "label_pointer not a label name??"
                    severity failure;
                    if inst(1 to il) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- equ label1_equ_target label2
                -- equ label1_equ_target label2 )
                elsif inst(1 to il) = INSTR_LABEL_EQU or inst(1 to il) =  INSTR_LABEL_EQU_PAR_CLOSE then
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " equ cannot update variable, it may be a constant ?"
                    severity failure; 
                    if inst(1 to il) = INSTR_LABEL_EQU_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- file readable a_fileA target
                elsif inst(1 to il) = INSTR_FILE_READABLE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_readable(var_stm_text_substituded_ptr, temp_int);
                    stm_value := to_unsigned(temp_int, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " cannot update variable, it may be a constant ?"
                    severity failure;

                -- file writeable a_fileA target
                elsif inst(1 to il) = INSTR_FILE_WRITABLE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_writeable(var_stm_text_substituded_ptr, temp_int);
                    stm_value := to_unsigned(temp_int, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " cannot update variable, it may be a constant ?"
                    severity failure;

                -- file appendable a_fileA target
                elsif inst(1 to il) = INSTR_FILE_APPENDABLE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_appendable(var_stm_text_substituded_ptr, temp_int);
                    stm_value := to_unsigned(temp_int, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " cannot update variable, it may be a constant ?"
                    severity failure;

                -- file write a_fileA a_lines
                elsif inst(1 to il) = INSTR_FILE_WRITE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_write(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file write not successful"
                    severity failure;

                -- file append a_fileB  a_lines
                elsif inst(1 to il) = INSTR_FILE_APPEND then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_append(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file append not successful"
                    severity failure;

                -- file read a_fileA a_lines number_of_lines
                -- file read a_fileA a_lines 256
                elsif inst(1 to il) = INSTR_FILE_READ then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " position object not found"
                    severity failure;
                    user_file_append_done := false;
                    -- if file is already in use, us it
                    if user_file_in_use_0 then
                        if var_stm_text = user_file_name_0 then
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_1 then
                        if var_stm_text = user_file_name_1 then
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_2 then
                        if var_stm_text = user_file_name_2 then
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_3 then
                        if var_stm_text = user_file_name_3 then
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    -- if file is not in use, try to open and use it
                    if not user_file_append_done then
                        stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                        var_stm_text_substituded_ptr := new stm_text;
                        stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                        txt_to_string(var_stm_text_substituded_ptr, user_file_path_string);
                        user_file_open_done := false;
                        if not user_file_in_use_0 and not user_file_open_done then
                            file_open(v_stat, user_file_0, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                            severity failure;
                            user_file_name_0 := var_stm_text;
                            user_file_in_use_0 := true;
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_1 and not user_file_open_done then
                            file_open(v_stat, user_file_1, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                            severity failure;
                            user_file_name_1 := var_stm_text;
                            user_file_in_use_1 := true;
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_2 and not user_file_open_done then
                            file_open(v_stat, user_file_2, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                            severity failure;
                            user_file_name_2 := var_stm_text;
                            user_file_in_use_2 := true;
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_3 and not user_file_open_done then
                            file_open(v_stat, user_file_3, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                            severity failure;
                            user_file_name_3 := var_stm_text;
                            user_file_in_use_3 := true;
                            for i in 1 to to_integer(par_values(3)(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " line couldn't be appended"
                                severity failure;
                            end loop;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " only 4 files are allowed for file read concurrently"
                            severity failure;
                        end if;
                    end if;

                -- file read end a_fileA a_lines
                elsif inst(1 to il) = INSTR_FILE_READ_END then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    if var_stm_text_substituded_ptr = user_file_name_0 and user_file_in_use_0 then
                        file_close(user_file_0);
                        user_file_in_use_0 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_1 and user_file_in_use_1 then
                        file_close(user_file_1);
                        user_file_in_use_1 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_2 and user_file_in_use_2 then
                        file_close(user_file_2);
                        user_file_in_use_2 := false;
                    elsif var_stm_text_substituded_ptr = user_file_name_3 and user_file_in_use_3 then
                        file_close(user_file_3);
                        user_file_in_use_3 := false;
                    else
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " trying to end file not started or already ended for read"
                        severity failure;
                    end if;

                -- file read all a_fileA a_lines
                elsif inst(1 to il) = INSTR_FILE_READ_ALL then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file object not found"
                    severity failure;
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " position object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, var_stm_text, var_stm_text_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_read_all(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " file read not successful"
                    severity failure;

                --  file pointer copy a_file_target a_file_source
                --  file pointer copy a_file_target a_file_source )
                elsif inst(1 to il) = INSTR_FILE_POINTER_COPY or inst(1 to il) = INSTR_FILE_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), var_stm_text, valid);
                    assert valid /= 0
                    report "files_pointer not a lines object name??"
                    severity failure;
                    if inst(1 to il) = INSTR_FILE_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- lines get a_lines position an_array number_found
                -- lines get a_lines 8 an_array number_found
                elsif inst(1 to il) = INSTR_LINES_GET_ARRAY then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    index_var(var_list, par_indexes(3), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not found"
                    severity failure;
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_get(var_stm_lines, temp_int, var_stm_array, number_found, valid, machine_value_width);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object does not get successfully"
                    severity failure;
                    update_var(var_list, par_indexes(3), var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " cannot update variable, it may be a constant ?"
                    severity failure;
                    stm_value := to_unsigned(number_found, machine_value_width);
                    update_var(var_list, par_indexes(4), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " cannot update variable, it may be a constant ?"
                    severity failure;

                -- lines set a_lines position an_array
                -- lines set a_lines 9 an_array
                elsif inst(1 to il) = INSTR_LINES_SET_ARRAY then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    index_var(var_list, par_indexes(3), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not found"
                    severity failure;
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_set(var_stm_lines, temp_int, var_stm_array, valid, machine_value_width);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not set successfully"
                    severity failure;

                -- lines set a_lines position "abc" txt
                -- lines set a_lines 7 "abc"
                -- lines set a_lines position "abc{}" a_varB
                -- lines set a_lines 7 "abc{}" a_varB
                elsif inst(1 to il) = INSTR_LINES_SET_MESSAGE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, txt, txt_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_set(var_stm_lines, temp_int, var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " message not set successfully"
                    severity failure;

                -- lines insert a_lines position an_array
                -- lines insert a_lines 9 an_array
                elsif inst(1 to il) = INSTR_LINES_INSERT_ARRAY then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    index_var(var_list, par_indexes(3), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not found"
                    severity failure;
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_insert(var_stm_lines, temp_int, var_stm_array, valid, machine_value_width);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not inserted successfully"
                    severity failure;

                -- lines insert a_lines position "abc"
                -- lines insert a_lines 7 "abc"
                -- lines insert a_lines position "abc{}" a_varB
                -- lines insert a_lines 7 "abc{}" a_varB
                elsif inst(1 to il) = INSTR_LINES_INSERT_MESSAGE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, txt, txt_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_insert(var_stm_lines, temp_int, var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " message not inserted successfully"
                    severity failure;

                -- lines append a_lines an_array
                elsif inst(1 to il) = INSTR_LINES_APPEND_ARRAY then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    index_var(var_list, par_indexes(2), var_scope, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " array object not found"
                    severity failure;
                    stm_lines_append(var_stm_lines, var_stm_array, valid, machine_value_width);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines append not successful"
                    severity failure;

                -- lines append a_lines "abc"
                -- lines append a_lines "abc{}" a_varB
                elsif inst(1 to il) = INSTR_LINES_APPEND_MESSAGE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(var_list, var_scope, txt, txt_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    stm_lines_append(var_stm_lines, var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines append not successful"
                    severity failure;

                -- lines delete a_lines position
                -- lines delete a_lines 13
                elsif inst(1 to il) = INSTR_LINES_DELETE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    stm_lines_delete(var_stm_lines, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines delete not successful"
                    severity failure;

                -- lines delete all a_lines
                elsif inst(1 to il) = INSTR_LINES_DELETE_ALL then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    while var_stm_lines.size > 0 loop
                        temp_int := 0;
                        stm_lines_delete(var_stm_lines, temp_int, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines delete all not successful"
                        severity failure;
                    end loop;

                -- lines size a_lines read_size
                elsif inst(1 to il) = INSTR_LINES_SIZE then
                    index_var(var_list, par_indexes(1), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report "line_size not a valid variable??"
                    severity failure;
                    stm_value := to_unsigned(var_stm_lines.size, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value, valid);

                --  lines pointer copy a_lines_target a_lines_source
                --  lines pointer copy a_lines_target a_lines_source 
                elsif inst(1 to il) = INSTR_LINES_POINTER_COPY or inst(1 to il) = INSTR_LINES_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), var_stm_lines, valid);
                    assert valid /= 0
                    report "lines_pointer not a lines object name??"
                    severity failure;
                    if inst(1 to il) = INSTR_LINES_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                -- if a_var_ref = another_var
                -- if 0x09 = another_var
                -- if a_varA = 0x09
                -- if 0x09 = 0x09
                elsif inst(1 to il) = INSTR_IF then
                    if_level := if_level + 1;
                    if_state(if_level) := false;
                    if trc_on(4) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  incremented if_level " & integer'image(if_level);
                    end if;
                    case to_integer(par_values(2)(30 downto 0)) is
                        when 0 => if (par_values(1) = par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when 1 => if (par_values(1) > par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when 2 => if (par_values(1) < par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when 3 => if (par_values(1) /= par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when 4 => if (par_values(1) >= par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when 5 => if (par_values(1) <= par_values(3)) then
                                if_state(if_level) := true;
                            end if;
                        when others =>
                            assert false
                            report " line " & (integer'image(file_line)) & "  if inst got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_text_field(file_line, dec)) & " in file " & text_line_crop(file_name)
                            severity failure;
                    end case;
                    if trc_on(4) = '1' then
                        if if_state(if_level) = true then
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) = false then
                        ien := ien + 1;
                        ien := branch_to_interrupt_instruction_element_number;
                        search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                        access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                        par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                        access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 or (inst(1 to il) /= INSTR_ELSE and inst(1 to il) /= INSTR_ELSIF and inst(1 to il) /= INSTR_END_IF) loop
                            if inst(1 to il) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if inst(1 to il) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert ien < inst_list.num_of_lines
                            report " line " & (integer'image(file_line)) & "  if inst unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            ien := ien + 1;
                            ien := branch_to_interrupt_instruction_element_number;
                            search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                            access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                            track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                            access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        end loop;
                        if trc_on(4) = '1' then
                            report inst(1 to il) & ":  num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level));
                        end if;
                        ien := ien - 1; -- re-align so it will be operated on.
                    end if;

                -- elsif a_varA > another_var
                -- 0x09 > another_var
                -- a_varA > 0x09
                -- elsif 0x0A > 0x09
                elsif inst(1 to il) = INSTR_ELSIF then
                    if trc_on(4) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  if_level is " & integer'image(if_level);
                        if if_state(if_level) = true then
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip to the end
                        ien := ien + 1;
                        ien := branch_to_interrupt_instruction_element_number;
                        search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                        access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                        par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                        access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        while (inst(1 to il) /= INSTR_IF) and inst(1 to il) /= INSTR_END_IF loop
                            assert ien < inst_list.num_of_lines
                            report " line " & (integer'image(file_line)) & "  if inst unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            ien := ien + 1;
                            ien := branch_to_interrupt_instruction_element_number;
                            search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                            access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                            track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                            access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        end loop;
                        ien := ien - 1; -- re-align so it will be operated on.
                    else
                        case to_integer(par_values(2)(30 downto 0)) is
                            when 0 => if par_values(1) = par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when 1 => if par_values(1) > par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when 2 => if par_values(1) < par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when 3 => if par_values(1) /= par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when 4 => if par_values(1) >= par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when 5 => if par_values(1) <= par_values(3) then
                                    if_state(if_level) := true;
                                end if;
                            when others =>
                                assert false
                                report " line " & (integer'image(file_line)) & "  elsif inst got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_text_field(file_line, dec)) & " in file " & text_line_crop(file_name)
                                severity failure;
                        end case;
                        if trc_on(4) = '1' then
                            if if_state(if_level) = true then
                                report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is true";
                            else
                                report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is false";
                            end if;
                        end if;
                        if if_state(if_level) = false then
                            ien := ien + 1;
                            ien := branch_to_interrupt_instruction_element_number;
                            search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                            access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                            track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                            access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                            num_of_if_in_false_if_leave(if_level) := 0;
                            while num_of_if_in_false_if_leave(if_level) /= 0 or (inst(1 to il) /= INSTR_ELSE and inst(1 to il) /= INSTR_ELSIF and inst(1 to il) /= INSTR_END_IF) loop
                                if inst(1 to il) = INSTR_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                                end if;
                                if inst(1 to il) = INSTR_END_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                                end if;
                                assert ien < inst_list.num_of_lines
                                report " line " & (integer'image(file_line)) & "  elsif inst unable to find terminating" & lf & "    else, elsif or end_if statement."
                                severity failure;
                                ien := ien + 1;
                                ien := branch_to_interrupt_instruction_element_number;
                                search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                                access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                                track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                                par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                                access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                            end loop;
                            if trc_on(4) = '1' then
                                report inst(1 to il) & ":  num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level));
                            end if;
                            ien := ien - 1; -- re-align so it will be operated on.
                        end if;
                    end if;

                -- else
                elsif inst(1 to il) = INSTR_ELSE then
                    if trc_on(4) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  if_level is " & integer'image(if_level);
                        if if_state(if_level) = true then
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else
                            report inst(1 to il) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip the else
                        ien := ien + 1;
                        ien := branch_to_interrupt_instruction_element_number;
                        search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                        access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                        track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                        par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                        access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 or inst(1 to il) /= INSTR_END_IF loop
                            if inst(1 to il) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if inst(1 to il) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert ien < inst_list.num_of_lines
                            report " line " & (integer'image(file_line)) & "  else inst unable to find terminating" & lf & "    end_if statement."
                            severity failure;
                            ien := ien + 1;
                            ien := branch_to_interrupt_instruction_element_number;
                            search_inst_element_ptr(inst_list, ien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                            access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                            track_inst_context(inst, par_text_fields, file_line, file_name, var_list, inst_context);
                            par_scopes := (others => textfield_dot_cat(inst_context.in_namespace_name, inst_context.in_proc_name));
                            access_inst_element_parameters(var_list, file_name, file_line, par_scopes, par_text_fields, par_indexes, par_values);
                        end loop;
                        ien := ien - 1; -- re-align so it will be operated on.
                    end if;

                -- end if
                elsif inst(1 to il) = INSTR_END_IF then
                    if_level := if_level - 1;
                    if trc_on(4) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  decremented if_level " & integer'image(if_level);
                    end if;

                -- loop loop_num
                -- loop 100
                elsif inst(1 to il) = INSTR_LOOP then
                    stack_loop_if_enter_level(sp) := if_level;
                    act_loop_num := stack_loop_num(sp);
                    if trc_on(5) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  sp:" & integer'image(sp);
                        report inst(1 to il) & ":  stack_loop_if_enter_level(" & integer'image(sp) & ")=" & integer'image(if_level);
                        report inst(1 to il) & ":  act_loop_num: stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num);
                    end if;
                    act_loop_num := act_loop_num + 1;
                    stack_loop_num(sp) := act_loop_num;
                    stack_loop_line(sp)(act_loop_num) := ien;
                    stack_curr_loop_count(sp)(act_loop_num) := 0;
                    stack_term_loop_count(sp)(act_loop_num) := to_integer(par_values(1)(30 downto 0));
                    if trc_on(5) = '1' then
                        report inst(1 to il) & ":  incremented stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num);
                        report inst(1 to il) & ":  set to goto ien: stack_loop_line(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(ien);
                        report inst(1 to il) & ":  stack_curr_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(stack_curr_loop_count(sp)(act_loop_num));
                        report inst(1 to il) & ":  stack_term_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(stack_term_loop_count(sp)(act_loop_num));
                    end if;

                -- end loop
                elsif inst(1 to il) = INSTR_END_LOOP then
                    act_loop_num := stack_loop_num(sp);
                    act_curr_loop_count := stack_curr_loop_count(sp)(act_loop_num);
                    act_curr_loop_count := act_curr_loop_count + 1;
                    stack_curr_loop_count(sp)(act_loop_num) := act_curr_loop_count;
                    act_term_loop_count := stack_term_loop_count(sp)(act_loop_num);
                    if trc_on(5) = '1' then
                        index_var_value_ptr(var_list, par_indexes(2), var_scope, stm_value_ptr, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " var not found"
                        severity failure;
                        update_var_value_ptr(var_list, par_indexes(1), stm_value_ptr, valid);
                        assert valid /= 0
                        report "var_pointer not a var name??"
                        severity failure; 
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  sp:" & integer'image(sp);
                        report inst(1 to il) & ":  act_loop_num: stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num);
                        report inst(1 to il) & ":  set incremented stack_curr_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_curr_loop_count);
                        report inst(1 to il) & ":  stack_term_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_term_loop_count);
                    end if;
                    if (act_curr_loop_count = act_term_loop_count) then
                        act_loop_num := act_loop_num - 1;
                        stack_loop_num(sp) := act_loop_num;
                        if trc_on(5) = '1' then
                            report inst(1 to il) & ":  expired, set decremented stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num);
                        end if;
                    else
                        ien := stack_loop_line(sp)(act_loop_num);
                        if trc_on(5) = '1' then
                            report inst(1 to il) & ":  next goto ien: stack_loop_line(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(ien);
                        end if;
                    end if;

                -- abort
                elsif inst(1 to il) = INSTR_ABORT then
                    assert false
                    report "the test has aborted due to an error!!"
                    severity failure;
                    finish;

                -- stop
                elsif inst(1 to il) = INSTR_STOP then
                    assert false
                    report "the test has been stopped for debugging by command !!"
                    severity failure;

                -- finish
                elsif inst(1 to il) = INSTR_FINISH then
                    expected_verify_failure_count := to_integer(unsigned(signals_out.out_signal_5(30 downto 0)));
                    expected_bus_timeout_failure_count := to_integer(unsigned(signals_out.out_signal_7(30 downto 0)));
                    print("Verify passes " & (integer'image(verify_passes_count)));
                    print("Timeout monitored bus access passes " & (integer'image(bus_timeout_passes_count)));
                    if expected_verify_failure_count /= 0 and expected_bus_timeout_failure_count /= 0 then
                        print("Expected " & (integer'image(expected_verify_failure_count)) & " verify failures, got " & (integer'image(verify_failure_count)));
                        print("Expected " & (integer'image(expected_bus_timeout_failure_count)) & " bus timeout failures, got " & (integer'image(bus_timeout_failure_count)));
                        if expected_verify_failure_count /= verify_failure_count then
                            print("FAILURES");
                            print("Test finished");
                            wait for 1000 ns;
                            finish;
                        end if;
                        if expected_bus_timeout_failure_count /= bus_timeout_failure_count then
                            print("FAILURES");
                            print("Test finished");
                            wait for 1000 ns;
                            finish;
                        end if;
                        print("SUCCESS");
                        wait for 1000 ns;
                        finish;
                    elsif expected_verify_failure_count /= 0 then
                        report "Expected " & (integer'image(expected_verify_failure_count)) & " verify failures, got " & (integer'image(verify_failure_count));
                        if expected_verify_failure_count /= verify_failure_count then
                            print("FAILURES");
                            print("Test finished");
                            wait for 1000 ns;
                            finish;
                        end if;
                        print("SUCCESS");
                        wait for 1000 ns;
                        finish;
                    elsif expected_bus_timeout_failure_count /= 0 then
                        report "Expected " & (integer'image(expected_bus_timeout_failure_count)) & " bus timeout failures, got " & (integer'image(bus_timeout_failure_count));
                        if expected_bus_timeout_failure_count /= bus_timeout_failure_count then
                            print("FAILURES");
                            print("Test finished");
                            wait for 1000 ns;
                            finish;
                        end if;
                        print("SUCCESS");
                        wait for 1000 ns;
                        finish;
                    end if;
                    print("SUCCESS");
                    print("Test finished");
                    wait for 1000 ns;
                    finish;

                -- proc
                elsif inst(1 to il) = INSTR_PROC
                      or inst(1 to il) = INSTR_PROC_PAR_OPEN
                      or inst(1 to il) = INSTR_PROC_PAR_NOPAR_0
                      or inst(1 to il) = INSTR_PROC_PAR_NOPAR_1 then
                    null; -- no action necessary

                -- end proc
                -- end interrupt
                -- return
                elsif inst(1 to il) = INSTR_RETURN or inst(1 to il) = INSTR_END_PROC or inst(1 to il) = INSTR_END_INTERRUPT then
                    if trc_on(5) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  sp:" & integer'image(sp);
                    end if;
                    act_loop_num := stack_loop_num(sp);
                    if act_loop_num > 0 then
                        if_level := stack_loop_if_enter_level(sp);
                        stack_loop_num(sp) := 0;
                    end if;
                    if sp = 0 then
                        report "Leaving proc Main and halt at line " & (integer'image(file_line)) & " " & inst(1 to il) & " file " & text_line_crop(file_name);
                        wait;
                    end if;
                    assert sp >= 0
                    report " line " & (integer'image(file_line)) & " call stack under run??"
                    severity failure;
                    sp := sp - 1;
                    if interrupt_in_service > 0 then
                        interrupt_number := interrupt_number_entered_stack(interrupt_number_entered_stack_pointer);
                        if interrupt_entry_call_stack_ptr_stack(interrupt_number) = sp then
                            v_set_interrupt_in_service := '0';
                            set_interrupt_in_service(interrupt_in_service, interrupt_number, v_set_interrupt_in_service, signals_out);
                            interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer - 1;
                        end if;
                    end if;     
                    runtime_context := stack_runtime_context(sp);
                    ien := runtime_context.inst_element_number_to_return_to_after_call;
                    if trc_on(5) = '1' then
                        print("Popping runtime_context from stack_runtime_context("  & integer'image(sp) & ")");
                        print_runtime_context(runtime_context);       
                    end if;                   
                    if trc_on(5) = '1' then                        
                        report inst(1 to il) & ":  restored if_level: stack_loop_if_enter_level(" & integer'image(sp) & ") = " & integer'image(if_level);
                        report inst(1 to il) & ":  restored act_loop_num: stack_loop_num(" & integer'image(sp) & ") = " & integer'image(act_loop_num);
                    end if;
                    wait for 0 ns;

                -- call some_proc ()
                -- call some_proc (
                -- call label some_label ()
                -- call label some_label (
                elsif inst(1 to il) = INSTR_CALL_NOPAR 
                      or inst(1 to il) = INSTR_CALL_PAR_OPEN
                      or inst(1 to il) = INSTR_CALL_LABEL_NOPAR
                      or inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
                    if trc_on(5) = '1' then
                        report inst(1 to il) & ": ien: " & integer'image(ien) & ";  code line: " & (ew_to_text_field(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report inst(1 to il) & ":  sp:" & integer'image(sp);
                    end if;
                    assert sp < 31
                    report " line " & (integer'image(file_line)) & " call stack over run, calls to deeply nested!!"
                    severity failure;
                    
                    if inst(1 to il) = INSTR_CALL_NOPAR 
                       or inst(1 to il) = INSTR_CALL_LABEL_NOPAR then
                        rcs(sp).inst_element_number_to_return_to_after_call := ien;
                    else 
                        pien := ien:
                        while pinst(1 to il) = INSTR_PAR_CLOSE loop
                            search_inst_element_ptr(inst_list, pien, last_searched_inst_element_number, last_searched_inst_element_ptr, ie_ptr);
                        access_inst_element_ptr(ie_ptr, file_list, inst, il, par_text_fields, txt, txt_enclosing_quote, file_line, file_name);
                    
                        end loop;
                    end if;                   
                    
                    

                sp := sp + 1; 
                init_runtime_context(rcs(sp));    
                rcs(sp).inst_element_number_of_called_proc := ien;                     
                rcs(sp).called_proc := main_proc_name;
                rcs(sp).called_in_file_line := file_line;
                rcs(sp).called_in_file_name := file_name;                   
                    
                    
                    sp := sp + 1; 
                    runtime_context.inst_element_number_to_return_to_after_call := ien; 
                    stack_runtime_context(sp) := runtime_context;
                    if trc_on(5) = '1' then
                        print("Pushing runtime_context to stack_runtime_context("  & integer'image(sp) & ")");
                        print_runtime_context(runtime_context);       
                    end if;
                    runtime_context.inst_element_number_of_called_proc_params_end := -1;
                    runtime_context.inst_element_number_of_call_params := -1;                     
                    runtime_context.called_in_file_line := file_line;
                    runtime_context.called_in_file_name := file_name;
                    runtime_context.par_scopes := (others => no_scope);                                          
                    if inst(1 to il) = INSTR_CALL 
                       or inst(1 to il) = INSTR_CALL_PAR_NOPAR 
                       or inst(1 to il) = INSTR_CALL_PAR_OPEN then
                        runtime_context.inst_element_number_of_called_proc := to_integer(par1(30 downto 0)) - 1;                  
                        runtime_context.in_call_of_proc_name := par_text_fields(1);   
                    elsif inst(1 to il) = INSTR_CALL_LABEL_PAR_NOPAR
                          or inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then
                        access_var_label_ptr(var_list, par_text_fields(1), par_text_fields(1), var_index, tmp_label_proc_ref_ptr, valid);
                        assert valid /= 0
                        report lf & "call label variable on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name & "line number " & (integer'image(file_line))
                        severity failure;       
                        text_field_ptr_to_text_field(tmp_label_proc_ref_ptr, tmp_label_proc_ref);
                        access_var(var_list, no_scope, tmp_label_proc_ref, var_index, tmp_var_value, valid);
                        assert valid /= 0
                        report lf & "call label called proc on stimulus line " & (integer'image(file_line)) & " is not valid!!" & lf & "in file " & file_name & "line number " & (integer'image(file_line))
                        severity failure;     
                        runtime_context.inst_element_number_of_called_proc := to_integer(tmp_var_value(30 downto 0)) - 1;               
                        runtime_context.in_call_of_proc_name := tmp_label_proc_ref;                                   
                    end if;
                    if inst(1 to il) = INSTR_CALL then 
                        runtime_context.call_process_state := IN_PROC_CONVENTIONAL_BODY;                                          
                    elsif inst(1 to il) = INSTR_CALL_PAR_NOPAR then
                        runtime_context.call_process_state := IN_PROC_ADVANCED_BODY;                   
                    elsif inst(1 to il) = INSTR_CALL_PAR_OPEN then
                        runtime_context.call_process_state := IN_PROC_ADVANCED_PARAMS;                   
                    elsif inst(1 to il) = INSTR_CALL_LABEL_PAR_NOPAR then
                        runtime_context.call_process_state := IN_PROC_ADVANCED_BODY;                    
                    elsif inst(1 to il) = INSTR_CALL_LABEL_PAR_OPEN then  
                        runtime_context.call_process_state := IN_PROC_ADVANCED_PARAMS;                   
                    end if;
                    if trc_on(5) = '1' then
                        print("Setting actual runtime_context "  & integer'image(rc.ien));
                        print_runtime_context(runtime_context);       
                    end if;    
                                  
                -- ) 
                elsif inst(1 to il) = INSTR_PAR_CLOSE then
                    if runtime_context.call_process_state = IN_PROC_ADVANCED_PARAMS then
                        runtime_context.call_process_state := IN_CALL_ADVANCED_PARAMS; 
                        runtime_context.inst_element_number_of_called_proc_params_end := ien;
                        ien := runtime_context.inst_element_number_of_call_params;
                    elsif runtime_context.call_process_state = IN_CALL_ADVANCED_PARAMS then
                        runtime_context.call_process_state := IN_PROC_ADVANCED_BODY; 
                        ien := runtime_context.inst_element_number_of_called_proc_params_end;                                 
                    end if;
                    
                -- log message INFO "some message"
                -- log message  INFO "misc_proc severity: {}" INFO
                elsif inst(1 to il) = INSTR_LOG_MESSAGE then
                    if par_values(1) <= loglevel then
                        txt_print_wvar(var_list, scope, txt, txt_enclosing_quote, sp, stack_called_file_names, stack_called_file_lines, stack_called_procs, machine_value_width);
                    end if;

                -- log lines INFO a_lines
                elsif inst(1 to il) = INSTR_LOG_LINES then
                    index_var(var_list, par_indexes(2), var_scope, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object not found"
                    severity failure;
                    if par_values(1) <= loglevel then
                        stm_lines_print(var_stm_lines, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " lines object access"
                        severity failure;
                    end if;

                -- trace 1
                elsif inst(1 to il) = INSTR_TRACE then
                    trc_on := par_values(1);

                -- verbosity INFO
                -- verbosity 25
                elsif inst(1 to il) = INSTR_VERBOSITY then
                    loglevel := par_values(1);

                -- resume ON_VERIFY (Flag Bit0) or BUS_TIMEOUT (Flag Bit1) failure
                -- if respective flag in resume value is set
                elsif inst(1 to il) = INSTR_RESUME then
                    resume := par_values(1);

                -- seed seed_var
                -- seed 1397
                elsif inst(1 to il) = INSTR_SEED then
                    assert par_values(1) > 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": seed expects a positive values"
                    severity failure;
                    seed1 := to_integer(par_values(1)(30 downto 0));
                    if seed1 > 1 then
                        seed2 := seed1 - 1;
                    else
                        seed2 := seed1 + 42;
                    end if;

                -- random rand_var rand_min_var rand_max_var
                -- random rand_var 0 rand_max_var
                -- random rand_var rand_min_var 9
                -- random rand_var 3 9
                elsif inst(1 to il) = INSTR_RANDOM then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    random(seed1, seed2, par_values(2), par_values(3), stm_value);
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " random cannot update variable, it may be a constant ?"
                    severity failure;

                -- wait time_to_wait
                -- wait 10000
                elsif inst(1 to il) = INSTR_WAIT then
                    wait for to_integer(par_values(1)(30 downto 0)) * 1 ns;

                -- marker 5 1 sets marker number 5 to high
                -- marker 7 0 sets marker number 7 to low
                elsif inst(1 to il) = INSTR_MARKER then
                    if par_values(1) < 16 then
                        for i in 0 to 15 loop
                            if par_values(1) = i then
                                if par_values(2) = 0 then
                                    temp_marker(i) := '0';
                                else
                                    temp_marker(i) := '1';
                                end if;
                            end if;
                        end loop;
                    else
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": 16 markers are provided only"
                        severity failure;
                    end if;
                    marker <= temp_marker;
                    wait for 0 ns;

                -- var verify a_var var_expected_value var_mask_value
                -- var verify a_var 0x0002 0x00FF
                elsif inst(1 to il) = INSTR_VAR_VERIFY then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    verify_passes_count := verify_passes_count + 1;
                    if (par_values(3) and stm_value) /= (par_values(3) and par_values(2)) then
                        print("read     = 0x" & to_hstring(stm_value));
                        print("expected = 0x" & to_hstring(par_values(2)));
                        print("mask     = 0x" & to_hstring(par_values(3)));
                        if resume(0) = '0' then
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                            severity failure;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                            severity error;
                            verify_failure_count := verify_failure_count + 1;
                        end if;
                    end if;

                -- signal write a_signal signal_to_be_set_value
                -- signal write a_signal 0x1234
                elsif inst(1 to il) = INSTR_SIGNAL_WRITE then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    temp_int := to_integer(stm_value(30 downto 0));
                    signal_write(signals_out, temp_int, par_values(2), valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": signal not defined"
                    severity failure;
                    wait for 0 ns;

                -- signal read a_signal signal_read_value
                -- signal verify a_signal signal_read_value signal_expected_value signal_mask_value
                -- signal verify a_signal signal_read_value 0x0002 0x00FF
                -- signal_read or signal_verify
                elsif inst(1 to il) = INSTR_SIGNAL_VERIFY or inst(1 to il) = INSTR_SIGNAL_READ then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    temp_int := to_integer(stm_value(30 downto 0));
                    signal_read(signals_in, temp_int, stm_value_b, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": signal not defined"
                    severity failure;
                    update_var(var_list, par_indexes(2), stm_value_b, valid);
                    assert valid /= 0
                    report "get_sig not a valid variable??"
                    severity failure;
                    if (inst(1 to il) = INSTR_SIGNAL_VERIFY) then
                        verify_passes_count := verify_passes_count + 1;
                        if (par_values(4) and stm_value_b) /= (par_values(4) and par_values(3)) then
                            print("signal   = 0x" & to_hstring(stm_value));
                            print("read     = 0x" & to_hstring(stm_value_b));
                            print("expected = 0x" & to_hstring(par_values(3)));
                            print("mask     = 0x" & to_hstring(par_values(4)));
                            if resume(0) = '0' then
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                                severity failure;
                            else
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                                severity error;
                                verify_failure_count := verify_failure_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                --  signal pointer copy a_signal_target a_signal_source
                --  signal pointer copy a_signal_target a_signal_source )
                elsif inst(1 to il) = INSTR_SIGNAL_POINTER_COPY or inst(1 to il) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " signal object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report "signal_pointer not a signal object name??"
                    severity failure;
                    if inst(1 to il) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                --  signal pointer set a_signal_target a_var
                --  signal pointer set a_signal_target 0x01
                elsif inst(1 to il) = INSTR_SIGNAL_POINTER_SET then
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report "signal_pointer not a signal object name??"
                    severity failure;

                --  signal pointer get a_signal_source a_var
                elsif inst(1 to il) = INSTR_SIGNAL_POINTER_GET then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " variable object not found"
                    severity failure;
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report "signal_pointer not a signal object name??"
                    severity failure;

                -- bus write a_bus bus_width  bus_address bus_to_be_set_value
                -- bus write a_bus 16 0x00001000 0x1233
                elsif (inst(1 to il) = INSTR_BUS_WRITE) then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    temp_int_b := to_integer(stm_value(30 downto 0));
                    bus_write(bus_down, bus_up, par_values(3), par_values(4), temp_int, temp_int_b, valid, successfull, bus_timeouts(to_integer(stm_value(30 downto 0))));
                    assert valid /= 0
                    report "Bus number not available"
                    severity failure;
                    bus_timeout_passes_count := bus_timeout_passes_count + 1;
                    if resume(1) = '0' then
                        assert successfull
                        report "Bus Write timeout"
                        severity failure;
                    else
                        if not successfull then
                            bus_timeout_failure_count := bus_timeout_failure_count + 1;
                        end if;
                        assert successfull
                        report "Bus Write timeout"
                        severity error;
                    end if;
                    wait for 0 ns;

                -- bus read  a_bus bus_width  bus_address  bus_read_value
                -- bus read  a_bus 16 0x00001000  bus_read_value
                -- bus verify a_bus bus_width  bus_address bus_read_value bus_expected_value bus_mask_value
                -- bus verify a_bus 32  0x00001004 bus_read_value 0x00050000 0x000FC000
                elsif inst(1 to il) = INSTR_BUS_READ or inst(1 to il) = INSTR_BUS_VERIFY then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    stm_value_b := (others => '0');
                    temp_int := to_integer(par_values(2)(30 downto 0));
                    temp_int_b := to_integer(stm_value(30 downto 0));
                    bus_read(bus_down, bus_up, par_values(3), stm_value_b, temp_int, temp_int_b, valid, successfull, bus_timeouts(to_integer(stm_value(30 downto 0))));
                    assert valid /= 0
                    report "Bus number not available"
                    severity failure;
                    bus_timeout_passes_count := bus_timeout_passes_count + 1;
                    if resume(1) = '0' then
                        assert successfull
                        report "Bus Read timeout"
                        severity failure;
                    else
                        if not successfull then
                            bus_timeout_failure_count := bus_timeout_failure_count + 1;
                        end if;
                        assert successfull
                        report "Bus Read timeout"
                        severity error;
                    end if;
                    update_var(var_list, par_indexes(4), stm_value_b, valid);
                    if valid = 0 then
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                        severity failure;
                    end if;
                    if inst(1 to il) = INSTR_BUS_VERIFY then
                        verify_passes_count := verify_passes_count + 1;
                        if (par_values(6) and stm_value_b) /= (par_values(6) and par_values(5)) then
                            print("bus      = 0x" & to_hstring(stm_value));
                            print("address  = 0x" & to_hstring(par_values(3)));
                            print("read     = 0x" & to_hstring(stm_value_b));
                            print("expected = 0x" & to_hstring(par_values(5)));
                            print("mask     = 0x" & to_hstring(par_values(6)));
                            if resume(0) = '0' then
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                                severity failure;
                            else
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ", file " & text_line_crop(file_name)
                                severity error;
                                verify_failure_count := verify_failure_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                -- bus timeout a_bus 1000
                -- bus timeout a_bus bus_timeout_value
                elsif inst(1 to il) = INSTR_BUS_TIMEOUT_SET then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & ": not a valid variable??"
                    severity failure;
                    bus_timeouts(to_integer(stm_value(30 downto 0))) := to_integer(par_values(2)(30 downto 0)) * 1 ns;

                elsif inst(1 to il) = INSTR_BUS_TIMEOUT_GET then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " bus object not found"
                    severity failure;
                    stm_value_b := to_unsigned(bus_timeouts(to_integer(stm_value(30 downto 0))) / 1 ns, machine_value_width);
                    update_var(var_list, par_indexes(2), stm_value_b, valid);
                    assert valid /= 0
                    report "variable not a var object name??"
                    severity failure;

                --  bus pointer copy a_file_target a_file_source
                --  bus pointer copy a_file_target a_file_source (
                elsif inst(1 to il) = INSTR_BUS_POINTER_COPY or inst(1 to il) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
                    index_var(var_list, par_indexes(2), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " bus object not found"
                    severity failure;
                    update_var(var_list, par_indexes(1), stm_value, valid);
                    assert valid /= 0
                    report "bus_pointer not a bus object name??"
                    severity failure;
                    if inst(1 to il) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
                        ien := access_next_instruction_line_to_execute;
                    end if;

                --  bus pointer set a_bus_target a_var
                --  bus pointer set a_bus_target 0x01
                elsif inst(1 to il) = INSTR_BUS_POINTER_SET then
                    update_var(var_list, par_indexes(1), par_values(2), valid);
                    assert valid /= 0
                    report "bus_pointer not a bus object name??"
                    severity failure;

                --  bus pointer get a_bus_source a_var
                elsif inst(1 to il) = INSTR_BUS_POINTER_GET then
                    index_var(var_list, par_indexes(1), var_scope, stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & inst(1 to il) & " bus object not found"
                    severity failure;
                    update_var(var_list, par_indexes(2), stm_value, valid);
                    assert valid /= 0
                    report "variable not a var object name??"
                    severity failure;

                -- undefined instructions
                else
                    assert false
                    report " line " & (integer'image(file_line)) & "  seems the command  " & ", " & inst(1 to il) & " was defined but" & lf & "was not found in the elsif chain, please check spelling."
                    severity failure;
                end if;

            end if;

        end loop;

        assert false
        report lf & "the end of the simulation! it was not terminated as expected." & lf
        severity failure;

    end process;
end;
