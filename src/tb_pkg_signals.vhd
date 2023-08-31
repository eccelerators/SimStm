library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_pkg_signals is
    type t_signals_in is record
        -- TODO: Add here all your inputs
        in_signal : std_logic;
        in_signal_1 : std_logic_vector(7 downto 0);
    end record;

    type t_signals_out is record
        -- TODO: Add here all your outputs
        my_signal : std_logic;
        my_signal_1 : std_logic_vector(7 downto 0);
    end record;

    function signals_in_init return t_signals_in;
    function signals_out_init return t_signals_out;

    procedure signal_write(signal signals : out t_signals_out;
                           variable signal_number : in integer;
                           variable value : in integer;
                           variable valid : out integer);

    procedure signal_read(signal signals : in t_signals_in;
                          variable signal_number : in integer;
                          variable value : out integer;
                          variable valid : out integer);

end tb_pkg_signals;

package body tb_pkg_signals is
    -- Iniziled values for the input record
    function signals_in_init return t_signals_in is
        variable signals : t_signals_in;
    begin
        -- TODO: Set here your init values
        signals.in_signal := 'U';
        signals.in_signal_1 := (others => 'U');
        return signals;
    end signals_in_init;

    -- Iniziled values for the output record
    function signals_out_init return t_signals_out is
        variable signals : t_signals_out;
    begin
        -- TODO: Set here your init values
        signals.my_signal := '0';
        signals.my_signal_1 := (others => '0');
        return signals;
    end signals_out_init;

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
        wait for 1 ps;
    end procedure signal_write;

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
            when others =>
                valid := 0;
        end case;

        value := to_integer(unsigned(temp_var));
    end procedure signal_read;

end tb_pkg_signals;
