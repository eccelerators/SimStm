library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package tb_signals_pkg is

    type t_signals_in is record
    
        -- TODO: Add here all your inputs        
        in_signal_1 : std_logic_vector(c_stm_value_width - 1 downto 0); -- stimulus_test_suite_index       
        in_signal_3 : std_logic_vector(c_stm_value_width - 1 downto 0); -- standard_test_verify_passes_count
        in_signal_4 : std_logic_vector(c_stm_value_width - 1 downto 0); -- standard_test_verify_failure_count
        in_signal_5 : std_logic_vector(c_stm_value_width - 1 downto 0); -- bus_timeout_passes_count
        in_signal_6 : std_logic_vector(c_stm_value_width - 1 downto 0); -- bus_timeout_failure_count
        
        in_signal_1000 : std_logic;
        in_signal_1001 : std_logic;
                
        in_signal_2000: std_logic;
        in_signal_2001: std_logic_vector(7 downto 0);
        in_signal_2002: std_logic;
        in_signal_2003: std_logic;
                       
    end record;

    type t_signals_out is record
    
        -- TODO: Add here all your outputs 
        out_signal_0 : std_logic; -- init dut
        out_signal_4 : std_logic_vector(c_stm_value_width - 1 downto 0); -- expected standard_test_error_count    
        out_signal_6 : std_logic_vector(c_stm_value_width - 1 downto 0); -- expected bus_timeout_test_error_count    
        out_signal_3000 : std_logic;
        out_signal_3001 : std_logic_vector(7 downto 0);
        out_signal_3002 : std_logic;
        out_signal_3003 : std_logic;
        
    end record;

    -- TODO: Define here the number of interrupts you want to have
    constant number_of_interrupts : natural := 2;

    type t_interrupt_labels is array (number_of_interrupts - 1 downto 0) of line;

    function signals_in_init return t_signals_in;
    function signals_out_init return t_signals_out;

    procedure signal_read(signal signals : in t_signals_in;
                          variable signal_number : in integer;
                          variable value : out unsigned(c_stm_value_width - 1 downto 0);
                          variable valid : out integer);

    procedure signal_write(signal signals : out t_signals_out;
                           variable signal_number : in integer;
                           variable value : in unsigned(c_stm_value_width - 1 downto 0);
                           variable valid : out integer);

    procedure get_interrupt_requests(signal signals : in t_signals_in;
                                     variable interrupt_requests : out unsigned);

    procedure resolve_interrupt_requests(variable interrupt_requests : in unsigned;
                                         variable interrupt_in_service : in unsigned;
                                         variable interrupt_number : out integer;
                                         variable branch_to_interrupt : out boolean;
                                         variable branch_to_interrupt_label_std_txt_io_line : out line);

    procedure set_interrupt_in_service(variable interrupt_in_service : inout unsigned; 
                                       variable interrupt_number : in integer;
                                       variable value_to_be_set : in std_logic; 
                                       signal signals : out t_signals_out);

end package;

package body tb_signals_pkg is

    -- Initialize values for the input record
    function signals_in_init return t_signals_in is
        variable signals : t_signals_in;
    begin
    
        -- TODO: Set here your init values      
        signals.in_signal_1 := (others => '0');  -- stimulus_test_suite_index                 
        signals.in_signal_4 := (others => '0');  -- expected_standard_test_verify_failure_count           
        signals.in_signal_6 := (others => '0');  -- expected_bus_timeout_failure_count            
                
        signals.in_signal_1000 := '0';
        signals.in_signal_1001 := '0';
        
        signals.in_signal_2000 := '0';
        signals.in_signal_2001 := (others => '0');
        signals.in_signal_2002 := '0';
        signals.in_signal_2003 := '0';
        
        return signals;
    end function;

    -- Initialize values for the output record
    function signals_out_init return t_signals_out is
        variable signals : t_signals_out;
    begin
    
        -- TODO: Set here your init values 
        signals.out_signal_0 := '0'; 
        signals.out_signal_4 := (others => '0'); 
        signals.out_signal_6 := (others => '0');   
        signals.out_signal_3000 := '0';
        signals.out_signal_3001 := (others => '0');
        signals.out_signal_3002 := '0';
        signals.out_signal_3003 := '0';
        
        return signals;
    end function;

    -- SimStm Mapping for input signals
    procedure signal_read(signal signals : in t_signals_in;
                          variable signal_number : in integer;
                          variable value : out unsigned(c_stm_value_width - 1 downto 0);
                          variable valid : out integer) is
    begin
        valid := 1;
        value := (others => '0');

        case signal_number is

            -- TODO: add here your SimStm mapping
            when 0 =>
                value := to_unsigned((now / 1 ns), c_stm_value_width);
            when 1 =>
                value(signals.in_signal_1'left downto 0) := unsigned(signals.in_signal_1);
            when 2 =>
                value := (others => '0');
            when 3 =>
                value(signals.in_signal_3'left downto 0) := unsigned(signals.in_signal_3);
            when 4 =>
                value(signals.in_signal_4'left downto 0) := unsigned(signals.in_signal_4);               
            when 5 =>
                value(signals.in_signal_5'left downto 0) := unsigned(signals.in_signal_5);
            when 6 =>
                value(signals.in_signal_6'left downto 0) := unsigned(signals.in_signal_6); 
                
            when 1000 =>
                value(0) := signals.in_signal_1000;
            when 1001 =>
                value(0) := signals.in_signal_1001;
                
            when 2000 =>
                value(0) := signals.in_signal_2000;
            when 2001 =>
                value(signals.in_signal_2001'left downto 0) := unsigned(signals.in_signal_2001);
            when 2002 =>
                value(0) := signals.in_signal_2002;                                                
            when 2003 =>
                value(0) := signals.in_signal_2003; 
                          
            when others =>
                valid := 0;
        end case;

    end procedure;

    -- SimStm Mapping for output signals
    procedure signal_write(signal signals : out t_signals_out;
                           variable signal_number : in integer;
                           variable value : in unsigned(c_stm_value_width - 1 downto 0);
                           variable valid : out integer) is
    begin
        valid := 1;

        case signal_number is
        
            -- TODO: add here your SimStm mapping
            when 0 =>
                signals.out_signal_0 <= value(0);
            when 4 =>
                signals.out_signal_4 <= std_logic_vector(value(signals.out_signal_4'left downto 0));
            when 6 =>
                signals.out_signal_6 <= std_logic_vector(value(signals.out_signal_6'left downto 0));
                                                
            when 3000 =>
                signals.out_signal_3000 <= value(0);
            when 3001 =>
                signals.out_signal_3001 <= std_logic_vector(value(signals.out_signal_3001'left downto 0));
            when 3002 =>
                signals.out_signal_3002 <= value(0);
            when 3003 =>
                signals.out_signal_3003 <= value(0);
                                
            when others =>
                valid := 0;
        end case;
        wait for 0 ps;
    end procedure;

    -- Map interrupts to interrupt requests
    procedure get_interrupt_requests(signal signals : in t_signals_in;
                                     variable interrupt_requests : out unsigned) is
    begin
        -- TODO: Connect in_signals used as interrupt to interrupt requests
        interrupt_requests(0) := signals.in_signal_1000;
        interrupt_requests(1) := signals.in_signal_1001;
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
            new string'("$InterruptB"),
            new string'("$InterruptA")
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
                for i in 0 to number_of_interrupts - 1 loop
                    if interrupt_requests(i) = '1' then
                        interrupt_number := i;
                        branch_to_interrupt := true;
                        branch_to_interrupt_label_std_txt_io_line := interrupt_labels(i);
                    end if;
                end loop;
            end if;
        end if;

    end procedure;

    -- Set or Reset the in service bit for a processed interrupt
    procedure set_interrupt_in_service(variable interrupt_in_service : inout unsigned; 
                                       variable interrupt_number : in integer;
                                       variable value_to_be_set : in std_logic; 
                                       signal signals : out t_signals_out) is
    begin        
        interrupt_in_service(interrupt_number) := value_to_be_set;
        -- TODO: Connect to out_signals used to interrupt busy e.g., to a interrupt dispatcher for 
        -- multicore systems
        -- case interrupt_number is
        --     -- TODO: add here your SimStm mapping
        --     when 0 =>
        --         signals.out_signal_1000 <= value_to_be_set;
        --     when 1 =>
        --         signals.out_signal_1001 <= value_to_be_set;
        --     when others =>
        --         null;
        -- end case;
    end procedure;

end package body;
