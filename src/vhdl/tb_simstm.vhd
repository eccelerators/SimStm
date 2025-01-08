-------------------------------------------------------------------------------
--             Copyright 2023  Ken Campbell
--               All rights reserved.
-------------------------------------------------------------------------------
-- $Author: sckoarn $
--
-- $Date:  $
--
-- $Id:  $
--
-- $Source:  $
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
use work.tb_interpreter_pkg.all;
use work.tb_bus_pkg.all;
use work.tb_signals_pkg.all;

entity tb_simstm is
    generic(
        stimulus_path : in string;
        stimulus_file : in string;
        stimulus_main_entry_label : in string := "$testMain"
    );
    port(
        executing_line : out integer;
        executing_file : out text_line;
        verify_passes : out std_logic_vector(c_stm_value_width - 1 downto 0);
        verify_failures : out std_logic_vector(c_stm_value_width - 1 downto 0);
        bus_timeout_passes : out std_logic_vector(c_stm_value_width - 1 downto 0);
        bus_timeout_failures : out std_logic_vector(c_stm_value_width - 1 downto 0);
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
    
    function ld(m : unsigned) return unsigned is
    begin
        if m < 0 then
            return to_unsigned(m'high, m'length);
        end if;
        for n in 0 to m'high loop
            if (2 ** n >= m) then
                return to_unsigned(n, m'length);
            end if;
        end loop;
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
    --! records are drawn from the user instruction list, variables are converted
    --! to integers and put through the elsif structure for exicution.

    read_file : process
        variable inst_list : inst_def_ptr; -- the instruction list
        variable defined_vars : var_field_ptr; -- defined variables
        variable inst_sequ : stim_line_ptr; -- the instruction sequence
        variable file_list : file_def_ptr; -- pointer to the list of file names
        variable last_sequ_num : integer;
        variable last_sequ_ptr : stim_line_ptr;

        variable instruction : text_field; -- instruction field
        variable par1 : t_stm_value; -- parameter 1
        variable par2 : t_stm_value; -- parameter 2
        variable par3 : t_stm_value; -- parameter 3
        variable par4 : t_stm_value; -- parameter 4
        variable par5 : t_stm_value; -- parameter 5
        variable par6 : t_stm_value; -- parameter 6
        variable txt : stm_text_ptr;
        variable txt_enclosing_quote : character;
        variable len : integer; -- length of the instruction field
        variable file_line : integer; -- line number in the stimulus file
        variable file_name : text_line; -- the file name the line came from
        variable v_line : integer := 0; -- sequence number
        variable stack : stack_register; -- call stack
        variable stack_called_labels : stack_text_field_array; -- called labels
        variable stack_called_files : stack_text_line_array; -- called files
        variable stack_called_file_line_numbers : stack_numbers_array; -- called line numbers
        variable stack_ptr : integer := 0; -- call stack pointer
        variable act_loop_num : integer := 0;
        variable act_curr_loop_count : integer := 0;
        variable act_term_loop_count : integer := 0;
        variable stack_loop_num : stack_int_array := (others => 0);
        variable stack_curr_loop_count : stack_int_array_array := (others => (others => 0));
        variable stack_term_loop_count : stack_int_array_array := (others => (others => 0));
        variable stack_loop_line : stack_int_array_array := (others => (others => 0));
        variable stack_loop_if_enter_level : stack_int_array := (others => 0);

        variable loglevel : t_stm_value := to_unsigned(0, c_stm_value_width);
        variable resume : t_stm_value := to_unsigned(0, c_stm_value_width);
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
        variable temp_stm_value : t_stm_value;
        variable temp_stm_value_b : t_stm_value;
        variable number_found : integer;
       
        variable temp_marker : std_logic_vector(15 downto 0) := (others => '0');

        variable trc_on : t_stm_value := to_unsigned(0, c_stm_value_width);

        file stimulus : text; -- file main file
        variable v_stat : file_open_status;

        -- Bus
        type bus_timeout_array is array (0 to 127) of time;
        variable bus_timeouts : bus_timeout_array := (others => 1 sec);

        -- Array
        variable var_stm_array : t_stm_array_ptr;

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

        variable main_label_text_field : text_field;
        -- variable main_label_string : string := stimulus_main_entry_label;
        variable main_line : integer := 0;
        variable main_entered : integer := 0;

        variable interrupt_requests : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');
        variable interrupt_in_service : unsigned(number_of_interrupts - 1 downto 0) := (others => '0');

        variable interrupt_number : integer := 0;
        variable branch_to_interrupt : boolean := false;
        variable branch_to_interrupt_label : text_field;
        variable branch_to_interrupt_label_std_txt_io_line : line;
        variable branch_to_interrupt_v_line : integer := 0;
        
        variable called_label :text_field;
        
    begin
        marker <= (others => '0');
        verify_passes <= (others => '0');
        verify_failures <= (others => '0');
        bus_timeout_passes <= (others => '0');
        bus_timeout_failures <= (others => '0');
        signals_out <= signals_out_init;
        bus_down <= bus_down_init;
        wait for 0 ns;

        init_const_text_field(stimulus_main_entry_label, main_label_text_field);
        define_instructions(inst_list);

        file_open(v_stat, stimulus, stimulus_path & stimulus_file, read_mode);
        assert v_stat = open_ok
        report lf & "error: unable to open stimulus_file " & stimulus_path & stimulus_file
        severity failure;
        file_close(stimulus);

        -- read, test, and load the stimulus file
        read_instruction_file(stimulus_path, stimulus_file, inst_list, defined_vars, inst_sequ, file_list);

        -- initialize last info
        last_sequ_num := 0;
        last_sequ_ptr := inst_sequ;

        -- using the instruction record list, get the instruction and implement
        -- it as per the statements in the elsif tree.
        while v_line < inst_sequ.num_of_lines loop

            verify_passes <= std_logic_vector(to_unsigned(verify_passes_count, c_stm_value_width));        
            verify_failures <= std_logic_vector(to_unsigned(verify_failure_count, c_stm_value_width));
            bus_timeout_passes <= std_logic_vector(to_unsigned(bus_timeout_passes_count, c_stm_value_width));
            bus_timeout_failures <= std_logic_vector(to_unsigned(bus_timeout_failure_count, c_stm_value_width));
            
            get_interrupt_requests(signals_in, interrupt_requests);
            if interrupt_requests > 0 then
                resolve_interrupt_requests(interrupt_requests, interrupt_in_service, interrupt_number, branch_to_interrupt, branch_to_interrupt_label_std_txt_io_line);
            end if;

            if main_entered = 0 then
                access_variable(defined_vars, main_label_text_field, main_line, valid);               
                assert valid = 1
                report lf & "error: Entry point proc Main not found !"
                severity failure;
                v_line := main_line;
                main_entered := 1;

            elsif branch_to_interrupt then
                if (stack_ptr >= 31) then
                    assert false
                    report " line " & (integer'image(file_line)) & " interrupt enter error: stack over run, calls to deeply nested!!"
                    severity failure;
                end if;
                if (stack_ptr >= 31) then
                    assert false
                    report " line " & (integer'image(file_line)) & " interrupt enter error: interrupt number stack over run, interrupts to deeply nested!!"
                    severity failure;
                end if;
                interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer + 1;
                interrupt_number_entered_stack(interrupt_number_entered_stack_pointer) := interrupt_number;
                interrupt_entry_call_stack_ptr_stack(interrupt_number_entered_stack_pointer) := stack_ptr;
                v_set_interrupt_in_service := '1';
                set_interrupt_in_service(interrupt_in_service, interrupt_number, v_set_interrupt_in_service, signals_out);                
                stack(stack_ptr) := v_line;
                stack_ptr := stack_ptr + 1;
                line_to_text_field(branch_to_interrupt_label_std_txt_io_line, branch_to_interrupt_label);
                access_variable(defined_vars, branch_to_interrupt_label, branch_to_interrupt_v_line, valid);
                assert valid = 1
                report lf & "error: Interrupt entry point $branch_to_interrupt_label not found !"
                severity failure;
                stack_called_labels(stack_ptr) := branch_to_interrupt_label;                
                v_line := branch_to_interrupt_v_line;
                access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                 par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                 last_sequ_num, last_sequ_ptr);
                stack_called_files(stack_ptr) := file_name;
                stack_called_file_line_numbers(stack_ptr) := file_line;
                wait for 0 ns;

            else

                v_line := v_line + 1;
                access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                 par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                 last_sequ_num, last_sequ_ptr);

                if trc_on(3) = '1' then
                    dump_file_defs(file_list);
                end if;
                if trc_on(2) = '1' then
                    dump_variables(defined_vars);
                end if;
                if trc_on(1) = '1' then
                    print_inst(inst_sequ, v_line, file_list);
                end if;

                executing_line <= file_line;
                executing_file <= file_name;
                wait for 100 ps;

                if trc_on(0) = '1' then
                    report "exec line " & (integer'image(file_line)) & " " & instruction(1 to len) & " file " & text_line_crop(file_name);
                end if;

                -- include "an_include.stm"
                if instruction(1 to len) = INSTR_INCLUDE then
                    null; -- This instruction was implemented while reading the file
                --
                -- const a_const_num 0x03
                -- const a_constB $a_constA
                -- const a_constC $a_varA
                elsif instruction(1 to len) = INSTR_CONST then
                    null; -- This instruction was implemented while reading the file

                -- var a_varA 0x05
                -- var a_varB $a_varA
                -- var a_varC $a_constA
                elsif instruction(1 to len) = INSTR_VAR then
                    null; -- This instruction was implemented while reading the file

                -- array an_array 16
                elsif instruction(1 to len) = INSTR_ARRAY then
                    null; -- This instruction was implemented while reading the file

                -- file a_fileA "file_name"
                -- file a_fileB "file_name{}{}" $file_user_index1 $file_user_index2
                elsif instruction(1 to len) = INSTR_FILE then
                    null; -- This instruction was implemented while reading the file

                -- signal a_signal
                elsif instruction(1 to len) = INSTR_SIGNAL then
                    null; -- This instruction was implemented while reading the file
                --
                -- bus a_bus
                elsif instruction(1 to len) = INSTR_BUS then
                    null; -- This instruction was implemented while reading the file
                --
                -- lines a_lines
                elsif instruction(1 to len) = INSTR_LINES then
                    null; -- This instruction was implemented while reading the file

                -- equ operand1_and_target $operand2
                -- equ operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_EQU then
                    update_variable(defined_vars, par1, par2, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " equ error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- equ operand1_and_target $operand2
                -- add operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_ADD then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add error: not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value + par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- equ operand1_and_target $operand2
                -- sub operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_SUB then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub error: not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value - par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- mul operand1_and_target $operand2
                -- mul operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_MUL then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := resize(resize(temp_stm_value, c_stm_value_width * 2)  * resize(par2, c_stm_value_width * 2), c_stm_value_width);
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- div operand1_and_target $operand2
                -- div operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_DIV then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value / par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " div error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- and operand1_and_target $operand2
                -- and operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_AND then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value and par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " and error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- or operand1_and_target $operand2
                -- or operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_OR then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value or par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " or error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- xor operand1_and_target $operand2
                -- xor operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_XOR then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := temp_stm_value xor par2;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " xor error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- shl operand1_and_target $operand2
                -- shl operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_SHL then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := shift_left(temp_stm_value, to_integer(par2(30 downto 0)));
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- shr operand1_and_target $operand2
                -- shr operand1_and_target 0xF0
                elsif instruction(1 to len) = INSTR_SHR then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := shift_right(temp_stm_value, to_integer(par2(30 downto 0)));
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- inv operand1_and_target
                elsif instruction(1 to len) = INSTR_INV then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := not temp_stm_value;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " inv error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- ld operand1_and_target
                elsif instruction(1 to len) = INSTR_LD then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value := ld(temp_stm_value);
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " ld error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- array set an_array $array_position 0x07
                -- array set an_array $array_position $a_varA
                -- array set an_array 5 0x07
                -- array set an_array 3 $a_varA
                elsif instruction(1 to len) = INSTR_ARRAY_SET then
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    assert var_stm_array'length > par2
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: index is out of array size"
                    severity failure;
                    var_stm_array(to_integer(par2(30 downto 0))) := par3;

                -- array get an_array $array_position a_varB
                elsif instruction(1 to len) = INSTR_ARRAY_GET then
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    assert var_stm_array'length > par2
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: index is out of array size"
                    severity failure;
                    temp_stm_value := var_stm_array(to_integer(par2(30 downto 0)));
                    update_variable(defined_vars, par3, temp_stm_value, valid);
                    assert valid /= 0
                    report "array_get error: not a valid variable??"
                    severity failure;

                --  array size an_array array_size
                elsif instruction(1 to len) = INSTR_ARRAY_SIZE then
                    temp_int := 0;
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    temp_stm_value := to_unsigned(var_stm_array'length, c_stm_value_width);
                    update_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report "array_size error: not a valid variable??"
                    severity failure;

                -- array pointer an_array another_array
                elsif instruction(1 to len) = INSTR_ARRAY_POINTER_COPY then
                    index_variable(defined_vars, par2, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    update_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report "array_pointer error: not a array name??"
                    severity failure;
                                                         
                -- array verify $a_var $array_position $var_expected_value $var_mask_value
                -- array verify $a_var $array_position 0x0002 0x00FF
                -- array verify $a_var 5 $var_expected_value $var_mask_value
                -- array verify $a_var 5 0x0002 0x00FF               
                elsif instruction(1 to len) = INSTR_ARRAY_VERIFY then
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    assert var_stm_array'length > par2
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: index is out of array size"
                    severity failure;
                    verify_passes_count := verify_passes_count + 1; 
                    temp_stm_value := var_stm_array(to_integer(par2(30 downto 0)));
                    if (par4 and temp_stm_value) /= (par4 and par3) then                            
                        if resume(0) = '0' then
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", array("& (to_hstring(par2)) & ")=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par3) & ", mask=0x" & to_hstring(par4) & ", file " & text_line_crop(file_name)                       
                            severity failure;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", array("& (to_hstring(par2)) & ")=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par3) & ", mask=0x" & to_hstring(par4) & ", file " & text_line_crop(file_name)                       
                            severity error;
                            verify_failure_count := verify_failure_count + 1;                            
                        end if;
                    end if;

                -- file readable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_READABLE then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);             
                    stm_file_readable(var_stm_text_substituded_ptr, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- file writeable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_WRITEABLE then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);             
                    stm_file_writeable(var_stm_text_substituded_ptr, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- file appendable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_APPENDABLE then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);             
                    stm_file_appendable(var_stm_text_substituded_ptr, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- file write a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_WRITE then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);                   
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);             
                    stm_file_write(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file write not successful"
                    severity failure;

                -- file append a_fileB  a_lines
                elsif instruction(1 to len) = INSTR_FILE_APPEND then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);                   
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);              
                    stm_file_append(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file append not successful"
                    severity failure;

                -- file read a_fileA a_lines $number_of_lines
                -- file read a_fileA a_lines 256
                elsif instruction(1 to len) = INSTR_FILE_READ then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: position object not found"
                    severity failure;
                    user_file_append_done := false;
                    -- if file is already in use, us it
                    if user_file_in_use_0 then
                        if var_stm_text = user_file_name_0 then
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_1 then
                        if var_stm_text = user_file_name_1 then
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_2 then
                        if var_stm_text = user_file_name_2 then
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_3 then
                        if var_stm_text = user_file_name_3 then
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                            user_file_append_done := true;
                        end if;
                    end if;
                    -- if file is not in use, try to open and use it
                    if not user_file_append_done then
                        stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);                   
                        var_stm_text_substituded_ptr := new stm_text;
                        stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);   
                        txt_to_string(var_stm_text_substituded_ptr, user_file_path_string);
                        user_file_open_done := false;
                        if not user_file_in_use_0 and not user_file_open_done then
                            file_open(v_stat, user_file_0, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_0 := var_stm_text;
                            user_file_in_use_0 := true;
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_0, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_1 and not user_file_open_done then
                            file_open(v_stat, user_file_1, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_1 := var_stm_text;
                            user_file_in_use_1 := true;
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_1, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_2 and not user_file_open_done then
                            file_open(v_stat, user_file_2, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_2 := var_stm_text;
                            user_file_in_use_2 := true;
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_2, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                        elsif not user_file_in_use_3 and not user_file_open_done then
                            file_open(v_stat, user_file_3, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_3 := var_stm_text;
                            user_file_in_use_3 := true;
                            for i in 1 to to_integer(par3(30 downto 0)) loop
                                readline(user_file_3, user_std_line);
                                tmp_std_line := new string'(user_std_line.all);
                                stm_lines_append(var_stm_lines, tmp_std_line, stm_lines_append_valid);
                                assert valid /= 0
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                                severity failure;
                            end loop;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: only 4 files are allowed for file read concurrently"
                            severity failure;
                        end if;
                    end if;

                -- file read end a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_READ_END then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);                   
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
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: trying to end file not started or already ended for read"
                        severity failure;
                    end if;

                -- file read all a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_READ_ALL then
                    index_variable(defined_vars, par1, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: position object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, var_stm_text, var_stm_text_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);                   
                    var_stm_text_substituded_ptr := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_substituded_ptr, var_stm_text_substituded);   
                    stm_file_read_all(var_stm_lines, var_stm_text_substituded_ptr, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file read not successful"
                    severity failure;

                --  file pointer copy a_file_target a_file_source
                elsif instruction(1 to len) = INSTR_FILE_POINTER_COPY then
                    index_variable(defined_vars, par2, var_stm_text, var_stm_text_enclosing_quote, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    update_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report "files_pointer error: not a lines object name??"
                    severity failure;
                                   
                -- lines get a_lines $position an_array number_found
                -- lines get a_lines 8 an_array number_found
                elsif instruction(1 to len) = INSTR_LINES_GET_ARRAY then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    index_variable(defined_vars, par3, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not found"
                    severity failure;
                    stm_lines_get(var_stm_lines, to_integer(par2(30 downto 0)), var_stm_array, number_found, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not get successfully"
                    severity failure;
                    update_variable(defined_vars, par3, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;
                    update_variable(defined_vars, par4, number_found, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- lines set a_lines $position an_array
                -- lines set a_lines 9 an_array
                elsif instruction(1 to len) = INSTR_LINES_SET_ARRAY then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    index_variable(defined_vars, par3, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not found"
                    severity failure;
                    stm_lines_set(var_stm_lines, to_integer(par2(30 downto 0)), var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not set successfully"
                    severity failure;

                -- lines set a_lines $position "abc" txt
                -- lines set a_lines 7 "abc"
                -- lines set a_lines $position "abc{}" $a_varB
                -- lines set a_lines 7 "abc{}" $a_varB
                elsif instruction(1 to len) = INSTR_LINES_SET_MESSAGE then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, txt, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    stm_lines_set(var_stm_lines, to_integer(par2(30 downto 0)), var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: message not set successfully"
                    severity failure;

                -- lines insert a_lines $position an_array
                -- lines insert a_lines 9 an_array
                elsif (instruction(1 to len) = INSTR_LINES_INSERT_ARRAY) then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    index_variable(defined_vars, par3, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not found"
                    severity failure;
                    stm_lines_insert(var_stm_lines, to_integer(par2(30 downto 0)), var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not inserted successfully"
                    severity failure;

                -- lines insert a_lines $position "abc"
                -- lines insert a_lines 7 "abc"
                -- lines insert a_lines $position "abc{}" $a_varB
                -- lines insert a_lines 7 "abc{}" $a_varB
                elsif (instruction(1 to len) = INSTR_LINES_INSERT_MESSAGE) then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, txt, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    stm_lines_insert(var_stm_lines, to_integer(par2(30 downto 0)), var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: message not inserted successfully"
                    severity failure;

                -- lines append a_lines an_array
                elsif instruction(1 to len) = INSTR_LINES_APPEND_ARRAY then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not found"
                    severity failure;
                    stm_lines_append(var_stm_lines, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines append not successful"
                    severity failure;

                -- lines append a_lines "abc"
                -- lines append a_lines "abc{}" $a_varB
                elsif instruction(1 to len) = INSTR_LINES_APPEND_MESSAGE then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_text_substitude_wvar(defined_vars, txt, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels, var_stm_text_substituded);
                    var_stm_text_out := new stm_text;
                    stm_text_copy_to_ptr(var_stm_text_out, var_stm_text_substituded);
                    stm_lines_append(var_stm_lines, var_stm_text_out, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines append not successful"
                    severity failure;

                -- lines delete a_lines $position
                -- lines delete a_lines 13
                elsif instruction(1 to len) = INSTR_LINES_DELETE then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_lines_delete(var_stm_lines, to_integer(par2(30 downto 0)), valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines delete not successful"
                    severity failure;

                -- lines delete all a_lines
                elsif instruction(1 to len) = INSTR_LINES_DELETE_ALL then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    while var_stm_lines.size > 0 loop
                        temp_int := 0;
                        stm_lines_delete(var_stm_lines, temp_int, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines delete all not successful"
                        severity failure;
                    end loop;

                -- lines size a_lines read_size
                elsif instruction(1 to len) = INSTR_LINES_SIZE then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report "line_size error: not a valid variable??"
                    severity failure;
                    update_variable(defined_vars, par2, var_stm_lines.size, valid);

                --  lines pointer copy a_lines_target a_lines_source
                elsif instruction(1 to len) = INSTR_LINES_POINTER_COPY then
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    update_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report "lines_pointer error: not a lines object name??"
                    severity failure;
                                
                -- if $a_var_ref = $another_var
                -- if 0x09 = $another_var
                -- if $a_varA = 0x09
                -- if 0x09 = 0x09
                elsif instruction(1 to len) = INSTR_IF then
                    if_level := if_level + 1;
                    if_state(if_level) := false;
                    if trc_on(4) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  incremented if_level " & integer'image(if_level);
                    end if;
                    case to_integer(par2(30 downto 0)) is
                        when 0 => if (par1 = par3) then
                                if_state(if_level) := true;
                            end if;
                        when 1 => if (par1 > par3) then
                                if_state(if_level) := true;
                            end if;
                        when 2 => if (par1 < par3) then
                                if_state(if_level) := true;
                            end if;
                        when 3 => if (par1 /= par3) then
                                if_state(if_level) := true;
                            end if;
                        when 4 => if (par1 >= par3) then
                                if_state(if_level) := true;
                            end if;
                        when 5 => if (par1 <= par3) then
                                if_state(if_level) := true;
                            end if;
                        when others =>
                            assert false
                            report " line " & (integer'image(file_line)) & " error:  if instruction got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_str(file_line, dec)) & " in file " & text_line_crop(file_name)
                            severity failure;
                    end case;
                    if trc_on(4) = '1' then  
                        if if_state(if_level) = true then               
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) = false then
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                         par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                         last_sequ_num, last_sequ_ptr);
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 or (instruction(1 to len) /= INSTR_ELSE and instruction(1 to len) /= INSTR_ELSIF and instruction(1 to len) /= INSTR_END_IF) loop
                            if instruction(1 to len) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if instruction(1 to len) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert v_line < inst_sequ.num_of_lines
                            report " line " & (integer'image(file_line)) & " error:  if instruction unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                             par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                             last_sequ_num, last_sequ_ptr);
                        end loop;
                        if trc_on(4) = '1' then             
                            report instruction(1 to len) & ":  num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level));
                        end if;
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    end if;

                -- elsif $a_varA > $another_var
                -- 0x09 > $another_var
                -- $a_varA > 0x09
                -- elsif 0x0A > 0x09
                elsif instruction(1 to len) = INSTR_ELSIF then
                    if trc_on(4) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  if_level is " & integer'image(if_level);
                        if if_state(if_level) = true then               
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else 
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip to the end
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                         par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                         last_sequ_num, last_sequ_ptr);
                        while (instruction(1 to len) /= INSTR_IF) and instruction(1 to len) /= INSTR_END_IF loop
                            assert v_line < inst_sequ.num_of_lines
                            report " line " & (integer'image(file_line)) & " error:  if instruction unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                             par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                             last_sequ_num, last_sequ_ptr);
                        end loop;
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    else
                        case to_integer(par2(30 downto 0)) is
                            when 0 => if par1 = par3 then
                                    if_state(if_level) := true;
                                end if;
                            when 1 => if par1 > par3 then
                                    if_state(if_level) := true;
                                end if;
                            when 2 => if par1 < par3 then
                                    if_state(if_level) := true;
                                end if;
                            when 3 => if par1 /= par3 then
                                    if_state(if_level) := true;
                                end if;
                            when 4 => if par1 >= par3 then
                                    if_state(if_level) := true;
                                end if;
                            when 5 => if par1 <= par3 then
                                    if_state(if_level) := true;
                                end if;
                            when others =>
                                assert false
                                report " line " & (integer'image(file_line)) & " error:  elsif instruction got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_str(file_line, dec)) & " in file " & text_line_crop(file_name)
                                severity failure;
                        end case;
                        if trc_on(4) = '1' then  
                            if if_state(if_level) = true then               
                                report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is true";
                            else 
                                report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is false";
                            end if;
                        end if;
                        if if_state(if_level) = false then
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                             par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                             last_sequ_num, last_sequ_ptr);
                            num_of_if_in_false_if_leave(if_level) := 0;
                            while num_of_if_in_false_if_leave(if_level) /= 0 or (instruction(1 to len) /= INSTR_ELSE and instruction(1 to len) /= INSTR_ELSIF and instruction(1 to len) /= INSTR_END_IF) loop
                                if instruction(1 to len) = INSTR_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                                end if;
                                if instruction(1 to len) = INSTR_END_IF then
                                    num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                                end if;
                                assert v_line < inst_sequ.num_of_lines
                                report " line " & (integer'image(file_line)) & " error:  elsif instruction unable to find terminating" & lf & "    else, elsif or end_if statement."
                                severity failure;
                                v_line := v_line + 1;
                                access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                                 par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                                 last_sequ_num, last_sequ_ptr);
                            end loop;
                            if trc_on(4) = '1' then             
                                report instruction(1 to len) & ":  num_of_if_in_false_if_leave " & integer'image(num_of_if_in_false_if_leave(if_level));
                            end if;
                            v_line := v_line - 1; -- re-align so it will be operated on.
                        end if;
                    end if;

                -- else
                elsif instruction(1 to len) = INSTR_ELSE then
                    if trc_on(4) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  if_level is " & integer'image(if_level);
                        if if_state(if_level) = true then               
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is true";
                        else 
                            report instruction(1 to len) & ":  resolved if_state " & integer'image(if_level) & " is false";
                        end if;
                    end if;
                    if if_state(if_level) then -- if the if_state is true then skip the else
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                         par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                         last_sequ_num, last_sequ_ptr);                       
                        num_of_if_in_false_if_leave(if_level) := 0;
                        while num_of_if_in_false_if_leave(if_level) /= 0 or instruction(1 to len) /= INSTR_END_IF loop
                            if instruction(1 to len) = INSTR_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) + 1;
                            end if;
                            if instruction(1 to len) = INSTR_END_IF then
                                num_of_if_in_false_if_leave(if_level) := num_of_if_in_false_if_leave(if_level) - 1;
                            end if;
                            assert v_line < inst_sequ.num_of_lines
                            report " line " & (integer'image(file_line)) & " error:  else instruction unable to find terminating" & lf & "    end_if statement."
                            severity failure;
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                             par1, par2, par3, par4, par5, par6, txt, txt_enclosing_quote, len, file_name, file_line,
                                             last_sequ_num, last_sequ_ptr);
                        end loop;                        
                        
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    end if;

                -- end if
                elsif instruction(1 to len) = INSTR_END_IF then
                    if_level := if_level - 1;
                    if trc_on(4) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  decremented if_level " & integer'image(if_level);
                    end if;

                -- loop $loop_num
                -- loop 100
                elsif instruction(1 to len) = INSTR_LOOP then
                    stack_loop_if_enter_level(stack_ptr) := if_level;
                    act_loop_num := stack_loop_num(stack_ptr);
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  stack_ptr:" & integer'image(stack_ptr);
                        report instruction(1 to len) & ":  stack_loop_if_enter_level(" & integer'image(stack_ptr) & ")=" & integer'image(if_level);
                        report instruction(1 to len) & ":  act_loop_num: stack_loop_num(" & integer'image(stack_ptr) & ")=" & integer'image(act_loop_num);
                    end if;
                    act_loop_num := act_loop_num + 1;
                    stack_loop_num(stack_ptr) := act_loop_num;
                    stack_loop_line(stack_ptr)(act_loop_num) := v_line;
                    stack_curr_loop_count(stack_ptr)(act_loop_num) := 0;
                    stack_term_loop_count(stack_ptr)(act_loop_num) := to_integer(par1(30 downto 0));
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ":  incremented stack_loop_num(" & integer'image(stack_ptr) & ")=" & integer'image(act_loop_num);
                        report instruction(1 to len) & ":  set to goto v_line: stack_loop_line(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(v_line);
                        report instruction(1 to len) & ":  stack_curr_loop_count(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(stack_curr_loop_count(stack_ptr)(act_loop_num));
                        report instruction(1 to len) & ":  stack_term_loop_count(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(stack_term_loop_count(stack_ptr)(act_loop_num));
                    end if;

                -- end loop
                elsif instruction(1 to len) = INSTR_END_LOOP then
                    act_loop_num := stack_loop_num(stack_ptr);
                    act_curr_loop_count := stack_curr_loop_count(stack_ptr)(act_loop_num);
                    act_curr_loop_count := act_curr_loop_count + 1;
                    stack_curr_loop_count(stack_ptr)(act_loop_num) := act_curr_loop_count;
                    act_term_loop_count := stack_term_loop_count(stack_ptr)(act_loop_num);
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  stack_ptr:" & integer'image(stack_ptr);
                        report instruction(1 to len) & ":  act_loop_num: stack_loop_num(" & integer'image(stack_ptr) & ")=" & integer'image(act_loop_num);
                        report instruction(1 to len) & ":  set incremented stack_curr_loop_count(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_curr_loop_count);
                        report instruction(1 to len) & ":  stack_term_loop_count(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(act_term_loop_count);
                    end if;
                    if (act_curr_loop_count = act_term_loop_count) then
                        act_loop_num := act_loop_num - 1;
                        stack_loop_num(stack_ptr) := act_loop_num;
                        if trc_on(5) = '1' then
                            report instruction(1 to len) & ":  expired, set decremented stack_loop_num(" & integer'image(stack_ptr) & ")=" & integer'image(act_loop_num);
                        end if;
                    else
                        v_line := stack_loop_line(stack_ptr)(act_loop_num);
                        if trc_on(5) = '1' then
                            report instruction(1 to len) & ":  next goto v_line: stack_loop_line(" & integer'image(stack_ptr) & ") (" & integer'image(act_loop_num) & ")=" & integer'image(v_line);
                        end if;
                    end if;

                -- abort
                elsif instruction(1 to len) = INSTR_ABORT then
                    assert false
                    report "the test has aborted due to an error!!"
                    severity failure;
                    finish;

                -- finish
                elsif instruction(1 to len) = INSTR_FINISH then
                    expected_verify_failure_count := to_integer(unsigned(signals_out.out_signal_4(30 downto 0)));
                    expected_bus_timeout_failure_count := to_integer(unsigned(signals_out.out_signal_6(30 downto 0)));
                    report "Verify passes " & (integer'image(verify_passes_count));
                    report "Timeout monitored bus access passes " & (integer'image(bus_timeout_passes_count));
                    if expected_verify_failure_count /= 0 and expected_bus_timeout_failure_count /= 0 then                       
                        report "Expected " & (integer'image(expected_verify_failure_count)) & " verify failures, got " & (integer'image(verify_failure_count));
                        report "Expected " & (integer'image(expected_bus_timeout_failure_count)) & " bus timeout failures, got " & (integer'image(bus_timeout_failure_count));
                        if expected_verify_failure_count /= verify_failure_count then
                            report "FAILURES";
                            report "Test finished";
                            wait for 1000 ns;
                            finish;                     
                        end if;
                        if expected_bus_timeout_failure_count /= bus_timeout_failure_count then
                            report "FAILURES";
                            report "Test finished";
                            wait for 1000 ns;
                            finish;                         
                        end if;
                        report "SUCCESS";
                        wait for 1000 ns;
                        finish;                                                            
                    elsif expected_verify_failure_count /= 0 then
                        report "Expected " & (integer'image(expected_verify_failure_count)) & " verify failures, got " & (integer'image(verify_failure_count));
                        if expected_verify_failure_count /= verify_failure_count then
                            report "FAILURES";
                            report "Test finished";
                            wait for 1000 ns;
                            finish;                            
                        end if;
                        report "SUCCESS";
                        wait for 1000 ns;
                        finish;                                           
                    elsif expected_bus_timeout_failure_count /= 0 then
                        report "Expected " & (integer'image(expected_bus_timeout_failure_count)) & " bus timeout failures, got " & (integer'image(bus_timeout_failure_count));
                        if expected_bus_timeout_failure_count /= bus_timeout_failure_count then
                            report "FAILURES";
                            report "Test finished";
                            wait for 1000 ns;
                            finish;                         
                        end if;
                        report "SUCCESS";
                        wait for 1000 ns;
                        finish;                                                
                    end if;
                    report "SUCCESS";                                        
                    report "Test finished";
                    wait for 1000 ns;
                    finish;

                -- proc
                elsif instruction(1 to len) = INSTR_PROC then
                    null; -- no action necessary

                -- end proc
                -- end interrupt
                -- return
                elsif instruction(1 to len) = INSTR_RETURN or instruction(1 to len) = INSTR_END_PROC or instruction(1 to len) = INSTR_END_INTERRUPT then
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  stack_ptr:" & integer'image(stack_ptr);
                    end if;
                    act_loop_num := stack_loop_num(stack_ptr);
                    if act_loop_num > 0 then
                        if_level := stack_loop_if_enter_level(stack_ptr);
                        stack_loop_num(stack_ptr) := 0;
                    end if;
                    if stack_ptr = 0 then
                        report "Leaving proc Main and halt at line " & (integer'image(file_line)) & " " & instruction(1 to len) & " file " & text_line_crop(file_name);
                        wait;
                    end if;
                    assert stack_ptr >= 0
                    report " line " & (integer'image(file_line)) & " call error: stack under run??"
                    severity failure;
                    stack_ptr := stack_ptr - 1;
                    if interrupt_in_service > 0 then
                        interrupt_number := interrupt_number_entered_stack(interrupt_number_entered_stack_pointer);
                        if interrupt_entry_call_stack_ptr_stack(interrupt_number) = stack_ptr then
                            v_set_interrupt_in_service := '0';
                            set_interrupt_in_service(interrupt_in_service, interrupt_number, v_set_interrupt_in_service, signals_out);
                            interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer - 1;
                        end if;
                    end if;
                    -- report " line " & (integer'image(file_line)) & "return_call stack_ptr decremented to = " & integer'image(stack_ptr);
                    v_line := stack(stack_ptr);
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ":  if_level: stack_loop_if_enter_level(" & integer'image(stack_ptr) & ") = " & integer'image(if_level);
                        report instruction(1 to len) & ":  act_loop_num: stack_loop_num(" & integer'image(stack_ptr) & ") = " & integer'image(act_loop_num);
                        report instruction(1 to len) & ":  decremented stack_ptr:" & integer'image(stack_ptr);
                        report instruction(1 to len) & ":  set to goto v_line: stack(" & integer'image(stack_ptr) & ") = " & integer'image(v_line);
                    end if;
                    wait for 0 ns;

                -- call $some_proc
                elsif instruction(1 to len) = INSTR_CALL then
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ": v_line: " & integer'image(v_line) & ";  code line: " & (ew_to_str(file_line, dec)) & ";  file: " & text_line_crop(file_name);
                        report instruction(1 to len) & ":  stack_ptr:" & integer'image(stack_ptr);
                    end if;
                    assert stack_ptr < 31
                    report " line " & (integer'image(file_line)) & " call error: stack over run, calls to deeply nested!!"
                    severity failure;
                    stack(stack_ptr) := v_line;
                    get_inst_field_1(inst_sequ, v_line, called_label);
                    stack_called_labels(stack_ptr) := called_label;
                    stack_called_files(stack_ptr) := file_name;
                    stack_called_file_line_numbers(stack_ptr) := file_line; 
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ":  push v_line: stack(" & integer'image(stack_ptr) & ") = " & integer'image(v_line);
                    end if;
                    stack_ptr := stack_ptr + 1;
                    v_line := to_integer(par1(30 downto 0)) - 1;
                    if trc_on(5) = '1' then
                        report instruction(1 to len) & ":  incremented stack_ptr:" & integer'image(stack_ptr);
                        report instruction(1 to len) & ":  goto v_line:" & integer'image(v_line);
                    end if;

                -- log message $INFO "some message"
                -- log message  $INFO "misc_proc severity: {}" $INFO
                elsif instruction(1 to len) = INSTR_LOG_MESSAGE then
                    if par1 <= loglevel then
                        txt_print_wvar(defined_vars, txt, txt_enclosing_quote, stack_ptr, stack_called_files, stack_called_file_line_numbers, stack_called_labels);
                    end if;

                -- log lines $INFO a_lines
                elsif instruction(1 to len) = INSTR_LOG_LINES then
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    if par1 <= loglevel then
                        stm_lines_print(var_stm_lines, valid);
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object access"
                        severity failure;
                    end if;

                -- trace 1
                elsif instruction(1 to len) = INSTR_TRACE then
                    trc_on := par1;

                -- verbosity $INFO
                -- verbosity 25
                elsif instruction(1 to len) = INSTR_VERBOSITY then
                    loglevel := par1;

                -- resume ON_VERIFY (Flag Bit0) or BUS_TIMEOUT (Flag Bit1) failure
                -- if respective flag in resume value is set
                elsif instruction(1 to len) = INSTR_RESUME then
                   resume := par1;

                -- seed $seed_var
                -- seed 1397
                elsif instruction(1 to len) = INSTR_SEED then
                    assert par1 > 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": seed expects a positive values"
                    severity failure;
                    seed1 := to_integer(par1(30 downto 0));
                    if seed1 > 1 then
                        seed2 := seed1 - 1;
                    else
                        seed2 := seed1 + 42;
                    end if;

                -- random rand_var $rand_min_var $rand_max_var
                -- random rand_var 0 $rand_max_var
                -- random rand_var $rand_min_var 9
                -- random rand_var 3 9
                elsif instruction(1 to len) = INSTR_RANDOM then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    random(seed1, seed2, par2, par3, temp_stm_value);
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " random error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- wait $time_to_wait
                -- wait 10000
                elsif instruction(1 to len) = INSTR_WAIT then
                    wait for to_integer(par1(30 downto 0)) * 1 ns;

                -- marker 5 1 sets marker number 5 to high
                -- marker 7 0 sets marker number 7 to low
                elsif instruction(1 to len) = INSTR_MARKER then
                    if par1 < 16 then
                        for i in 0 to 15 loop
                            if par1 = i then
                                if par2 = 0 then
                                    temp_marker(i) := '0';
                                else
                                    temp_marker(i) := '1';
                                end if;
                            end if;
                        end loop;
                    else
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": 16 markers are provided only"
                        severity failure;
                    end if;
                    marker <= temp_marker;
                    wait for 0 ns;
                    
                -- var verify $a_var $var_expected_value $var_mask_value
                -- var verify $a_var 0x0002 0x00FF
                elsif instruction(1 to len) = INSTR_VAR_VERIFY then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    verify_passes_count := verify_passes_count + 1; 
                    if (par3 and temp_stm_value) /= (par3 and par2) then                            
                        if resume(0) = '0' then
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", var=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par2) & ", mask=0x" & to_hstring(par3) & ", file " & text_line_crop(file_name)                       
                            severity failure;
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", var=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par2) & ", mask=0x" & to_hstring(par3) & ", file " & text_line_crop(file_name)                       
                            severity error;
                            verify_failure_count := verify_failure_count + 1;                            
                        end if;
                    end if;

                -- signal write $a_signal $signal_to_be_set_value
                -- signal write $a_signal 0x1234
                elsif instruction(1 to len) = INSTR_SIGNAL_WRITE then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    signal_write(signals_out, to_integer(temp_stm_value(30 downto 0)), par2, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": signal not defined"
                    severity failure;
                    wait for 0 ns;

                -- signal read $a_signal signal_read_value
                -- signal verify $a_signal signal_read_value $signal_expected_value $signal_mask_value
                -- signal verify $a_signal signal_read_value 0x0002 0x00FF
                --  signal_read or signal_verify
                elsif instruction(1 to len) = INSTR_SIGNAL_VERIFY or instruction(1 to len) = INSTR_SIGNAL_READ then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    signal_read(signals_in, to_integer(temp_stm_value(30 downto 0)), temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": signal not defined"
                    severity failure;
                    update_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report "get_sig error: not a valid variable??"
                    severity failure;           
                    if (instruction(1 to len) = INSTR_SIGNAL_VERIFY) then
                        verify_passes_count := verify_passes_count + 1; 
                        if (par4 and temp_stm_value) /= (par4 and par3) then                            
                            if resume(0) = '0' then
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", read=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par3) & ", mask=0x" & to_hstring(par4) & ", file " & text_line_crop(file_name)                       
                                severity failure;
                            else
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", read=0x" & to_hstring(temp_stm_value) & ", expected=0x" & to_hstring(par3) & ", mask=0x" & to_hstring(par4) & ", file " & text_line_crop(file_name)                       
                                severity error;
                                verify_failure_count := verify_failure_count + 1;                            
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                --  signal pointer copy a_signal_target a_signal_source
                elsif instruction(1 to len) = INSTR_SIGNAL_POINTER_COPY then
                    index_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: signal object not found"
                    severity failure;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report "signal_pointer error: not a signal object name??"
                    severity failure;
                    
                --  signal pointer set a_signal_target a_var
                --  signal pointer set a_signal_target 0x01
                elsif instruction(1 to len) = INSTR_SIGNAL_POINTER_SET then
                    update_variable(defined_vars, par1, par2, valid);
                    assert valid /= 0
                    report "signal_pointer error: not a signal object name??"
                    severity failure;

                --  signal pointer get a_signal_source a_var
                elsif instruction(1 to len) = INSTR_SIGNAL_POINTER_GET then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: variable object not found"
                    severity failure;
                    update_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report "signal_pointer error: not a signal object name??"
                    severity failure;


                -- bus write $a_bus $bus_width  $bus_address $bus_to_be_set_value
                -- bus write $a_bus 16 0x00001000 0x1233
                elsif (instruction(1 to len) = INSTR_BUS_WRITE) then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    bus_write(bus_down, bus_up, par3, par4, to_integer(par2(30 downto 0)), to_integer(temp_stm_value(30 downto 0)), valid, successfull, bus_timeouts(to_integer(temp_stm_value(30 downto 0))));
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

                -- bus read  $a_bus $bus_width  $bus_address  bus_read_value
                -- bus read  $a_bus 16 0x00001000  bus_read_value
                -- bus verify $a_bus $bus_width  $bus_address bus_read_value $bus_expected_value $bus_mask_value
                -- bus verify $a_bus 32  0x00001004 bus_read_value 0x00050000 0x000FC000
                elsif instruction(1 to len) = INSTR_BUS_READ or instruction(1 to len) = INSTR_BUS_VERIFY then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stm_value_b := (others => '0');
                    bus_read(bus_down, bus_up, par3, temp_stm_value_b, to_integer(par2(30 downto 0)), to_integer(temp_stm_value(30 downto 0)), valid, successfull, bus_timeouts(to_integer(temp_stm_value(30 downto 0))));
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
                    update_variable(defined_vars, par4, temp_stm_value_b, valid);
                    if valid = 0 then
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                        severity failure;
                    end if;
                    if instruction(1 to len) = INSTR_BUS_VERIFY then
                        verify_passes_count := verify_passes_count + 1; 
                        if (par6 and temp_stm_value_b) /= (par6 and par5) then
                            if resume(0) = '0' then
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & " address=0x" & to_hstring(par3) & ", read=0x" & to_hstring(temp_stm_value_b) & ", expected=0x" & to_hstring(par5) & ", mask=0x" & to_hstring(par6) & ", file " & text_line_crop(file_name)
                                severity failure;
                            else
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & " address=0x" & to_hstring(par3) & ", read=0x" & to_hstring(temp_stm_value_b) & ", expected=0x" & to_hstring(par5) & ", mask=0x" & to_hstring(par6) & ", file " & text_line_crop(file_name)
                                severity error;
                                verify_failure_count := verify_failure_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                -- bus timeout $a_bus 1000
                -- bus timeout a_bus $bus_timeout_value
                elsif instruction(1 to len) = INSTR_BUS_TIMEOUT_SET then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    bus_timeouts(to_integer(temp_stm_value(30 downto 0))) := to_integer(par2(30 downto 0)) * 1 ns;
                    
                elsif instruction(1 to len) = INSTR_BUS_TIMEOUT_GET then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: bus object not found"
                    severity failure;
                    update_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report "variable error: not a var object name??"
                    severity failure;                          

                --  bus pointer copy a_file_target a_file_source
                elsif instruction(1 to len) = INSTR_BUS_POINTER_COPY then
                    index_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: bus object not found"
                    severity failure;
                    update_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report "bus_pointer error: not a bus object name??"
                    severity failure;
                    
                --  bus pointer set a_bus_target a_var
                --  bus pointer set a_bus_target 0x01
                elsif instruction(1 to len) = INSTR_BUS_POINTER_SET then
                    update_variable(defined_vars, par1, par2, valid);
                    assert valid /= 0
                    report "bus_pointer error: not a bus object name??"
                    severity failure;

                --  bus pointer get a_bus_source a_var
                elsif instruction(1 to len) = INSTR_BUS_POINTER_GET then
                    index_variable(defined_vars, par1, temp_stm_value, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: bus object not found"
                    severity failure;
                    update_variable(defined_vars, par2, temp_stm_value, valid);
                    assert valid /= 0
                    report "variable error: not a var object name??"
                    severity failure;                    

                -- undefined instructions
                else
                    assert false
                    report " line " & (integer'image(file_line)) & " error:  seems the command  " & ", " & instruction(1 to len) & " was defined but" & lf & "was not found in the elsif chain, please check spelling."
                    severity failure;
                end if;

            end if;

        end loop;

        assert false
        report lf & "the end of the simulation! it was not terminated as expected." & lf
        severity failure;

    end process;
end;
