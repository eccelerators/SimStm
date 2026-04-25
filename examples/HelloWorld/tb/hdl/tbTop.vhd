
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;
use work.tb_bus_pkg.all;
use work.tb_signals_pkg.all;
use work.basic.all;

entity tbTop is
    generic(
        stimulus_path : string := "tb/simstm/";
        stimulus_file : string := "testMain.stm";
        stimulus_main_entry_label : string := "SimStmTest.testMain";
        stimulus_test_suite_index : integer := 255;
        machine_value_width : integer := 2 ** (stimulus_test_suite_index rem 4) * 32;
        machine_address_width : integer := 31
    );
end;

architecture behavioural of tbTop is

    signal executing_line : integer := 0;
    signal executing_file : text_line;
    signal marker : std_logic_vector(15 downto 0) := (others => '0');
    signal verify_passes : std_logic_vector(31 downto 0) := (others => '0');
    signal verify_failures : std_logic_vector(31 downto 0) := (others => '0');
    signal bus_timeout_passes : std_logic_vector(31 downto 0) := (others => '0');
    signal bus_timeout_failures : std_logic_vector(31 downto 0) := (others => '0');

    signal signals_in : t_signals_in := signals_in_init;
    signal signals_out : t_signals_out := signals_out_init;
    signal bus_down : t_bus_down := bus_down_init;
    signal bus_up : t_bus_up := bus_up_init;

    signal InitDut : std_logic := '1';
    signal Clk : std_logic := '0';
    signal Rst : std_logic := '1';
    signal Active : std_logic := '0';

begin

    -- standard inputs
    -- signals_in.in_signal_0 constant 0 used to indicate yet unsassigned signal (None) e.g. in locally defined signals to be set by a parameter later
    -- signals_in.in_signal_1 actual simulation time already supplied by package
    signals_in.in_signal_2 <= std_logic_vector(to_unsigned(stimulus_test_suite_index, 32));
    -- signals_in.in_signal_3 constant 0 already supplied by package
    signals_in.in_signal_4 <= verify_passes;
    signals_in.in_signal_5 <= verify_failures;
    signals_in.in_signal_6 <= bus_timeout_passes;
    signals_in.in_signal_7 <= bus_timeout_failures;
    -- signals_in.in_signal_8 Machine value width

    -- standard outputs
    InitDut <= signals_out.out_signal_1;
    -- signals_out.out_signal_5 <= expected_standard_test_verify_failure_count already connected in tb_simstm
    -- signals_out.out_signal_7 <= expected_bus_timeout_test_failure_count already connected in tb_simstm

    -- interrupts
    signals_in.in_signal_1000 <= signals_out.out_signal_3002;
    signals_in.in_signal_1001 <= signals_out.out_signal_3003;

    -- user inputs and outputs
    signals_in.in_signal_2000 <= Active;
    signals_in.in_signal_2001 <= signals_out.out_signal_3001;
    signals_in.in_signal_2002 <= signals_out.out_signal_3002;
    signals_in.in_signal_2003 <= signals_out.out_signal_3003;
    
    Clk <= transport (not Clk) after 10 ns / 2; -- 100MHz
    Rst <= InitDut;
        
    i_tb_simstm : entity work.tb_simstm
        generic map(
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file,
            stimulus_main_entry_label => stimulus_main_entry_label,
            machine_value_width => machine_value_width,
            machine_address_width => machine_address_width
        )
        port map(
            executing_line => executing_line,
            executing_file => executing_file,
            verify_passes => verify_passes,
            verify_failures => verify_failures,
            bus_timeout_passes => bus_timeout_passes,
            bus_timeout_failures => bus_timeout_failures,
            marker => marker,
            signals_in => signals_in,
            signals_out => signals_out,
            bus_down => bus_down,
            bus_up => bus_up
        );
        
    i_dut : entity work.Dut 
        port map(
            Rst => Rst,
            Clk  => Clk,
            Active  => Active
        );

end architecture;
