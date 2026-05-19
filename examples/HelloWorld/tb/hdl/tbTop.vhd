
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
        machine_value_width : integer := 2 ** (stimulus_test_suite_index rem 4) * 32
    );
end;

architecture behavioural of tbTop is

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal executing_line : integer := 0;
    signal executing_file : text_line;
    signal marker : std_logic_vector(15 downto 0) := (others => '0');

    signal signals_in : t_signals_in := signals_in_init;
    signal signals_out : t_signals_out := signals_out_init;
    signal bus_down : t_bus_down := bus_down_init;
    signal bus_up : t_bus_up := bus_up_init;

begin

    signals_in.test_suite_index <= stimulus_test_suite_index;
    signals_in.sim_time <= (now / 1 ns);
    signals_in.machine_value_width <= machine_value_width;
    rst <= signals_out.dut_reset;
        
    clk <= transport (not Clk) after 10 ns / 2; -- 100MHz
      
    i_tb_simstm : entity work.tb_simstm
        generic map(
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file,
            stimulus_main_entry_label => stimulus_main_entry_label,
            machine_value_width => machine_value_width
        )
        port map(
            executing_line => executing_line,
            executing_file => executing_file,
            verify_assertions => signals_in.simstm_loopback_verify_assertions,
            verify_failures => signals_in.simstm_loopback_verify_failures,
            bus_timeout_assertions => signals_in.simstm_loopback_bus_timeout_assertions,
            bus_timeout_failures => signals_in.simstm_loopback_bus_timeout_failures,
            verify_failure_expected => signals_out.simstm_loopback_verify_failure_expected,
            bus_timeout_failure_expected => signals_out.simstm_loopback_bus_timeout_failure_expected,
            marker => marker,
            signals_in => signals_in,
            signals_out => signals_out,
            bus_down => bus_down,
            bus_up => bus_up
        );
        
    i_dut : entity work.Dut 
        port map(
            Rst => signals_out.dut_reset,
            Clk  => clk,
            Active  => signals_in.active
        );

end architecture;
