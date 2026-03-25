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

use work.tb_limits_pkg.all;
use work.tb_base_pkg.all;
use work.tb_instructions_pkg.all;
use work.tb_interpreter_util_pkg.all;
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
    --! lists of valid_bus instructions, valid_bus list of variables and finally a list
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
        variable il : integer;
        variable slc : src_locator;
        
        variable noc : integer;
        
        variable stimulus_file_var : string (1 to stimulus_file'length) := stimulus_file;

        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable file_line : integer; -- line number in the stimulus file
        variable file_name : text_line; -- the file name the line came from
        variable ien : integer := 0; -- sequence number
        variable bien : integer := 0; -- branch sequence number
        variable ie : inst_element_ptr;
        variable bie : inst_element_ptr;

        variable sp : integer := 0; -- call stack pointer
        variable rcs : stm_array_of_runtime_context; -- call stack

        variable act_loop_num : integer := 0;
        variable act_curr_loop_count : integer := 0;
        variable act_term_loop_count : integer := 0;
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
        variable valid_bus : integer;
        variable interrupt_number_entered_stack_pointer : integer := -1;
        variable interrupt_number_entered_stack : interrupt_array := (others => 0);
        variable interrupt_entry_call_stack_ptr_stack : interrupt_array := (others => 0);
        variable v_set_interrupt_in_service : std_logic := '0';

        variable successfull : boolean := false;

        -- random generator seed variables
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;
       
        variable par_scopes : parameter_text_field_array;
        variable var_scope : text_field;
        variable var_index : integer;
        variable number_found : integer;
        variable stm_values_ptr : stm_values_ptr;

        variable temp_marker : std_logic_vector(15 downto 0) := (others => '0');

        variable trc_on : unsigned(machine_value_width - 1 downto 0) := to_unsigned(0, machine_value_width);

        variable v_stat : file_open_status;

        -- Bus
        type bus_timeout_array is array (0 to 127) of time;
        variable bus_timeouts : bus_timeout_array := (others => 1 sec);

        -- Array
        variable var_stm_array : stm_array_ptr;

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
        variable var_stm_lines : stm_lines_ptr;

        variable main_proc_name : text_field;
        variable main_inst_element : integer := 0;
        variable main_entered : integer := 0;

        variable interrupt_requests : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');
        variable interrupt_in_service : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');

        variable interrupt_number : integer := 0;
        variable branch_to_interrupt : boolean := false;
        variable branch_to_interrupt_proc_name : text_field;
        variable branch_to_interrupt_proc_name_std_txt_io_line : line;
        variable branch_to_interrupt_instruction_element_number : integer := 0;

        variable no_scope : text_field;
        variable no_proc : text_field;
        variable no_file : text_field;
        variable no_file_on_main_entry : text_field;
        variable no_file_on_interrupt : text_field;
        variable empty_text_field : text_field;
        variable debug : boolean;
        
        variable ven1 : integer;
        variable ven2 : integer;
        variable ven3 : integer;
        variable ven4 : integer;
        variable val : unsigned(machine_value_width - 1 downto 0);
        variable val1 : unsigned(machine_value_width - 1 downto 0);
        variable val2 : unsigned(machine_value_width - 1 downto 0);
        variable val3 : unsigned(machine_value_width - 1 downto 0);
        variable val4 : unsigned(machine_value_width - 1 downto 0);
        variable val5 : unsigned(machine_value_width - 1 downto 0);
        variable val6 : unsigned(machine_value_width - 1 downto 0);
        variable val_int : integer;
        variable val1_int : integer;
        variable val2_int : integer;                
        variable signal_valid : integer;
        variable bus_valid : integer;
        variable pen : integer; 
                
        procedure get_ven_in_called_scope_prefer_local(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);     
        end procedure;
        
        procedure get_ven_in_caller_scope_prefer_local(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp - 1).ien_of_called_proc).name, ven);        
        end procedure;
        
        procedure get_ven_in_called_scope_local(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            access_inst_par_index_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);        
        end procedure;
        
        procedure get_ven_in_caller_scope_local(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            access_inst_par_index_local(ie, vars, pn, procs.element_ptrs(rcs(sp - 1).ien_of_called_proc).name, ven);        
        end procedure;
     
        procedure get_ven_in_called_scope_call_params_target_sensitive(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            if rcs(sp).call_process_state = IN_CALL_PARAMS then
                access_inst_par_index_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);
                return;
            end if;
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);           
        end procedure;
        
        procedure get_ven_in_called_scope_call_params_source_sensitive(constant par_num : in integer; variable ven : out integer) is
            variable pn : integer := par_num;
        begin
            if rcs(sp).call_process_state = IN_CALL_PARAMS then
                access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp - 1).ien_of_called_proc).name, ven);
                return;
            end if;
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);         
        end procedure;  
            
         
        procedure get_val_in_called_scope_prefer_local(constant par_num : in integer; variable val : out unsigned(machine_value_width - 1 downto 0)) is
            variable pn : integer := par_num;
            variable ven : integer;
        begin
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);   
            val := vars.element_ptrs(ven).values(0);
        end procedure;
        
        procedure get_val_in_caller_scope_prefer_local(constant par_num : in integer; variable val : out unsigned(machine_value_width - 1 downto 0)) is
            variable pn : integer := par_num;
            variable ven : integer;
        begin
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp - 1).ien_of_called_proc).name, ven); 
            val := vars.element_ptrs(ven).values(0);
        end procedure; 
        
        procedure get_val_in_called_scope_call_params_source_sensitive(constant par_num : in integer; variable val : out unsigned(machine_value_width - 1 downto 0) ) is
            variable pn : integer := par_num;
            variable ven : integer;
        begin
            if rcs(sp).call_process_state = IN_CALL_PARAMS then
                access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp - 1).ien_of_called_proc).name, ven);
                val := vars.element_ptrs(ven).values(0);
                return;
            end if;
            access_inst_par_index_prefer_local(ie, vars, pn, procs.element_ptrs(rcs(sp).ien_of_called_proc).name, ven);
            val := vars.element_ptrs(ven).values(0);        
        end procedure;      
 
        procedure print_instr( constant pre : in string; constant post: in string) is
        begin
            print(pre & crop(ie.inst) & " #" & integer'image(ien) & " sp " & integer'image(sp) & " file name: " & crop(ie.slc.file_name) & " file line: " & integer'image(ie.slc.file_line) & post);         
        end procedure; 
        
        procedure print_instr( constant pre : in string) is
        begin
            print_instr(pre, "");        
        end procedure;         
             
    begin
        debug:= true;
        marker <= (others => '0');
        verify_passes <= (others => '0');
        verify_failures <= (others => '0');
        bus_timeout_passes <= (others => '0');
        bus_timeout_failures <= (others => '0');
        signals_out <= signals_out_init;
        bus_down <= bus_down_init;

        wait for 0 ns;

        init_const_text_field(stimulus_main_entry_label, main_proc_name);
        init_const_text_field("", empty_text_field);
        init_const_text_field(".", no_scope);
        init_const_text_field("no_proc", no_proc);
        init_const_text_field("no_file", no_file);
        init_const_text_field("no_file_on_main_entry", no_file);
        init_const_text_field("no_file_on_interrupt", no_file);
        
        init_inst_def_list(inst_defs); 
        define_insts(inst_defs);
        
        init_file_def_list(code_files);
        print("collect stimulus code files");
        slc.file_name := string_to_text_field(stimulus_file);
        slc.file_line := -1;
        collect_code_files(slc, code_files, stimulus_path, stimulus_file_var);
        print(integer'image(code_files.last_element_num) & " stimulus code files");   
        
        init_var_pool_ordered(vars);
        print("parsing stimulus code files");
        parse_constants(code_files, inst_defs, vars, procs, machine_value_width, debug); 
        noc := vars.last_element_num;
        print(integer'image(noc) & " constants");  
        dump_var_pool_ordered( vars, machine_value_width);
        
        parse_variables(code_files, inst_defs, vars, procs, machine_value_width, debug); 
        print(integer'image(vars.last_element_num - noc) & " variables");                 
        init_proc_pool_ordered(procs);
        init_inst_sequence(insts);
        parse_instructions_and_procs(code_files, inst_defs, insts, vars, procs, machine_value_width, debug); 
        print(integer'image(procs.last_element_num) & " procedures"); 
        print(integer'image(insts.last_element_num) & " instructions"); 

        print("checking if all variables are initially defined for all instructions");
        check_instructions_in_initial_context(insts, vars, procs, machine_value_width);
     
        print("starting stimuli execution");

        sp := 0;
        init_runtime_context(rcs(sp));
        ien := 0;
        
        while ien <= insts.last_element_num loop

            verify_passes <= std_logic_vector(to_unsigned(verify_passes_count, 32));
            verify_failures <= std_logic_vector(to_unsigned(verify_failure_count, 32));
            bus_timeout_passes <= std_logic_vector(to_unsigned(bus_timeout_passes_count, 32));
            bus_timeout_failures <= std_logic_vector(to_unsigned(bus_timeout_failure_count, 32));

            get_interrupt_requests(signals_in, interrupt_requests);
            if interrupt_requests > 0 then
                resolve_interrupt_requests(interrupt_requests, interrupt_in_service, interrupt_number, branch_to_interrupt, branch_to_interrupt_proc_name_std_txt_io_line);
            end if;

            if main_entered = 0 then
                sp := sp + 1;
                init_runtime_context(rcs(sp));
                -- main tests shall not reach their end proc but must be terminated by a reasonable finish instruction inside itself 
                slc.file_name := no_file_on_main_entry; 
                slc.file_line := -1;              
                access_proc(slc, procs, main_proc_name, ien); 
                ie := insts.element_ptrs(ien);
                print_instr("exec main entry ");
                main_entered := 1;              
                rcs(sp).ien_of_called_proc := ien;                     

            elsif branch_to_interrupt then
                assert sp < max_num_of_stack_elements
                report "branch to interrupt, stack over run"
                severity failure;
                sp := sp + 1;
                init_runtime_context(rcs(sp));
                interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer + 1;
                interrupt_number_entered_stack(interrupt_number_entered_stack_pointer) := interrupt_number;
                interrupt_entry_call_stack_ptr_stack(interrupt_number_entered_stack_pointer) := sp;
                v_set_interrupt_in_service := '1';
                set_interrupt_in_service(interrupt_in_service, interrupt_number, v_set_interrupt_in_service, signals_out);               
                line_to_text_field(branch_to_interrupt_proc_name_std_txt_io_line, branch_to_interrupt_proc_name);
                slc.file_name := no_file_on_interrupt; 
                slc.file_line := -1; 
                access_proc(slc, procs, branch_to_interrupt_proc_name, ien);                
                ie := insts.element_ptrs(ien);
                if trc_on(TRACE_INTERRUPTS)then
                    print_instr("exec interrupt entry ");                    
                end if;   
                rcs(sp).ien_of_called_proc := ien;                                        
                wait for 0 ns;

            else
                ien := ien + 1;
                ie := insts.element_ptrs(ien);
                if trc_on(TRACE_FILES) then
                    dump_file_defs(code_files);
                end if;
                if trc_on(TRACE_VARIABLES) then
                    dump_var_pool_ordered(vars, machine_value_width);
                end if;
                if trc_on(TRACE_INSTRUCTIONS) then
                    print_inst_element(insts, ien, code_files);
                end if;

                executing_line <= file_line;
                executing_file <= file_name;
                wait for 100 ps;

                if trc_on(TRACE_EXECUTED_LINES) then
                    print_instr("exec ");
                end if;

                -- namespace "a_namespace"
                if crop(ie.inst) = INSTR_NAMESPACE then
                    null; -- processed during inital parse

                -- end namespace
                elsif crop(ie.inst) = INSTR_END_NAMESPACE then
                    null; -- processed during inital parse

                -- include "an_include.stm"
                elsif crop(ie.inst) = INSTR_INCLUDE then
                    null; -- processed during inital code file collection
                --
                -- const a_const_num 0x03
                -- const a_constB a_constA
                -- const a_constC a_varA
                elsif crop(ie.inst) = INSTR_CONST then
                    null; -- processed during inital parse

                -- var a_varA 0x05
                -- var a_varB a_varA
                -- var a_varC a_constA
                elsif crop(ie.inst) = INSTR_VAR then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1);                    
                    index_and_reinit_var(vars, ven1, val1);
                    
                -- array an_array 16
                elsif crop(ie.inst) = INSTR_ARRAY then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1);                    
                    index_and_reinit_var(vars, ven1, var_stm_array);
                    for i in 0 to var_stm_array'length - 1 loop
                        var_stm_array(i) := to_unsigned(0, machine_value_width);
                    end loop;

                -- label a_label a_proc_label
                elsif crop(ie.inst) = INSTR_LABEL then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1); 
                    index_and_reinit_var(vars, ven1, var_stm_label);

                -- file a_fileA "file_name"
                -- file a_fileB "file_name{}{}" file_user_index1 file_user_index2
                elsif crop(ie.inst) = INSTR_FILE then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1);    
                    index_and_reinit_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
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
                        assert false
                        report "trying to end file not started or already ended for read:" & 
                               " file name: " & crop(ie.slc.file_name) & 
                               " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end if;

                -- signal a_signal
                elsif crop(ie.inst) = INSTR_SIGNAL then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1); 
                    index_and_reinit_var(vars, ven1, val1);

                -- bus a_bus
                elsif crop(ie.inst) = INSTR_BUS then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1); 
                    index_and_reinit_var(vars, ven1, val1);

                -- lines a_lines
                elsif crop(ie.inst) = INSTR_LINES then
                    -- processed during inital parse for global vars, executed as instruction only for local vars
                    get_ven_in_called_scope_local(1, ven1); 
                    index_and_reinit_var(vars, ven1, var_stm_lines);
                    while var_stm_lines.size > 0 loop
                        val_int := 0;
                        stm_lines_delete(slc, var_stm_lines, val_int);
                        assert false
                        report "lines delete all not successful:" & 
                               " file name: " & crop(ie.slc.file_name) & 
                               " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end loop;

                -- equ operand1_equ_target operand2
                -- equ operand1_equ_target 0xF0
                elsif crop(ie.inst) = INSTR_EQU or crop(ie.inst) =  INSTR_EQU_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_val_in_called_scope_call_params_source_sensitive(2, val2);
                    update_var(vars, ven1, val2);
                    if crop(ie.inst) = INSTR_EQU_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- var pointer copy d_var s_var
                -- var pointer copy d_var s_var )
                elsif crop(ie.inst) = INSTR_VAR_POINTER_COPY or crop(ie.inst) = INSTR_VAR_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_ven_in_called_scope_call_params_source_sensitive(2, ven2);
                    index_var_values_ptr(vars, ven2, stm_values_ptr);
                    update_var_values_ptr(vars, ven1, stm_values_ptr);
                    if crop(ie.inst) = INSTR_VAR_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- add operand1_and_target operand2
                -- add operand1_and_target 0xF01
                elsif crop(ie.inst) = INSTR_ADD then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 + val2;
                    update_var(vars, ven1, val);

                -- sub operand1_and_target operand2
                -- sub operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_SUB then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 - val2;
                    update_var(vars, ven1, val);

                -- mul operand1_and_target operand2
                -- mul operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_MUL then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 + val2;
                    val := resize(resize(val1, machine_value_width * 2) * resize(val2, machine_value_width * 2), machine_value_width);
                    update_var(vars, ven1, val);                

                -- div operand1_and_target operand2
                -- div operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_DIV then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 / val2;
                    update_var(vars, ven1, val);

                -- rem operand1_and_target operand2
                -- rem operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_REM then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 rem val2;
                    update_var(vars, ven1, val);

                -- and operand1_and_target operand2
                -- and operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_AND then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 and val2;
                    update_var(vars, ven1, val);

                -- or operand1_and_target operand2
                -- or operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_OR then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 or val2;
                    update_var(vars, ven1, val);

                -- xor operand1_and_target operand2
                -- xor operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_XOR then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := val1 xor val2;
                    update_var(vars, ven1, val);

                -- shl operand1_and_target operand2
                -- shl operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_SHL then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := shift_left(val1, to_integer(val2(30 downto 0)));
                    update_var(vars, ven1, val);                

                -- shr operand1_and_target operand2
                -- shr operand1_and_target 0xF0
                elsif crop(ie.inst) = INSTR_SHR then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val := shift_right(val1, to_integer(val2(30 downto 0)));
                    update_var(vars, ven1, val); 

                -- inv operand1_and_target
                elsif crop(ie.inst) = INSTR_INV then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    val := not val1;
                    update_var(vars, ven1, val);

                -- ld operand1_and_target
                elsif crop(ie.inst) = INSTR_LD then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(1, val1);
                    val := ld(val1);
                    update_var(vars, ven1, val);

                -- array set an_array array_position 0x07
                -- array set an_array array_position a_varA
                -- array set an_array 5 0x07
                -- array set an_array 3 a_varA
                elsif crop(ie.inst) = INSTR_ARRAY_SET then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    index_var(vars, ven1, var_stm_array);
                    get_val_in_called_scope_prefer_local(2, val2);
                    assert var_stm_array'length > val2
                    report "array set position is out of array size:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                    get_val_in_called_scope_prefer_local(3, val3);
                    var_stm_array(to_integer(val2(30 downto 0))) := val3;

                -- array get an_array array_position a_varB
                elsif crop(ie.inst) = INSTR_ARRAY_GET then
                    get_ven_in_called_scope_prefer_local(1, ven1);     
                    index_var(vars, ven1, var_stm_array);
                    get_val_in_called_scope_prefer_local(2, val2);                    
                    assert var_stm_array'length > val2
                    report "array get position is out of array size:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                    val := var_stm_array(to_integer(val2(30 downto 0)));
                    get_ven_in_called_scope_prefer_local(3, ven3);
                    update_var(vars, ven3, val);

                --  array size an_array array_size
                elsif crop(ie.inst) = INSTR_ARRAY_SIZE then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    index_var(vars, ven1, var_stm_array);
                    val := to_unsigned(var_stm_array'length, machine_value_width);
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    update_var(vars, ven2, val);

                -- array pointer an_array another_array
                -- array pointer an_array another_array )
                elsif crop(ie.inst) = INSTR_ARRAY_POINTER_COPY or crop(ie.inst) =  INSTR_ARRAY_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_ven_in_called_scope_call_params_source_sensitive(2, ven2);
                    index_var(vars, ven2, var_stm_array);
                    update_var(vars, ven1, var_stm_array);
                    if crop(ie.inst) = INSTR_ARRAY_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- array verify a_var array_position var_expected_value var_mask_value
                -- array verify a_var array_position 0x0002 0x00FF
                -- array verify a_var 5 var_expected_value var_mask_value
                -- array verify a_var 5 0x0002 0x00FF
                elsif crop(ie.inst) = INSTR_ARRAY_VERIFY then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    index_var(vars, ven1, var_stm_array);
                    get_val_in_called_scope_prefer_local(2, val2);    
                    assert var_stm_array'length > val2
                    report "array verify position is out of array size:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                    verify_passes_count := verify_passes_count + 1;
                    val := var_stm_array(to_integer(val2(30 downto 0)));    
                    get_val_in_called_scope_call_params_source_sensitive(3, val3);                  
                    get_val_in_called_scope_call_params_source_sensitive(4, val4);                
                    if (val4 and val) /= (val4 and val3) then
                        print_instr("exec ");
                        print(" index    = 0x" & to_hstring(val2));
                        print(" read     = 0x" & to_hstring(val));
                        print(" expected = 0x" & to_hstring(val3));
                        print(" mask     = 0x" & to_hstring(val4));
                        assert resume(0) /= '0'
                        report "array verify has difference:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                        assert false
                        report "array verify has difference:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity error;
                        verify_failure_count := verify_failure_count + 1;
                    end if;

                -- label pointer copy a_label another_label
                -- label pointer copy a_label another_label )
                elsif crop(ie.inst) = INSTR_LABEL_POINTER_COPY or crop(ie.inst) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_ven_in_called_scope_call_params_source_sensitive(2, ven2);
                    index_var(vars, ven2, var_stm_label);
                    update_var(vars, ven1, var_stm_label);
                    if crop(ie.inst) = INSTR_LABEL_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- label equ label1_target label2
                -- label equ label1_target label2 )
                elsif crop(ie.inst) = INSTR_LABEL_EQU or crop(ie.inst) =  INSTR_LABEL_EQU_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_val_in_called_scope_call_params_source_sensitive(2, val2); 
                    update_var(vars, ven1, val2); 
                    if crop(ie.inst) = INSTR_LABEL_EQU_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;
                    
                -- label set label1_target label2
                -- label set label1_target label2 )
                elsif crop(ie.inst) = INSTR_LABEL_SET or crop(ie.inst) =  INSTR_LABEL_SET_PAR_CLOSE then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(2, val2);                     
                    update_var(vars, ven1, val2); 
                    if crop(ie.inst) = INSTR_LABEL_SET_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- file readable a_fileA target
                elsif crop(ie.inst) = INSTR_FILE_READABLE then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(2, val2);                      
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_readable(var_stm_text_substituded_ptr, val_int);
                    val := to_unsigned(val_int, machine_value_width);
                    update_var(vars, ven2, val);

                -- file writeable a_fileA target
                elsif crop(ie.inst) = INSTR_FILE_WRITABLE then
                    get_ven_in_called_scope_prefer_local(1, ven1);                   
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_writeable(var_stm_text_substituded_ptr, val_int);
                    val := to_unsigned(val_int, machine_value_width);
                    update_var(vars, ven2, val);

                -- file appendable a_fileA target
                elsif crop(ie.inst) = INSTR_FILE_APPENDABLE then
                    get_ven_in_called_scope_prefer_local(1, ven1);                   
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_appendable(var_stm_text_substituded_ptr, val_int);
                    val := to_unsigned(val_int, machine_value_width);
                    update_var(vars, ven2, val);

                -- file write a_fileA a_lines
                elsif crop(ie.inst) = INSTR_FILE_WRITE then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    get_ven_in_called_scope_prefer_local(2, ven2);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    index_var(vars, ven2, var_stm_lines);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_write(slc, var_stm_lines, var_stm_text_substituded_ptr);

                -- file append a_fileB  a_lines
                elsif crop(ie.inst) = INSTR_FILE_APPEND then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    get_ven_in_called_scope_prefer_local(2, ven2);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    index_var(vars, ven2, var_stm_lines);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_append(slc, var_stm_lines, var_stm_text_substituded_ptr);

                -- file read a_fileA a_lines number_of_lines
                -- file read a_fileA a_lines 256
                elsif crop(ie.inst) = INSTR_FILE_READ then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    get_val_in_called_scope_prefer_local(3, val3);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    index_var(vars, ven2, var_stm_lines);
                    user_file_append_done := false;
                    -- if file is already in use, us it
                    if user_file_in_use_0 then
                        if var_stm_text = user_file_name_0 then
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_1 then
                        if var_stm_text = user_file_name_1 then
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_2 then
                        if var_stm_text = user_file_name_2 then
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_3 then
                        if var_stm_text = user_file_name_3 then
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    -- if file is not in use, try to open and use it
                    if not user_file_append_done then
                        stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                        var_stm_text_substituded_ptr := new stm_text;
                        stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                        txt_to_string(var_stm_text_substituded_ptr, user_file_path_string);
                        user_file_open_done := false;
                        if not user_file_in_use_0 and not user_file_open_done then
                            stm_user_file_open(slc, user_file_0, user_file_path_string, read_mode); 
                            user_file_name_0 := var_stm_text;
                            user_file_in_use_0 := true;
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                        elsif not user_file_in_use_1 and not user_file_open_done then
                            stm_user_file_open(slc, user_file_1, user_file_path_string, read_mode); 
                            user_file_name_1 := var_stm_text;
                            user_file_in_use_1 := true;
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                        elsif not user_file_in_use_2 and not user_file_open_done then
                            stm_user_file_open(slc, user_file_2, user_file_path_string, read_mode); 
                            user_file_name_2 := var_stm_text;
                            user_file_in_use_2 := true;
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                        elsif not user_file_in_use_3 and not user_file_open_done then
                            stm_user_file_open(slc, user_file_3, user_file_path_string, read_mode); 
                            user_file_name_3 := var_stm_text;
                            user_file_in_use_3 := true;
                            for i in 1 to to_integer(val3(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(slc, var_stm_lines, tmp_std_line);
                            end loop;
                        else
                            assert false
                            report "only 4 files are allowed for file read concurrently:" & 
                               " file name: " & crop(ie.slc.file_name) & 
                               " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                        end if;
                    end if;

                -- file read end a_fileA a_lines
                elsif crop(ie.inst) = INSTR_FILE_READ_END then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
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
                        assert false
                        report "trying to end file not started or already ended for read:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end if;

                -- file read all a_fileA a_lines
                elsif crop(ie.inst) = INSTR_FILE_READ_ALL then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    get_ven_in_called_scope_prefer_local(2, ven2);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    index_var(vars, ven2, var_stm_lines);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);
                    stm_file_read_all(slc, var_stm_lines, var_stm_text_substituded_ptr);

                --  file pointer copy a_file_target a_file_source
                --  file pointer copy a_file_target a_file_source )
                elsif crop(ie.inst) = INSTR_FILE_POINTER_COPY or crop(ie.inst) = INSTR_FILE_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);  
                    get_ven_in_called_scope_call_params_source_sensitive(2, ven2);  
                    index_var(vars, ven2, var_stm_text, var_stm_text_enclosing_quote);
                    update_var(vars, ven1, var_stm_text);
                    if crop(ie.inst) = INSTR_FILE_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- lines get a_lines position an_array number_found
                -- lines get a_lines 8 an_array number_found
                elsif crop(ie.inst) = INSTR_LINES_GET_ARRAY then
                    get_ven_in_called_scope_prefer_local(1, ven1);  
                    get_val_in_called_scope_prefer_local(2, val2);  
                    get_ven_in_called_scope_prefer_local(3, ven3);  
                    get_ven_in_called_scope_prefer_local(4, ven4);  
                    index_var(vars, ven1, var_stm_text, var_stm_text_enclosing_quote);
                    index_var(vars, ven3, var_stm_lines);                   
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_get(slc, var_stm_lines, val_int, var_stm_array, number_found, machine_value_width);
                    update_var(vars, ven3, var_stm_array);
                    val := to_unsigned(number_found, machine_value_width);
                    update_var(vars, ven4, val);

                -- lines set a_lines position an_array
                -- lines set a_lines 9 an_array
                elsif crop(ie.inst) = INSTR_LINES_SET_ARRAY then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_ven_in_called_scope_prefer_local(3, ven3);   
                    index_var(vars, ven1, var_stm_lines);
                    index_var(vars, ven3, var_stm_array);
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_set(slc, var_stm_lines, val_int, var_stm_array, machine_value_width);

                -- lines set a_lines position "abc" txt
                -- lines set a_lines 7 "abc"
                -- lines set a_lines position "abc{}" a_varB
                -- lines set a_lines 7 "abc{}" a_varB
                elsif crop(ie.inst) = INSTR_LINES_SET_MESSAGE then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    index_var(vars, ven1, var_stm_lines);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_set(slc, var_stm_lines, val_int, var_stm_text_out);

                -- lines insert a_lines position an_array
                -- lines insert a_lines 9 an_array
                elsif crop(ie.inst) = INSTR_LINES_INSERT_ARRAY then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_ven_in_called_scope_prefer_local(3, ven3);   
                    index_var(vars, ven1, var_stm_lines);
                    index_var(vars, ven3, var_stm_array);
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_insert(slc, var_stm_lines, val_int, var_stm_array, machine_value_width);

                -- lines insert a_lines position "abc"
                -- lines insert a_lines 7 "abc"
                -- lines insert a_lines position "abc{}" a_varB
                -- lines insert a_lines 7 "abc{}" a_varB
                elsif crop(ie.inst) = INSTR_LINES_INSERT_MESSAGE then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_ven_in_called_scope_prefer_local(3, ven3);   
                    index_var(vars, ven1, var_stm_lines);
                    index_var(vars, ven3, var_stm_array);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_insert(slc, var_stm_lines, val_int, var_stm_text_out);
                    
                -- lines append a_lines an_array
                elsif crop(ie.inst) = INSTR_LINES_APPEND_ARRAY then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    index_var(vars, ven1, var_stm_lines);
                    index_var(vars, ven2, var_stm_array);
                    stm_lines_append(slc, var_stm_lines, var_stm_array, machine_value_width);

                -- lines append a_lines "abc"
                -- lines append a_lines "abc{}" a_varB
                elsif crop(ie.inst) = INSTR_LINES_APPEND_MESSAGE then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    index_var(vars, ven1, var_stm_lines);
                    stm_text_substitude_wvar(slc, insts, vars, rcs, var_stm_text, var_stm_text_enclosing_quote, sp, var_stm_text_substituded, machine_value_width);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    stm_lines_append(slc, var_stm_lines, var_stm_text_out);

                -- lines delete a_lines position
                -- lines delete a_lines 13
                elsif crop(ie.inst) = INSTR_LINES_DELETE then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    index_var(vars, ven1, var_stm_lines);
                    val_int := to_integer(val2(30 downto 0));
                    stm_lines_delete(slc, var_stm_lines, val_int);

                -- lines delete all a_lines
                elsif crop(ie.inst) = INSTR_LINES_DELETE_ALL then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    index_var(vars, ven1, var_stm_lines);
                    while var_stm_lines.size > 0 loop
                        val_int := 0;
                        stm_lines_delete(slc, var_stm_lines, val_int);
                        assert false
                        report "lines delete all not successful:" & 
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end loop;

                -- lines size a_lines read_size
                elsif crop(ie.inst) = INSTR_LINES_SIZE then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    index_var(vars, ven1, var_stm_lines);
                    val := to_unsigned(var_stm_lines.size, machine_value_width);
                    update_var(vars, ven2, val);

                --  lines pointer copy a_lines_target a_lines_source
                --  lines pointer copy a_lines_target a_lines_source 
                elsif crop(ie.inst) = INSTR_LINES_POINTER_COPY or crop(ie.inst) = INSTR_LINES_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1); 
                    get_ven_in_called_scope_call_params_source_sensitive(2, ven2);                  
                    index_var(vars, ven2, var_stm_lines);
                    update_var(vars, ven1, var_stm_lines);
                    if crop(ie.inst) = INSTR_LINES_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                -- if a_var_ref = another_var
                -- if 0x09 = another_var
                -- if a_varA = 0x09
                -- if 0x09 = 0x09
                elsif crop(ie.inst) = INSTR_IF then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_val_in_called_scope_prefer_local(3, val3); 
                    if_level := if_level + 1;
                    if_state(if_level) := false;
                    if trc_on(TRACE_IF_TREES) = '1' then
                        print_instr("exec ");                      
                        print(" incremented if_level " & integer'image(if_level));
                    end if;
                    case to_integer(val2(30 downto 0)) is
                        when 0 => if (val1 = val3) then
                                if_state(if_level) := true;
                            end if;
                        when 1 => if (val1 > val3) then
                                if_state(if_level) := true;
                            end if;
                        when 2 => if (val1 < val3) then
                                if_state(if_level) := true;
                            end if;
                        when 3 => if (val1 /= val3) then
                                if_state(if_level) := true;
                            end if;
                        when 4 => if (val1 >= val3) then
                                if_state(if_level) := true;
                            end if;
                        when 5 => if (val1 <= val3) then
                                if_state(if_level) := true;
                            end if;
                        when others =>
                            assert false
                            report "if instruction got an unknown compare operation as parameter 2" &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                    end case;
                    if trc_on(TRACE_IF_TREES) = '1' then
                        if if_state(if_level) = true then
                            print(" resolved if_state " & integer'image(if_level) & " is true");
                        else
                            print(" resolved if_state " & integer'image(if_level) & " is false");
                        end if;
                    end if;
                    if if_state(if_level) = false then
                        bien := ien + 1;
                        bie := insts.element_ptrs(bien);
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 
                              or (crop(ie.inst) /= INSTR_ELSE 
                                  and crop(ie.inst) /= INSTR_ELSIF 
                                  and crop(ie.inst) /= INSTR_END_IF) 
                        loop
                            if crop(bie.inst) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if crop(bie.inst) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert bien <= insts.last_element_num
                            report "if instruction unable to find terminating else, elsif or end_if statement." &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                            bien := bien + 1;
                        end loop;
                        if trc_on(TRACE_IF_TREES) = '1' then
                            print_instr("exec ");
                            print(crop(ie.inst) & " num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level)) & ie.slc.file_name & " file line: " & integer'image(ie.slc.file_line));
                        end if;
                        ien := bien - 1; -- re-align so it will be operated on.
                    end if;

                -- elsif a_varA > another_var
                -- 0x09 > another_var
                -- a_varA > 0x09
                -- elsif 0x0A > 0x09
                elsif crop(ie.inst) = INSTR_ELSIF then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_val_in_called_scope_prefer_local(3, val3); 
                    if trc_on(TRACE_IF_TREES) = '1' then
                        print_instr("exec ");
                        print(" if_level is " & integer'image(if_level));
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip to the end
                        bien := ien + 1;
                        bie := insts.element_ptrs(bien);
                        while crop(bie.inst) /= INSTR_IF
                              and crop(bie.inst) /= INSTR_END_IF 
                        loop
                            assert bien <= insts.last_element_num
                            report "if instruction unable to find terminating else, elsif or end_if statement." &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                            bien := bien + 1;
                        end loop;
                        ien := bien - 1; -- re-align so it will be operated on.
                    else
                        case to_integer(val2(30 downto 0)) is
                            when 0 => if val1 = val3 then
                                    if_state(if_level) := true;
                                end if;
                            when 1 => if val1 > val3 then
                                    if_state(if_level) := true;
                                end if;
                            when 2 => if val1 < val3 then
                                    if_state(if_level) := true;
                                end if;
                            when 3 => if val1 /= val3 then
                                    if_state(if_level) := true;
                                end if;
                            when 4 => if val1 >= val3 then
                                    if_state(if_level) := true;
                                end if;
                            when 5 => if val1 <= val3 then
                                    if_state(if_level) := true;
                                end if;
                            when others =>
                            assert false
                                report "elsif instruction got an unknown compare operation as parameter 2" &  
                                       " file name: " & crop(ie.slc.file_name) & 
                                       " file line: " & integer'image(ie.slc.file_line)
                                severity failure;
                        end case;
                        if trc_on(TRACE_IF_TREES) = '1' then
                            if if_state(if_level) = true then
                                print(" resolved if_state " & integer'image(if_level) & " is true");
                            else
                                print(" resolved if_state " & integer'image(if_level) & " is false");
                            end if;
                        end if;
                        if if_state(if_level) = false then
                            bien := ien + 1;
                            bie := insts.element_ptrs(bien);
                            num_of_if_in_false_if_leave(if_level) := 0;
                            while num_of_if_in_false_if_leave(if_level) /= 0 
                                  or (crop(bie.inst) /= INSTR_ELSE 
                                      and crop(bie.inst) /= INSTR_ELSIF 
                                      and crop(bie.inst) /= INSTR_END_IF) 
                            loop
                                if crop(bie.inst) = INSTR_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                                end if;
                                if crop(bie.inst) = INSTR_END_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                                end if;
                                assert bien <= insts.last_element_num
                                report "if instruction unable to find terminating else, elsif or end_if statement." &  
                                       " file name: " & crop(ie.slc.file_name) & 
                                       " file line: " & integer'image(ie.slc.file_line)
                                severity failure;
                                bien := bien + 1;
                            end loop;
                            if trc_on(TRACE_IF_TREES) = '1' then
                                print(" num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level)));
                            end if;
                            ien := bien - 1; -- re-align so it will be operated on.
                        end if;
                    end if;

                -- else
                elsif crop(ie.inst) = INSTR_ELSE then
                    if trc_on(TRACE_IF_TREES) = '1' then
                        print_instr("exec ");
                        print(" if_level is " & integer'image(if_level));
                        if if_state(if_level) = true then
                            print(" resolved if_state " & integer'image(if_level) & " is true");
                        else
                            print(" resolved if_state " & integer'image(if_level) & " is false");
                        end if;
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip the else
                        bien := ien + 1;
                        bie := insts.element_ptrs(bien);
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 
                              or crop(ie.inst) /= INSTR_END_IF 
                        loop
                            if crop(bie.inst) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if crop(bie.inst) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert bien <= insts.last_element_num
                            report "if instruction unable to find terminating else, elsif or end_if statement." &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                            bien := ien + 1;
                        end loop;
                        ien := bien - 1; -- re-align so it will be operated on.
                    end if;

                -- end if
                elsif crop(ie.inst) = INSTR_END_IF then
                    if_level := if_level - 1;
                    if trc_on(TRACE_IF_TREES) = '1' then
                        print(" decremented if_level " & integer'image(if_level));
                    end if;

                -- loop loop_num
                -- loop 100
                elsif crop(ie.inst) = INSTR_LOOP then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    rcs(sp).loop_if_enter_level := if_level;
                    act_loop_num := rcs(sp).loop_num;
                    if trc_on(TRACE_CALLS) = '1' then
                        print_instr("exec ");
                        print(" sp:" & integer'image(sp));
                        print(" stack_loop_if_enter_level(" & integer'image(sp) & ")=" & integer'image(if_level));
                        print(" act_loop_num: stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num));
                    end if;
                    act_loop_num := act_loop_num + 1;
                    rcs(sp).loop_num := act_loop_num;
                    rcs(sp).loop_line(act_loop_num) := ien;
                    rcs(sp).curr_loop_count(act_loop_num) := 0;
                    rcs(sp).term_loop_count(act_loop_num) := to_integer(val1(30 downto 0));
                    if trc_on(TRACE_CALLS) = '1' then
                        print(crop(ie.inst) & " incremented stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num));
                        print(crop(ie.inst) & " set to goto ien: stack_loop_line(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(ien));
                        print(crop(ie.inst) & " stack_curr_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(rcs(sp).curr_loop_count(act_loop_num)));
                        print(crop(ie.inst) & " stack_term_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(rcs(sp).term_loop_count(act_loop_num)));
                    end if;

                -- end loop
                elsif crop(ie.inst) = INSTR_END_LOOP then
                    act_loop_num := rcs(sp).loop_num;
                    act_curr_loop_count := rcs(sp).curr_loop_count(act_loop_num);
                    act_curr_loop_count := act_curr_loop_count + 1;
                    rcs(sp).curr_loop_count(act_loop_num) := act_curr_loop_count;
                    act_term_loop_count := rcs(sp).term_loop_count(act_loop_num);
                    if trc_on(TRACE_CALLS) = '1' then
                        print_instr("exec ");
                        print(" sp:" & integer'image(sp));
                        print(" act_loop_num: stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num));
                        print(" set incremented stack_curr_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_curr_loop_count));
                        print(" stack_term_loop_count(" & integer'image(sp) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_term_loop_count));
                    end if;
                    if (act_curr_loop_count = act_term_loop_count) then
                        act_loop_num := act_loop_num - 1;
                        rcs(sp).loop_num := act_loop_num;
                        if trc_on(TRACE_CALLS) = '1' then
                            print(" loop count reached, exiting, set decremented stack_loop_num(" & integer'image(sp) & ")=" & integer'image(act_loop_num));
                        end if;
                    else
                        ien := rcs(sp).loop_line(act_loop_num);
                    end if;

                -- abort
                elsif crop(ie.inst) = INSTR_ABORT then
                    print_instr("exec ");
                    print("the simulation aborts");
                    finish;

                -- stop
                elsif crop(ie.inst) = INSTR_STOP then
                    print_instr("exec ");
                    print("the simulation has been stopped for debugging by command");
                    stop;

                -- finish
                elsif crop(ie.inst) = INSTR_FINISH then
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
                elsif crop(ie.inst) = INSTR_PROC
                      or crop(ie.inst) = INSTR_PROC_PAR_OPEN
                      or crop(ie.inst) = INSTR_PROC_NOPAR then
                    null; -- no action necessary

                -- end proc
                -- end interrupt
                -- return
                elsif crop(ie.inst) = INSTR_RETURN or crop(ie.inst) = INSTR_END_PROC or crop(ie.inst) = INSTR_END_INTERRUPT then
                    if trc_on(TRACE_CALLS) then
                        print_instr("exec ");
                    end if;
                    act_loop_num := rcs(sp).loop_num;
                    if act_loop_num > 0 then
                        if_level := rcs(sp).loop_if_enter_level;
                        rcs(sp).loop_num := 0;
                    end if;
                    if sp = 0 then
                        print_instr("exec ");
                        print("leaving proc Main shall not happen, simulation shall be ended by a finish or abort instruction inside proc Main, ");
                        finish;
                    end if;
                    assert sp >= 0
                    report "stack underrun:" & 
                       " stack pointer " & integer'image(sp) & 
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
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
                    ien := rcs(sp).ien_of_call;
                    if trc_on(TRACE_STACK) then
                        print_instr("entering previous runtime_context ");
                        print_runtime_context(rcs(sp));       
                    end if;
                    wait for 0 ns;

                -- call some_proc ()
                -- call some_proc (
                -- call label some_label ()
                -- call label some_label (
                elsif crop(ie.inst) = INSTR_CALL_NOPAR 
                      or crop(ie.inst) = INSTR_CALL_PAR_OPEN
                      or crop(ie.inst) = INSTR_CALL_LABEL_NOPAR
                      or crop(ie.inst) = INSTR_CALL_LABEL_PAR_OPEN then
                    assert sp < max_num_of_stack_elements
                    report "stack overrun:" & 
                       " stack pointer " & integer'image(sp) & 
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                    if trc_on(TRACE_STACK) then
                        print_instr("leaving runtime_context ");
                        print_runtime_context(rcs(sp));       
                    end if;
                    sp := sp + 1;
                    init_runtime_context(rcs(sp));         
                    if trc_on(TRACE_CALLS) then
                        print_instr("exec ");
                    end if;
                    rcs(sp).ien_of_call := ien;         
                    if crop(ie.inst) = INSTR_CALL_NOPAR then
                       access_proc(slc, procs, ie.inst_args.par_text_fields(1), ien);
                       rcs(sp).call_process_state := IN_PROC_BODY;    
                    elsif crop(ie.inst) = INSTR_CALL_PAR_OPEN then                       
                       access_proc(slc, procs, ie.inst_args.par_text_fields(1), ien);
                       rcs(sp).call_process_state := IN_PROC_PARAMS;                                                            
                    elsif crop(ie.inst) = INSTR_CALL_LABEL_NOPAR then
                          get_ven_in_called_scope_prefer_local(1, ven1); 
                          index_var(vars, ven1, var_stm_label);                        
                          access_proc(slc, procs, var_stm_label, pen);
                          ien := procs.element_ptrs(pen).pointer_to_ien;
                          rcs(sp).call_process_state := IN_PROC_BODY; 
                    elsif crop(ie.inst) = INSTR_CALL_LABEL_PAR_OPEN then
                          get_ven_in_called_scope_prefer_local(1, ven1); 
                          index_var(vars, ven1, var_stm_label);                        
                          access_proc(slc, procs, var_stm_label, pen);
                          ien := procs.element_ptrs(pen).pointer_to_ien;
                          rcs(sp).call_process_state := IN_PROC_PARAMS; 
                    end if;      
                                  
                -- ) 
                elsif crop(ie.inst) = INSTR_PAR_CLOSE then
                    if rcs(sp).call_process_state = IN_PROC_PARAMS then
                        rcs(sp).call_process_state := IN_CALL_PARAMS; 
                        rcs(sp).ien_of_proc_params_end := ien;
                        ien := rcs(sp).ien_of_call;
                    elsif rcs(sp).call_process_state = IN_CALL_PARAMS then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                        ien := rcs(sp).ien_of_proc_params_end;                                 
                    end if;
                    
                -- log message INFO "some message"
                -- log message  INFO "misc_proc severity: {}" INFO
                elsif crop(ie.inst) = INSTR_LOG_MESSAGE then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    if val1 <= loglevel then
                        txt_print_wvar(slc, insts, vars, rcs, txt, txt_enclosing_quote, sp, machine_value_width);
                    end if;

                -- log lines INFO a_lines
                elsif crop(ie.inst) = INSTR_LOG_LINES then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    get_ven_in_called_scope_prefer_local(2, ven2); 
                    index_var(vars, ven2, var_stm_lines);
                    if val1 <= loglevel then
                        stm_lines_print(var_stm_lines);
                        assert valid_bus /= 0
                        report "lines object access failed:" & 
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end if;

                -- trace 1
                elsif crop(ie.inst) = INSTR_TRACE then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    trc_on := val1;

                -- verbosity INFO
                -- verbosity 25
                elsif crop(ie.inst) = INSTR_VERBOSITY then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    loglevel := val1;

                -- resume ON_VERIFY (Flag Bit0) or BUS_TIMEOUT (Flag Bit1) failure
                -- if respective flag in resume value is set
                elsif crop(ie.inst) = INSTR_RESUME then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    resume := val1;

                -- seed seed_var
                -- seed 1397
                elsif crop(ie.inst) = INSTR_SEED then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    assert val1 > 0
                    report "seed expects a value > 0" &  
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                    seed1 := to_integer(val1(30 downto 0));
                    if seed1 > 1 then
                        seed2 := seed1 - 1;
                    else
                        seed2 := seed1 + 42;
                    end if;

                -- random rand_var rand_min_var rand_max_var
                -- random rand_var 0 rand_max_var
                -- random rand_var rand_min_var 9
                -- random rand_var 3 9
                elsif crop(ie.inst) = INSTR_RANDOM then
                    get_ven_in_called_scope_prefer_local(1, ven1); 
                    get_val_in_called_scope_prefer_local(2, val2); 
                    get_val_in_called_scope_prefer_local(3, val3); 
                    index_var(vars, ven1, val);
                    random(seed1, seed2, val2, val3, val);
                    update_var(vars, ven1, val);

                -- wait time_to_wait
                -- wait 10000
                elsif crop(ie.inst) = INSTR_WAIT then
                    get_val_in_called_scope_prefer_local(1, val1); 
                    wait for to_integer(val1(30 downto 0)) * 1 ns;

                -- marker 5 1 sets marker number 5 to high
                -- marker 7 0 sets marker number 7 to low
                elsif crop(ie.inst) = INSTR_MARKER then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2); 
                    if val1 < 16 then
                        for i in 0 to 15 loop
                            if val1 = i then
                                if val2 = 0 then
                                    temp_marker(i) := '0';
                                else
                                    temp_marker(i) := '1';
                                end if;
                            end if;
                        end loop;
                        
                    else
                        assert false
                        report "16 markers are provided only:" & 
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    end if;
                    marker <= temp_marker;
                    wait for 0 ns;

                -- var verify a_var var_expected_value var_mask_value
                -- var verify a_var 0x0002 0x00FF
                elsif crop(ie.inst) = INSTR_VAR_VERIFY then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    get_val_in_called_scope_prefer_local(3, val3);
                    verify_passes_count := verify_passes_count + 1;
                    if (val3 and val1) /= (val3 and val2) then
                        print_instr("exec ");
                        print(" read     = 0x" & to_hstring(val1));
                        print(" expected = 0x" & to_hstring(val2));
                        print(" mask     = 0x" & to_hstring(val3));
                        if resume(0) = '0' then
                            assert false
                            report "verify failure assertion" &  
                               " file name: " & crop(ie.slc.file_name) & 
                               " file line: " & integer'image(ie.slc.file_line)
                            severity failure;
                        else
                            assert false
                            report "verify error assertion" &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                            severity error;
                            verify_failure_count := verify_failure_count + 1;
                        end if;
                    end if;

                -- signal write a_signal signal_to_be_set_value
                -- signal write a_signal 0x1234
                elsif crop(ie.inst) = INSTR_SIGNAL_WRITE then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val_int := to_integer(val1(30 downto 0));
                    signal_write(signals_out, val_int, val2, signal_valid);
                    assert signal_valid /= 0
                    report "trying to write invalid signal" &  
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                    severity failure;                  
                    wait for 0 ns;

                -- signal read a_signal signal_read_value
                -- signal verify a_signal signal_read_value signal_expected_value signal_mask_value
                -- signal verify a_signal signal_read_value 0x0002 0x00FF
                -- signal_read or signal_verify
                elsif crop(ie.inst) = INSTR_SIGNAL_VERIFY or crop(ie.inst) = INSTR_SIGNAL_READ then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    get_val_in_called_scope_prefer_local(3, val3);
                    get_val_in_called_scope_prefer_local(4, val4);
                    val_int := to_integer(val1(30 downto 0));
                    signal_read(signals_in, val_int, val, signal_valid);
                    assert signal_valid /= 0
                    report "trying to read invalid signal" &  
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                    severity failure;                    
                    update_var(vars, ven2, val);
                    if (crop(ie.inst) = INSTR_SIGNAL_VERIFY) then
                        verify_passes_count := verify_passes_count + 1;
                        if (val4 and val) /= (val4 and val3) then
                            print_instr("exec ");
                            print(" signal   = 0x" & to_hstring(val1));
                            print(" read     = 0x" & to_hstring(val));
                            print(" expected = 0x" & to_hstring(val3));
                            print(" mask     = 0x" & to_hstring(val4));
                            if resume(0) = '0' then
                                assert false
                                report "verify failure assertion" &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                                severity failure;
                            else
                                assert false
                                report "verify error assertion" &  
                                       " file name: " & crop(ie.slc.file_name) & 
                                       " file line: " & integer'image(ie.slc.file_line)
                                severity error;
                                verify_failure_count := verify_failure_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                --  signal pointer copy a_signal_target a_signal_source
                --  signal pointer copy a_signal_target a_signal_source )
                elsif crop(ie.inst) = INSTR_SIGNAL_POINTER_COPY or crop(ie.inst) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_val_in_called_scope_call_params_source_sensitive(2, val2);
                    update_var(vars, ven1, val2);
                    if crop(ie.inst) = INSTR_SIGNAL_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                --  signal pointer set a_signal_target a_var
                --  signal pointer set a_signal_target 0x01
                elsif crop(ie.inst) = INSTR_SIGNAL_POINTER_SET then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    update_var(vars, ven1, val2);

                --  signal pointer get a_signal_source a_var
                elsif crop(ie.inst) = INSTR_SIGNAL_POINTER_GET then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    update_var(vars, ven2, val1);

                -- bus write a_bus bus_width  bus_address bus_to_be_set_value
                -- bus write a_bus 16 0x00001000 0x1233
                elsif crop(ie.inst) = INSTR_BUS_WRITE then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    get_val_in_called_scope_prefer_local(3, val3);
                    get_val_in_called_scope_prefer_local(4, val4);
                    val2_int := to_integer(val2(30 downto 0));
                    val_int := to_integer(val1(30 downto 0));
                    bus_write(bus_down, bus_up, val3, val4, val2_int, val_int, bus_valid, successfull, bus_timeouts(to_integer(val1(30 downto 0))));
                    assert bus_valid /= 0
                    report "trying to write to invalid bus" &  
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                    severity failure;                  
                    bus_timeout_passes_count := bus_timeout_passes_count + 1;
                    if resume(1) = '0' then
                        assert successfull
                        report "bus write timeout failure assertion" &  
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity failure;
                    else
                        if not successfull then
                            bus_timeout_failure_count := bus_timeout_failure_count + 1;
                        end if;
                        assert successfull
                        report "bus write timeout error assertion" &  
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                        severity error;
                    end if;
                    wait for 0 ns;

                -- bus read  a_bus bus_width  bus_address  bus_read_value
                -- bus read  a_bus 16 0x00001000  bus_read_value
                -- bus verify a_bus bus_width  bus_address bus_read_value bus_expected_value bus_mask_value
                -- bus verify a_bus 32  0x00001004 bus_read_value 0x00050000 0x000FC000
                elsif crop(ie.inst) = INSTR_BUS_READ or crop(ie.inst) = INSTR_BUS_VERIFY then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    get_val_in_called_scope_prefer_local(3, val3);
                    get_ven_in_called_scope_prefer_local(4, ven4);
                    get_val_in_called_scope_prefer_local(5, val5);
                    get_val_in_called_scope_prefer_local(6, val6);
                    val2_int := to_integer(val2(30 downto 0));
                    val_int := to_integer(val1(30 downto 0));
                    bus_read(bus_down, bus_up, val3, val, val2_int, val_int, bus_valid, successfull, bus_timeouts(val_int));
                    assert bus_valid /= 0
                    report "trying to read from invalid bus" &  
                       " file name: " & crop(ie.slc.file_name) & 
                       " file line: " & integer'image(ie.slc.file_line)
                    severity failure;   
                    bus_timeout_passes_count := bus_timeout_passes_count + 1;
                    if resume(1) = '0' then
                        assert successfull
                        report "bus read timeout"
                        severity failure;
                    else
                        if not successfull then
                            bus_timeout_failure_count := bus_timeout_failure_count + 1;
                        end if;
                        assert successfull
                        report "bus read timeout"
                        severity error;
                    end if;
                    update_var(vars, ven4, val);
                    if crop(ie.inst) = INSTR_BUS_VERIFY then
                        verify_passes_count := verify_passes_count + 1;
                        if (val6 and val) /= (val6 and val5) then
                            print_instr("exec ");
                            print(" bus      = 0x" & to_hstring(val));
                            print(" address  = 0x" & to_hstring(val3));
                            print(" read     = 0x" & to_hstring(val));
                            print(" expected = 0x" & to_hstring(val5));
                            print(" mask     = 0x" & to_hstring(val6));
                            if resume(0) = '0' then
                                assert false
                                report "verify failure assertion" &  
                                   " file name: " & crop(ie.slc.file_name) & 
                                   " file line: " & integer'image(ie.slc.file_line)
                                severity failure;
                            else
                                assert false
                                report "verify error assertion" &  
                                       " file name: " & crop(ie.slc.file_name) & 
                                       " file line: " & integer'image(ie.slc.file_line)
                                severity error;
                                verify_failure_count := verify_failure_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                -- bus timeout a_bus 1000
                -- bus timeout a_bus bus_timeout_value
                elsif crop(ie.inst) = INSTR_BUS_TIMEOUT_SET then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    val_int := to_integer(val1(30 downto 0));
                    val2_int := to_integer(val2(30 downto 0));
                    bus_timeouts(val_int) := val2_int * 1 ns;

                elsif crop(ie.inst) = INSTR_BUS_TIMEOUT_GET then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    val1_int := to_integer(val1(30 downto 0));
                    val := to_unsigned(bus_timeouts(val1_int) / 1 ns, machine_value_width);
                    update_var(vars, ven2, val);

                --  bus pointer copy a_file_target a_file_source
                --  bus pointer copy a_file_target a_file_source (
                elsif crop(ie.inst) = INSTR_BUS_POINTER_COPY or crop(ie.inst) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
                    get_ven_in_called_scope_call_params_target_sensitive(1, ven1);
                    get_val_in_called_scope_call_params_source_sensitive(2, val2);
                    update_var(vars, ven1, val2);
                    if crop(ie.inst) = INSTR_BUS_POINTER_COPY_PAR_CLOSE then
                        rcs(sp).call_process_state := IN_PROC_BODY;
                    end if;

                --  bus pointer set a_bus_target a_var
                --  bus pointer set a_bus_target 0x01
                elsif crop(ie.inst) = INSTR_BUS_POINTER_SET then
                    get_ven_in_called_scope_prefer_local(1, ven1);
                    get_val_in_called_scope_prefer_local(2, val2);
                    update_var(vars, ven1, val2);

                --  bus pointer get a_bus_source a_var
                elsif crop(ie.inst) = INSTR_BUS_POINTER_GET then
                    get_val_in_called_scope_prefer_local(1, val1);
                    get_ven_in_called_scope_prefer_local(2, ven2);
                    update_var(vars, ven2, val1);

                -- undefined instructions
                else
                    assert false
                    report "seems the command  " & ", " & crop(ie.inst) & " was defined but" &  
                           "was not found in the elsif chain, please check spelling" &  
                           " file name: " & crop(ie.slc.file_name) & 
                           " file line: " & integer'image(ie.slc.file_line)
                    severity failure;
                end if;

            end if;

        end loop;

        assert false
        report "simulation not terminated by finish or abort instruction as expected by general simstm policy."
        severity failure;

    end process;
end;
