library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_pkg_base is

    -- constants
    constant max_str_len : integer := 256;
    constant max_field_len : integer := 128;
    constant c_stm_text_len : integer := 200;
    -- file handles
    file stimulus : text; -- file main file
    file include_file : text; -- file declaration for includes

    -- type def's
    type base is (bin, oct, hex, dec);
    --  subtype stack_element is integer range 0 to 8192;
    type stack_register is array (31 downto 0) of integer;
    type state_register is array (7 downto 0) of boolean;
    type int_array is array (1 to 128) of integer;
    type int_array_array is array (1 to 16) of int_array;
    type boolean_array is array (0 to 127) of boolean;
    
    subtype text_field is string(1 to max_field_len);
    subtype text_line is string(1 to max_str_len);
    subtype stm_text is string(1 to c_stm_text_len);
    type stm_text_ptr is access stm_text;

    -- define the stimulus line record and access
    type stim_line;
    type stim_line_ptr is access stim_line; -- pointer to stim_line record
    type stim_line is record
        instruction : text_field;
        inst_field_1 : text_field;
        inst_field_2 : text_field;
        inst_field_3 : text_field;
        inst_field_4 : text_field;
        inst_field_5 : text_field;
        inst_field_6 : text_field;
        txt : stm_text_ptr;
        line_number : integer; -- sequence line
        num_of_lines : integer; -- total number of lines
        file_line : integer; -- file line number
        file_idx : integer;
        next_rec : stim_line_ptr;
    end record;

    -- define the variables field and pointer
    type var_field;
    type var_field_ptr is access var_field; -- pointer to var_field
    type var_field is record
        var_name : text_field;
        var_index : integer;
        var_value : integer;
        var_array : t_array_object_ptr;
        var_file : text_field;
        var_lines : t_lines_object_ptr;
        const : boolean;
        next_rec : var_field_ptr;
    end record;
    -- define the instruction structure
    type inst_def;
    type inst_def_ptr is access inst_def;
    type inst_def is record
        instruction : text_field;
        instruction_l : integer;
        params : integer;
        next_rec : inst_def_ptr;
    end record;
    -- define the file handle record
    type file_def;
    type file_def_ptr is access file_def;
    type file_def is record
        rec_idx : integer;
        file_name : text_line;
        next_rec : file_def_ptr;
    end record;

    type t_array_object is array (natural range <>) of integer;
    type t_array_object_ptr is access t_array_object;

    type t_lines_object is record
        lines : t_line_object;
        size : integer;
    end record;
    type t_lines_object_ptr is access t_lines_object;
    
    type t_line_object is record
        line_content : line;
        line_number : integer;
        next_line_object_ptr : t_line_object_ptr;
    end record;
    type t_line_object_ptr is access t_line_object;
    

    procedure file_read(variable lines_object : inout t_lines_object;
                          variable file_path : in text_field;
                          variable valid : out integer);
                          
    procedure file_write(variable lines_object : out t_lines_object;
                          variable file_path : in text_field;
                          variable valid : out integer);
                                           
    procedure file_append(variable lines_object : in t_lines_object;
                          variable file_path : in text_field;
                          variable valid : out integer);                           

    procedure lines_get(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable array_object : out t_array_object;
                           variable valid : out integer); 

    procedure lines_set(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable array_object : in t_array_object;
                           variable valid : out integer);
                                                       
    procedure lines_set(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer); 
                           
    procedure lines_append(variable line_object : inout t_line_object;
                           variable array_object : in t_array_object;
                           variable valid : out integer);
                                                       
    procedure lines_append(variable line_object : inout t_line_object;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer);      
                           
    procedure lines_insert(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable array_object : in t_array_object;
                           variable valid : out integer);
                                                       
    procedure lines_insert(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable text_ptr : out stm_text_ptr;
                           variable valid : out integer);                                                    
                                                                                                           
    procedure lines_delete(variable line_object : inout t_line_object;
                           variable position : in integer;
                           variable valid : out integer);  
                           
    procedure lines_pointer(variable line_object : inout t_line_object;
                           variable line_object : in t_line_object;
                           variable valid : out integer);  
                           
    procedure lines_size(variable line_object : inout t_line_object;
                           variable line_size : out integer;
                           variable valid : out integer);                                                                           
                          
end package;



package body tb_pkg_base is

    -- Initialize values for the input record
    function signals_in_init return t_signals_in is
        variable signals : t_signals_in;
    begin
        -- TODO: Set here your init values
        signals.in_signal := 'U';
        signals.in_signal_1 := (others => 'U');
        signals.in_signal_2 := '0';
        return signals;
    end function;

    -- Initialize values for the output record
    function signals_out_init return t_signals_out is
        variable signals : t_signals_out;
    begin
        -- TODO: Set here your init values
        signals.my_signal := '0';
        signals.my_signal_1 := (others => '0');
        return signals;
    end function;
    
    -- SimStm Mapping for input signals
    procedure signal_read(signal signals : in t_signals_in;
                          variable signal_number : in integer;
                          variable value : out integer;
                          variable valid : out integer) is
        variable temp_var : std_logic_vector(31 downto 0);
    begin
        valid := 1;
        temp_var := (others => '0');

        case signal_number is
            -- TODO: add here your SimStm mapping
            when 0 =>
                temp_var(0) := signals.in_signal;
            when 1 =>
                temp_var(signals.in_signal_1'left downto 0) := signals.in_signal_1;
            when 2 =>
                temp_var(0) := signals.in_signal_2;
            when others =>
                valid := 0;
        end case;

        value := to_integer(unsigned(temp_var));
    end procedure;

    -- SimStm Mapping for output signals
    procedure signal_write(signal signals : out t_signals_out;
                           variable signal_number : in integer;
                           variable value : in integer;
                           variable valid : out integer) is
        variable temp_var : std_logic_vector(31 downto 0);
    begin
        valid := 1;
        temp_var := std_logic_vector(to_unsigned(value, 32));

        case signal_number is
            -- TODO: add here your SimStm mapping
            when 0 =>
                signals.my_signal <= temp_var(0);
            when 1 =>
                signals.my_signal_1 <= temp_var(signals.my_signal_1'left downto 0);
            when others =>
                valid := 0;
        end case;
        wait for 0 ps;
    end procedure;


    
    -- Map interrupts to interrupt requests
    procedure get_interrupt_requests (signal signals : in t_signals_in; 
                                      variable interrupt_requests : out unsigned) is     
    begin
        -- TODO: Connect in_signals used as interrupt to the interrupt_vector
        interrupt_requests(0) := signals.in_signal;
        interrupt_requests(1) := signals.in_signal_2;
        wait for 0 ps;
    end procedure;
    
    
    procedure resolve_interrupt_requests(variable interrupt_requests : in unsigned;
                           variable interrupt_in_service : in unsigned;
                           variable interrupt_number : out integer;
                           variable branch_to_interrupt : out boolean;
                           variable branch_to_interrupt_label_std_txt_io_line : out line) is
        variable empty_label : line := new string'("");
        variable interrupt_labels : t_interrupt_labels := (
          -- TODO: Add here all your simstm interrupt entry procedure labels
          new string'("$InterruptA"),
          new string'("$InterruptB")
        ); 
    begin
        interrupt_number := -1;
        branch_to_interrupt := false;
        branch_to_interrupt_label_std_txt_io_line := empty_label;
        
        -- TODO: Adapt your interrupt priority and nesting logic
        
        -- Implementation for behavior:
        --   - the lower the interrupt number the higher its priority
        --   - no interrupt nesting
        if interrupt_requests > 0 then    
            if interrupt_in_service = 0 then
                for i in 0 to number_of_interrupts-1 loop 
                    if interrupt_requests(i) = '1' then
                        interrupt_number := i;
                        branch_to_interrupt := true;
                        branch_to_interrupt_label_std_txt_io_line := interrupt_labels(i);
                    end if;
                end loop;
            end if;
        end if;
        
    end procedure;   

    -- Set in service bit for a processed interrupt
    procedure set_interrupt_in_service (variable interrupt_in_service : inout unsigned; variable interrupt_number : in integer) is        
    begin        
        interrupt_in_service(interrupt_number) := '0';
    end procedure; 
    
   
    -- Reset in service bit for a processed interrupt
    procedure reset_interrupt_in_service (variable interrupt_in_service : inout unsigned; variable interrupt_number : in integer) is        
    begin        
        interrupt_in_service(interrupt_number) := '0';
    end procedure; 
        

end package body;
