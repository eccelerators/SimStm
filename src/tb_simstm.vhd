library std;
use std.textio.all;

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
        user_file_folder_path : in string := ""
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        simdone : out std_logic;
        executing_line : out integer;
        executing_file : out text_line;
        marker : out std_logic_vector(15 downto 0);
        signals_out : out t_signals_out;
        signals_in : in t_signals_in := signals_in_init;
        bus_down : out t_bus_down;
        bus_up : in t_bus_up := bus_up_init
    );
end;

architecture behavioural of tb_simstm is
    signal rstneg : std_logic;

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
    rstneg <= not rst;
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
        variable par1 : integer; -- parameter 1
        variable par2 : integer; -- parameter 2
        variable par3 : integer; -- parameter 3
        variable par4 : integer; -- parameter 4
        variable par5 : integer; -- parameter 5
        variable par6 : integer; -- parameter 6
        variable txt : stm_text_ptr;
        variable len : integer; -- length of the instruction field
        variable file_line : integer; -- line number in the stimulus file
        variable file_name : text_line; -- the file name the line came from
        variable v_line : integer := 0; -- sequence number
        variable stack : stack_register; -- call stack
        variable stack_ptr : integer := 0; -- call stack pointer
        variable act_loop_num : integer := 0;
        variable act_curr_loop_count : integer := 0;
        variable act_term_loop_count : integer := 0;
        variable stack_loop_num : int_array := (others => 0);
        variable stack_curr_loop_count : int_array_array := (others => (others => 0));
        variable stack_term_loop_count : int_array_array := (others => (others => 0));
        variable stack_loop_line : int_array_array := (others => (others => 0));
        variable stack_loop_if_enter_level : int_array := (others => 0);

        variable loglevel : integer := 0;
        variable exit_on_verify_error : boolean := true;
        variable error_count : integer := 0;
        variable if_level : integer := 0;
        variable loop_if_enter_level : integer := 0;
        variable if_state : boolean_array := (others => false);
        variable num_of_if_in_false_if_leave : int_array := (others => 0);
        variable valid : integer;
        variable interrupt_number_entered_stack_pointer : integer := -1;
        variable interrupt_number_entered_stack : int_array := (others => 0);
        variable interrupt_entry_call_stack_ptr_stack : int_array := (others => 0);

        variable successfull : boolean := false;

        -- random generator seed variables
        variable seed1 : positive := 1;
        variable seed2 : positive := 1;

        --  scratchpad variables
        variable tempaddress : std_logic_vector(31 downto 0);
        variable tempdata : std_logic_vector(31 downto 0);
        variable temp_int : integer;
        variable number_found : integer;

        variable temp_stdvec_a : std_logic_vector(31 downto 0);
        variable temp_stdvec_b : std_logic_vector(31 downto 0);
        variable temp_stdvec_c : std_logic_vector(31 downto 0);

        variable trc_on : boolean := false;

        file stimulus : text; -- file main file
        variable v_stat : file_open_status;

        -- Bus
        type bus_timeout_array is array (0 to 127) of time;
        variable bus_timeouts : bus_timeout_array := (others => 1 sec);

        -- Array
        variable var_stm_array : t_stm_array_ptr;

        -- Text
        variable var_stm_text : stm_text_ptr;
        variable var_stm_text_out : stm_text_ptr;
        variable var_stm_text_substituded : stm_text;       

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
        variable user_file_number : integer; 
        variable user_files_used : integer := 0;    
        variable user_v_stat : file_open_status;
        variable user_file_path_string : stm_text;
        variable user_file_append_done : boolean;
        variable user_file_open_done : boolean;
        variable user_std_line : line;
        variable stm_lines_append_valid : integer := 0;
        
        -- Lines
        variable var_stm_lines : t_stm_lines_ptr;
        variable var_stm_lines_ptr : t_stm_lines_ptr;
        variable var_stm_line_ptr : t_stm_line_ptr;

        variable main_label_text_field : text_field;
        variable main_label_string : string(1 to 5) := "$Main";
        variable main_line : integer := 0;
        variable main_entered : integer := 0;

        variable interrupt_requests : unsigned(number_of_interrupts-1 downto 0) := (others => '0');
        variable interrupt_in_service : unsigned(number_of_interrupts-1 downto 0) := (others => '0');

        variable interrupt_number : integer := 0;
        variable branch_to_interrupt : boolean := false;
        variable branch_to_interrupt_label : text_field;
        variable branch_to_interrupt_label_std_txt_io_line : line;
        variable branch_to_interrupt_v_line : integer := 0;

    begin
        simdone <= '0';
        marker <= (others => '0');

        init_text_field(main_label_string, main_label_text_field);

        signals_out <= signals_out_init;
        bus_down <= bus_down_init;

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

            get_interrupt_requests(signals_in, interrupt_requests);

            if main_entered = 0 then

                access_variable(defined_vars, main_label_text_field, main_line, valid);
                assert valid = 1
                report lf & "error: Entry point proc Main not found !" 
                severity failure;
                v_line := main_line;
                main_entered := 1;

            elsif interrupt_requests > 0 then

                resolve_interrupt_requests(interrupt_requests, interrupt_in_service, interrupt_number, branch_to_interrupt, branch_to_interrupt_label_std_txt_io_line);

                if branch_to_interrupt then
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

                    set_interrupt_in_service(interrupt_in_service, interrupt_number);

                    stack(stack_ptr) := v_line;
                    stack_ptr := stack_ptr + 1;
                    -- report " line " & (integer'image(file_line)) & "call stack_ptr incremented to = " & integer'image(stack_ptr);
                    line_to_text_field(branch_to_interrupt_label_std_txt_io_line, branch_to_interrupt_label);
                    access_variable(defined_vars, branch_to_interrupt_label, branch_to_interrupt_v_line, valid);
                    assert valid = 1
                    report lf & "error: Interrupt entry point $branch_to_interrupt_label not found !" 
                    severity failure;
                    v_line := branch_to_interrupt_v_line;

                end if;

            else

                v_line := v_line + 1;
                access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                    par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                    last_sequ_num, last_sequ_ptr);

                -- dump_variables(defined_vars);                
                -- print_inst(inst_sequ, v_line, file_list);    

                Executing_Line <= file_line;
                Executing_File <= file_name;
                wait for 100 ps;

                if trc_on then
                    report "exec line " & (integer'image(file_line)) & " " & instruction(1 to len) & " file " & file_name;
                end if;

                -- include "an_include.stm"
                if instruction(1 to len) = INSTR_INCLUDE then
                    null; -- This instruction was implemented while reading the file
                    -- 
                -- const a_const_num #x03
                -- const a_constB $a_constA
                -- const a_constC $a_varA
                elsif instruction(1 to len) = INSTR_CONST then
                    null; -- This instruction was implemented while reading the file

                -- var a_varA #x05
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
                -- equ operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_EQU then
                    update_variable(defined_vars, par1, par2, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " equ error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- equ operand1_and_target $operand2
                -- add operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_ADD then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add error: not a valid variable??"
                    severity failure;
                    temp_int := temp_int + par2;
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " add error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- equ operand1_and_target $operand2
                -- sub operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_SUB then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub error: not a valid variable??"
                    severity failure;                    
                    temp_int := temp_int - par2;
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " sub error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- mul operand1_and_target $operand2
                -- mul operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_MUL then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_int := temp_int * par2;
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- div operand1_and_target $operand2
                -- div operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_DIV then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    if temp_int < 0 then
                        temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                        temp_stdvec_c := not temp_stdvec_a;
                        temp_int := to_integer(signed(temp_stdvec_c));
                        temp_int := temp_int / par2;
                        temp_stdvec_a := std_logic_vector(to_signed((temp_int), 32));
                        temp_stdvec_c := not temp_stdvec_a;
                        temp_int := to_integer(signed(temp_stdvec_c));
                    else
                        temp_int := temp_int / par2;
                    end if;
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " div error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- and operand1_and_target $operand2
                -- and operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_AND then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                    temp_stdvec_b := std_logic_vector(to_signed(par2, 32));
                    temp_stdvec_c := temp_stdvec_a and temp_stdvec_b;
                    temp_int := to_integer(signed(temp_stdvec_c));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " and error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- or operand1_and_target $operand2
                -- or operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_OR then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                    temp_stdvec_b := std_logic_vector(to_signed(par2, 32));
                    temp_stdvec_c := temp_stdvec_a or temp_stdvec_b;
                    temp_int := to_integer(signed(temp_stdvec_c));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " or error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- xor operand1_and_target $operand2
                -- xor operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_XOR then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                    temp_stdvec_b := std_logic_vector(to_signed(par2, 32));
                    temp_stdvec_c := temp_stdvec_a xor temp_stdvec_b;
                    temp_int := to_integer(signed(temp_stdvec_c));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " xor error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- shl operand1_and_target $operand2
                -- shl operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_SHL then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_int := to_integer(shift_left(to_signed(temp_int, 32), par2));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- shr operand1_and_target $operand2
                -- shr operand1_and_target #xF0
                elsif instruction(1 to len) = INSTR_SHR then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_int := to_integer(shift_right(to_signed(temp_int, 32), par2));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " mul error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- inv operand1_and_target
                elsif instruction(1 to len) = INSTR_INV then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                    temp_stdvec_c := not temp_stdvec_a;
                    temp_int := to_integer(signed(temp_stdvec_c));
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " inv error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- ld operand1_and_target
                elsif instruction(1 to len) = INSTR_LD then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_int := ld(temp_int);
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " ld error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- array set an_array $array_position #x07
                -- array set an_array $array_position $a_varA
                -- array set an_array 5 #x07
                -- array set an_array 3 $a_varA
                elsif instruction(1 to len) = INSTR_ARRAY_SET then
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    assert var_stm_array'length > par2
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: index is out of array size"
                    severity failure;
                    var_stm_array(par2) := par3;

                -- array get an_array $array_position a_varB
                elsif instruction(1 to len) = INSTR_ARRAY_GET then
                    index_variable(defined_vars, par1, var_stm_array, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array not found"
                    severity failure;
                    assert var_stm_array'length > par2
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: index is out of array size"
                    severity failure;                       
                    temp_int := var_stm_array(par2);
                    update_variable(defined_vars, par3, temp_int, valid);
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
                    temp_int := var_stm_array'length;
                    update_variable(defined_vars, par2, temp_int, valid);
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
                    
                -- file readable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_READABLE then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_file_readable(var_stm_text, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;
                    
                -- file writeable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_WRITEABLE then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_file_writeable(var_stm_text, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- file appendable a_fileA target
                elsif instruction(1 to len) = INSTR_FILE_APPENDABLE then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    stm_file_appendable(var_stm_text, temp_int);
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- file write a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_WRITE then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_file_write(var_stm_lines, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file write not successful"
                    severity failure;

                -- file append a_fileB  a_lines                    
                elsif instruction(1 to len) = INSTR_FILE_APPEND then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_file_append(var_stm_lines, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file append not successful"
                    severity failure;

                -- file read a_fileA a_lines $number_of_lines
                -- file read a_fileA a_lines 256
                elsif instruction(1 to len) = INSTR_FILE_READ then
                    index_variable(defined_vars, par1, var_stm_text, valid);
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
                            readline(user_file_0, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;
                            user_file_append_done := true;
                        end if;
                    end if; 
                    if user_file_in_use_1 then
                        if var_stm_text = user_file_name_1 then
                            readline(user_file_1, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_2 then
                        if var_stm_text = user_file_name_2 then
                            readline(user_file_2, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;
                            user_file_append_done := true;
                        end if;
                    end if;
                    if user_file_in_use_3 then
                        if var_stm_text = user_file_name_3 then
                            readline(user_file_3, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;
                            user_file_append_done := true;
                        end if;
                    end if;
                    -- if file is not in use, try to open and use it
                    if not user_file_append_done then                        
                        txt_to_string(var_stm_text, user_file_path_string);
                        user_file_open_done := false;
                        if not user_file_in_use_0 and not user_file_open_done then
                            file_open(v_stat, user_file_0, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_0 := var_stm_text;
                            user_file_in_use_0 := true;
                            readline(user_file_0, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;                           
                        elsif not user_file_in_use_1 and not user_file_open_done then
                            file_open(v_stat, user_file_1, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_1 := var_stm_text;
                            user_file_in_use_1 := true;
                            readline(user_file_1, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;                            
                        elsif not user_file_in_use_2 and not user_file_open_done then
                            file_open(v_stat, user_file_2, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_2 := var_stm_text;
                            user_file_in_use_2 := true;
                            readline(user_file_2, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;                           
                        elsif not user_file_in_use_3 and not user_file_open_done then
                            file_open(v_stat, user_file_3, stm_text_crop(user_file_path_string), read_mode);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                            severity failure;
                            user_file_name_3 := var_stm_text;
                            user_file_in_use_3 := true;
                            readline(user_file_3, user_std_line);
                            stm_lines_append(var_stm_lines, user_std_line, stm_lines_append_valid);
                            assert valid /= 0
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: line couldn't be appended"
                            severity failure;                           
                        else
                            assert false
                            report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: only 4 files are allowed for file read concurrently"
                            severity failure;                        
                        end if;               
                    end if;
                    
                -- file read end a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_READ_END then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    if var_stm_text = user_file_name_0 and user_file_in_use_0 then
                        file_close(user_file_0);
                        user_file_in_use_0 := false;
                    elsif var_stm_text = user_file_name_1 and user_file_in_use_1 then
                        file_close(user_file_1);
                        user_file_in_use_1 := false;  
                    elsif var_stm_text = user_file_name_2 and user_file_in_use_2 then
                        file_close(user_file_2);
                        user_file_in_use_2 := false;                
                    elsif var_stm_text = user_file_name_3 and user_file_in_use_3 then
                        file_close(user_file_3);
                        user_file_in_use_3 := false;                        
                    else
                        assert valid /= 0
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: trying to end file not started or already ended for read"
                        severity failure;                                           
                    end if;                      
                    
                -- file read all a_fileA a_lines
                elsif instruction(1 to len) = INSTR_FILE_READ_ALL then
                    index_variable(defined_vars, par1, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file object not found"
                    severity failure;
                    index_variable(defined_vars, par2, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: position object not found"
                    severity failure;
                    stm_file_read_all(var_stm_lines, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: file read not successful"
                    severity failure;
                                 
                -- lines get a_lines $position an_array number_found
                -- lines get a_lines 8 an_array number_found              
                elsif instruction(1 to len) = INSTR_LINES_GET_ARRAY then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    index_variable(defined_vars, par3, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    stm_lines_get(var_stm_lines, par2, var_stm_array, number_found, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: array object not get successfully"
                    severity failure;
                    update_variable(defined_vars, par3, number_found, valid);
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
                    stm_lines_set(var_stm_lines, par2, var_stm_array, valid);
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
                    index_variable(defined_vars, par3, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: message object not found"
                    severity failure;
                    stm_lines_set(var_stm_lines, par2, var_stm_text, valid);
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
                    stm_lines_insert(var_stm_lines, par2, var_stm_array, valid);
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
                    index_variable(defined_vars, par3, var_stm_text, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: message object not found"
                    severity failure;
                    stm_lines_insert(var_stm_lines, par2, var_stm_text, valid);
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
                    stm_text_substitude_wvar(defined_vars, txt, var_stm_text_substituded, hex);
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
                    stm_lines_delete(var_stm_lines, par2, valid);               
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines delete not successful"
                    severity failure;
                    
                -- lines delete all a_lines
                elsif instruction(1 to len) = INSTR_LINES_DELETE_ALL then
                    index_variable(defined_vars, par1, var_stm_lines, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & " error: lines object not found"
                    severity failure;
                    for i in 0 to var_stm_lines.size - 1 loop
                        temp_int := i;
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
                -- if #x09 = $another_var
                -- if $a_varA = #x09
                -- if #x09 = #x09
                elsif instruction(1 to len) = INSTR_IF then
                    if_level := if_level + 1;
                    --    assert false
                    --    report " line " & (integer'image(file_line)) & " executing if command" & lf & "  if_level incremented to " & ht & integer'image(if_level)
                    --    severity note;
                    if_state(if_level) := false;
                    case par2 is
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
                            report " line " & (integer'image(file_line)) & " error:  if instruction got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_str(file_line, dec)) & " in file " & file_name
                            severity failure;
                    end case;
                    if if_state(if_level) = false then
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                            par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
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
                                par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                                last_sequ_num, last_sequ_ptr);
                        end loop;
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    end if;

                -- elsif $a_varA > $another_var
                -- #x09 > $another_var
                -- $a_varA > #x09
                -- elsif #x0A > #x09
                elsif instruction(1 to len) = INSTR_ELSIF then
                    if if_state(if_level) = true then -- if the if_state is true then skip to the end
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                            par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                            last_sequ_num, last_sequ_ptr);
                        while (instruction(1 to len) /= INSTR_IF) and instruction(1 to len) /= INSTR_END_IF loop
                            assert v_line < inst_sequ.num_of_lines
                            report " line " & (integer'image(file_line)) & " error:  if instruction unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                                last_sequ_num, last_sequ_ptr);
                        end loop;
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    else
                        case par2 is
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
                                report " line " & (integer'image(file_line)) & " error:  elsif instruction got an unexpected value" & lf & "  in parameter 2!" & lf & "found on line " & (ew_to_str(file_line, dec)) & " in file " & file_name
                                severity failure;
                        end case;
                        if if_state(if_level) = false then
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
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
                                    par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                                    last_sequ_num, last_sequ_ptr);
                            end loop;
                            v_line := v_line - 1; -- re-align so it will be operated on.
                        end if;
                    end if;

                -- else
                elsif instruction(1 to len) = INSTR_ELSE then
                    if if_state(if_level) = true then -- if the if_state is true then skip the else
                        v_line := v_line + 1;
                        access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                            par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                            last_sequ_num, last_sequ_ptr);
                        while instruction(1 to len) /= INSTR_IF and instruction(1 to len) /= INSTR_END_IF loop
                            assert v_line < inst_sequ.num_of_lines
                            report " line " & (integer'image(file_line)) & " error:  if instruction unable to find terminating" & lf & "    else, elsif or end_if statement."
                            severity failure;
                            v_line := v_line + 1;
                            access_inst_sequ(inst_sequ, defined_vars, file_list, v_line, instruction,
                                par1, par2, par3, par4, par5, par6, txt, len, file_name, file_line,
                                last_sequ_num, last_sequ_ptr);
                        end loop;
                        v_line := v_line - 1; -- re-align so it will be operated on.
                    end if;

                -- end if
                elsif instruction(1 to len) = INSTR_END_IF then
                    if_level := if_level - 1;
                    -- assert false
                    -- report " line " & (integer'image(file_line)) & " executing end_if command" & lf & "  if_level decremented to " & ht & integer'image(if_level)
                    -- severity note;

                -- loop $loop_num
                -- loop 100
                elsif instruction(1 to len) = INSTR_LOOP then
                    stack_loop_if_enter_level(stack_ptr + 1) := if_level;
                    act_loop_num := stack_loop_num(stack_ptr + 1);
                    act_loop_num := act_loop_num + 1;
                    stack_loop_num(stack_ptr + 1) := act_loop_num;
                    stack_loop_line(stack_ptr + 1)(act_loop_num) := v_line;
                    stack_curr_loop_count(stack_ptr + 1)(act_loop_num) := 0;
                    stack_term_loop_count(stack_ptr + 1)(act_loop_num) := par1;
                    -- assert false
                    -- report " line " & (integer'image(file_line)) & " executing loop command" & lf & "  nested loop:" & ht & integer'image(act_loop_num) & lf & "  loop length:" & ht & integer'image(par1)
                    -- severity note;

                -- end loop
                elsif instruction(1 to len) = INSTR_END_LOOP then
                    act_loop_num := stack_loop_num(stack_ptr + 1);
                    act_curr_loop_count := stack_curr_loop_count(stack_ptr + 1)(act_loop_num);
                    act_curr_loop_count := act_curr_loop_count + 1;
                    stack_curr_loop_count(stack_ptr + 1)(act_loop_num) := act_curr_loop_count;
                    act_term_loop_count := stack_term_loop_count(stack_ptr + 1)(act_loop_num);
                    if (act_curr_loop_count = act_term_loop_count) then
                        act_loop_num := act_loop_num - 1;
                        stack_loop_num(stack_ptr + 1) := act_loop_num;
                    else
                        v_line := stack_loop_line(stack_ptr + 1)(act_loop_num);
                    end if;

                -- abort
                elsif instruction(1 to len) = INSTR_ABORT then
                    simdone <= '1';
                    assert false
                    report "the test has aborted due to an error!!"
                    severity failure;
                    wait;

                -- finish
                elsif instruction(1 to len) = INSTR_FINISH then
                    simdone <= '1';
                    assert error_count /= 0
                    report "test finished with no errors!!"
                    severity note;
                    assert error_count = 0
                    report "test finished with " & (integer'image(error_count)) & " errors!!"
                    severity error;
                    wait;

                -- proc
                elsif instruction(1 to len) = INSTR_PROC then
                    null; -- no action necessary

                -- end proc
                -- end interrupt
                -- return
                elsif instruction(1 to len) = INSTR_RETURN or instruction(1 to len) = INSTR_END_PROC or instruction(1 to len) = INSTR_END_INTERRUPT then
                    act_loop_num := stack_loop_num(stack_ptr);
                    if act_loop_num > 0 then
                        if_level := stack_loop_if_enter_level(stack_ptr);
                    end if;
                    if stack_ptr = 0 then
                        report "Leaving proc Main and halt at line " & (integer'image(file_line)) & " " & instruction(1 to len) & " file " & file_name;
                        wait;
                    end if;
                    assert stack_ptr <= 0
                    report " line " & (integer'image(file_line)) & " call error: stack under run??"
                    severity failure;
                    stack_ptr := stack_ptr - 1;
                    if interrupt_in_service > 0 then
                        interrupt_number :=  interrupt_number_entered_stack(interrupt_number_entered_stack_pointer);
                        if interrupt_entry_call_stack_ptr_stack(interrupt_number) = stack_ptr then
                            reset_interrupt_in_service(interrupt_in_service, interrupt_number);
                            interrupt_number_entered_stack_pointer := interrupt_number_entered_stack_pointer - 1;
                        end if;
                    end if;
                    -- report " line " & (integer'image(file_line)) & "return_call stack_ptr decremented to = " & integer'image(stack_ptr);
                    v_line := stack(stack_ptr);

                -- call $some_proc 
                elsif instruction(1 to len) = INSTR_CALL then
                    assert stack_ptr < 31
                    report " line " & (integer'image(file_line)) & " call error: stack over run, calls to deeply nested!!"
                    severity failure;
                    stack(stack_ptr) := v_line;
                    stack_ptr := stack_ptr + 1;
                    -- report " line " & (integer'image(file_line)) & "call stack_ptr incremented to = " & integer'image(stack_ptr);
                    v_line := par1 - 1;

                -- log message $INFO "some message"
                -- log message  $INFO "misc_proc severity: {}" $INFO 
                elsif instruction(1 to len) = INSTR_LOG_MESSAGE then
                    if par1 <= loglevel then
                        txt_print_wvar(defined_vars, txt, hex);
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
                    if par1 /= 0 then
                        trc_on := true;
                    else
                        trc_on := false;
                    end if;

                -- verbosity $INFO
                -- verbosity 25
                elsif instruction(1 to len) = INSTR_VERBOSITY then
                    loglevel := par1;

                -- resume $RESUME_ON_VERIFY_ERROR
                -- resume $EXIT_ON_VERIFY_ERROR
                elsif instruction(1 to len) = INSTR_RESUME then
                    if par1 = 0 then
                        exit_on_verify_error := true;
                    else
                        exit_on_verify_error := false;
                    end if;

                -- seed $seed_var
                -- seed 1397
                elsif instruction(1 to len) = INSTR_SEED then
                    assert par1 > 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": seeds must allow only positive values"
                    severity failure;
                    temp_int := 0;
                    seed1 := par1;
                    seed2 := 1;
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " random_seed error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- random rand_var $rand_min_var $rand_max_var
                -- random rand_var 0 $rand_max_var
                -- random rand_var $rand_min_var 9
                -- random rand_var 3 9
                elsif instruction(1 to len) = INSTR_RANDOM then
                    index_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                    severity failure;
                    temp_int := 0;
                    getrandint(seed1, seed2, par2, par3, temp_int);
                    update_variable(defined_vars, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & " random error: cannot update variable, it may be a constant ?"
                    severity failure;

                -- wait $time_to_wait
                -- wait 10000
                elsif instruction(1 to len) = INSTR_WAIT then
                    wait for par1 * 1 ns;

                -- marker 5 1 sets marker number 5 to high
                -- marker 7 0 sets marker number 7 to low
                elsif instruction(1 to len) = INSTR_MARKER then
                    if par1 < 16 then
                        for i in 0 to 15 loop
                            if par1 = i then
                                if par2 = 0 then
                                    marker(i) <= '0';
                                else
                                    marker(i) <= '1';
                                end if;
                            end if;
                        end loop;
                    else
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": 16 markers are provided only"
                        severity failure;
                    end if;
                    wait for 0 ns;

                -- signal write $a_signal $signal_to_be_set_value
                -- signal write $a_signal #x1234
                elsif instruction(1 to len) = INSTR_SIGNAL_WRITE then
                    signal_write(signals_out, par1, par2, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": signal not defined"
                    severity failure;
                    wait for 0 ns;

                -- signal read $a_signal signal_read_value
                -- signal verify $a_signal signal_read_value $signal_expected_value $signal_mask_value
                -- signal verify $a_signal signal_read_value #x0002 #x00FF               --  signal_read or signal_verify
                elsif instruction(1 to len) = INSTR_SIGNAL_VERIFY or instruction(1 to len) = INSTR_SIGNAL_READ then
                    signal_read(signals_in, par1, temp_int, valid);
                    assert valid /= 0
                    report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": signal not defined"
                    severity failure;
                    update_variable(defined_vars, par2, temp_int, valid);
                    assert valid /= 0
                    report "get_sig error: not a valid variable??"
                    severity failure;
                    if (instruction(1 to len) = INSTR_SIGNAL_VERIFY) then
                        temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                        temp_stdvec_b := std_logic_vector(to_signed(par3, 32));
                        temp_stdvec_c := std_logic_vector(to_signed(par4, 32));
                        assert (temp_stdvec_c and temp_stdvec_a) = (temp_stdvec_c and temp_stdvec_b)
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & ", read=0x" & to_hstring(temp_stdvec_a) & ", expected=0x" & to_hstring(temp_stdvec_b) & ", mask=0x" & to_hstring(temp_stdvec_c) & " file " & file_name
                        severity failure;
                    end if;
                    wait for 0 ns;

                -- bus write $a_bus $bus_width  $bus_address $bus_to_be_set_value
                -- bus write $a_bus 16 #x00001000 #x1233
                elsif (instruction(1 to len) = INSTR_BUS_WRITE) then
                    tempaddress := std_logic_vector(to_signed(par3, tempaddress'length));
                    tempdata := std_logic_vector(to_signed(par4, tempdata'length));
                    bus_write(clk, bus_down, bus_up, tempaddress, tempdata, par2, par1, valid, successfull, bus_timeouts(par1));
                    assert valid /= 0
                    report "Bus number not avalible"
                    severity failure;
                    assert successfull
                    report "Bus Read timeout"
                    severity failure;
                    wait for 0 ns;

                -- bus read  $a_bus $bus_width  $bus_address  bus_read_value
                -- bus read  $a_bus 16 #x00001000  bus_read_value
                -- bus verify $a_bus $bus_width  $bus_address bus_read_value $bus_expected_value $bus_mask_value
                -- bus verify $a_bus 32  #x00001004 bus_read_value #x00050000 #x000FC000
                elsif instruction(1 to len) = INSTR_BUS_READ or instruction(1 to len) = INSTR_BUS_VERIFY then
                    temp_stdvec_a := std_logic_vector(to_signed(par3, tempaddress'length));
                    temp_stdvec_b := (others => '0');
                    bus_read(clk, bus_down, bus_up, temp_stdvec_a, temp_stdvec_b, par2, par1, valid, successfull, bus_timeouts(par1));
                    assert valid /= 0
                    report "Bus number not avalible"
                    severity failure;
                    assert successfull
                    report "Bus Read timeout"
                    severity failure;
                    temp_int := to_integer(signed(temp_stdvec_b));
                    update_variable(defined_vars, par4, temp_int, valid);
                    if valid = 0 then
                        assert false
                        report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ": not a valid variable??"
                        severity failure;
                    end if;
                    if instruction(1 to len) = INSTR_BUS_VERIFY then
                        temp_stdvec_a := std_logic_vector(to_signed(temp_int, 32));
                        temp_stdvec_b := std_logic_vector(to_signed(par5, 32));
                        temp_stdvec_c := std_logic_vector(to_signed(par6, 32));
                        if (temp_stdvec_c and temp_stdvec_a) /= (temp_stdvec_c and temp_stdvec_b) then
                            if exit_on_verify_error then
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & " address=0x" & to_hstring(tempaddress) & ", read=0x" & to_hstring(temp_stdvec_a) & ", expected=0x" & to_hstring(temp_stdvec_b) & ", mask=0x" & to_hstring(temp_stdvec_c)
                                severity failure;
                            else
                                assert false
                                report " line " & (integer'image(file_line)) & ", " & instruction(1 to len) & ":" & " address=0x" & to_hstring(tempaddress) & ", read=0x" & to_hstring(temp_stdvec_a) & ", expected=0x" & to_hstring(temp_stdvec_b) & ", mask=0x" & to_hstring(temp_stdvec_c)
                                severity error;
                                error_count := error_count + 1;
                            end if;
                        end if;
                    end if;
                    wait for 0 ns;

                -- bus timeout $a_bus 1000
                -- bus timeout a_bus $bus_timeout_value
                elsif instruction(1 to len) = INSTR_BUS_TIMEOUT then
                    bus_timeouts(par1) := par2 * 1 ns;

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
