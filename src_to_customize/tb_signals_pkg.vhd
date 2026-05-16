use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package tb_signals_pkg is

    type t_signals_in is record
        --base
        sim_time : integer;
        test_suite_index : integer;
        machine_value_width : integer;
        
        -- general
        simstm_loopback_verify_assertions : std_logic_vector(31 downto 0);
        simstm_loopback_verify_failures : std_logic_vector(31 downto 0);
        simstm_loopback_bus_timeout_assertions : std_logic_vector(31 downto 0);
        simstm_loopback_bus_timeout_failures : std_logic_vector(31 downto 0);

        -- signals for tests
        active : std_logic;
        count : std_logic_vector(31 downto 0);
    end record;

    type t_signals_out is record
        --base
        dut_reset : std_logic;

        -- general
        simstm_loopback_verify_failure_expected : std_logic_vector(31 downto 0);
        simstm_loopback_bus_timeout_failure_expected : std_logic_vector(31 downto 0);

        -- signals for tests
        step_down : std_logic;
        step_up : std_logic;
        step_value : std_logic_vector(31 downto 0);
    end record;

    -- TODO: Define here the number of interrupts you want to have
    constant number_of_interrupts : natural := 2;

    type t_interrupt_labels is array (number_of_interrupts - 1 downto 0) of line;

    function signals_in_init return t_signals_in;
    function signals_out_init return t_signals_out;

    procedure signal_read(
        signal signals : in t_signals_in;
        variable signal_number : in integer;
        variable value : out unsigned;
        variable valid : out integer
    );

    procedure signal_write(
        signal signals : out t_signals_out;
        variable signal_number : in integer;
        variable value : in unsigned;
        variable valid : out integer
    );

    procedure get_interrupt_requests(
        signal signals : in t_signals_in;
        variable interrupt_requests : out unsigned
    );

    procedure resolve_interrupt_requests(
        variable interrupt_requests : in unsigned;
        variable interrupt_in_service : in unsigned;
        variable interrupt_number : out integer;
        variable branch_to_interrupt : out boolean;
        variable branch_to_interrupt_proc_std_txt_io_line : out line
    );

    procedure set_interrupt_in_service(
        variable interrupt_in_service : inout unsigned;
        variable interrupt_number : in integer;
        variable value_to_be_set : in std_logic;
        signal signals : out t_signals_out
    );

end package;

package body tb_signals_pkg is

    -- Initialize values for the input record
    function signals_in_init return t_signals_in is
        variable signals : t_signals_in;
    begin
        -- base
        signals.sim_time := 0;
        signals.test_suite_index := 0;

        -- general
        signals.simstm_loopback_verify_assertions := (others => '0');
        signals.simstm_loopback_verify_failures := (others => '0');
        signals.simstm_loopback_bus_timeout_assertions := (others => '0');
        signals.simstm_loopback_bus_timeout_failures := (others => '0');

        -- signals for tests
        signals.active := '0';
        signals.count := (others => '0');

        return signals;
    end function;

    -- Initialize values for the output record
    function signals_out_init return t_signals_out is
        variable signals : t_signals_out;
    begin
        -- base
        signals.bus_reset := '0';

        -- general
        signals.simstm_loopback_verify_failure_expected := (others => '0');
        signals.simstm_loopback_bus_timeout_failure_expected := (others => '0');

        -- signals for tests
        signals.step_down := '0';
        signals.step_up := '0';
        signals.step_value := (others => '0');
        return signals;
    end function;

    -- SimStm Mapping for input signals
    procedure signal_read(
        signal signals : in t_signals_in;
        variable signal_number : in integer;
        variable value : out unsigned;
        variable valid : out integer
    ) is
        procedure value_mapping(constant int : in integer; variable val : out unsigned) is
        begin
            val := to_unsigned(int, val'length);
        end procedure;

        procedure value_mapping(signal slv : in std_logic; variable val : out unsigned) is
        begin
            val := to_unsigned(0, val'length);
            val(0) := slv;
        end procedure;

        procedure value_mapping(signal slv : in std_logic_vector; variable val : out unsigned) is
        begin
            val := resize(unsigned(slv), val'length);
        end procedure;
    begin
        valid := 1;
        value := to_unsigned(0, value'length);

        case signal_number is
            when 0 =>
                assert false
                report "read of unassigned signal e.g., local signal in procedure"
                severity failure;

            -- base
            when 1 =>
                value_mapping(signals.sim_time, value);
            when 2 =>
                value_mapping(signals.test_suite_index, value);
            when 3 =>
                value_mapping(signals.machine_value_width, value);

            -- general
            when 10000 =>
                value_mapping(signals.simstm_loopback_verify_assertions, value);
            when 10001 =>
                value_mapping(signals.simstm_loopback_verify_failures, value);
            when 10002 =>
                value_mapping(signals.simstm_loopback_bus_timeout_assertions, value);
            when 10003 =>
                value_mapping(signals.simstm_loopback_bus_timeout_failures, value);

            -- signals unittest mapping
            when 11000 =>
                value_mapping(signals.active, value);
            when 11001 =>
                value_mapping(signals.count, value);

            when others =>
                valid := 0;

        end case;

    end procedure;

    -- SimStm Mapping for output signals
    procedure signal_write(
        signal signals : out t_signals_out;
        variable signal_number : in integer;
        variable value : in unsigned;
        variable valid : out integer
    ) is
        procedure value_mapping(variable val : in unsigned; signal slv : out std_logic) is
        begin
            slv <= val(0);
        end procedure;

        procedure value_mapping(variable val : in unsigned; signal slv : out std_logic_vector) is
        begin
            slv <= std_logic_vector(resize(val, slv'length));
        end procedure;
    begin
        valid := 1;

        case signal_number is
            when 0 =>
                assert false
                report "write to unassigned signal e.g., local signal in procedure"
                severity failure;

            -- base
            when 1 =>
                value_mapping(value, signals.dut_reset);

            -- general
            when 10000 =>
                value_mapping(value, signals.simstm_loopback_verify_failure_expected);
            when 10001 =>
                value_mapping(value, signals.simstm_loopback_bus_timeout_failure_expected);

            -- signals unittest mapping
            when 11000 =>
                value_mapping(value, signals.step_down);
            when 11001 =>
                value_mapping(value, signals.step_up);
            when 11002 =>
                value_mapping(value, signals.step_value);

            when others =>
                assert false
                report "write to unassigned signal e.g., local signal in procedure"
                severity failure;
                valid := 0;

        end case;
        wait for 0 ps;
    end procedure;

    -- Map interrupts to interrupt requests
    procedure get_interrupt_requests(
        signal signals : in t_signals_in;
        variable interrupt_requests : out unsigned
    ) is
    begin
        interrupt_requests(0) := '0';
        interrupt_requests(1) := '0';
        wait for 0 ps;
    end procedure;

    procedure resolve_interrupt_requests(
        variable interrupt_requests : in unsigned;
        variable interrupt_in_service : in unsigned;
        variable interrupt_number : out integer;
        variable branch_to_interrupt : out boolean;
        variable branch_to_interrupt_proc_std_txt_io_line : out line
    ) is
        variable empty_label : line := new string'("");
        variable interrupt_labels : t_interrupt_labels := (
            -- TODO: Add here all your simstm interrupt entry procedure labels
            new string'("InterruptB"),
            new string'("InterruptA")
        );
    begin
        interrupt_number := -1;
        branch_to_interrupt := false;
        branch_to_interrupt_proc_std_txt_io_line := empty_label;

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
                        branch_to_interrupt_proc_std_txt_io_line := interrupt_labels(i);
                    end if;
                end loop;
            end if;
        end if;

    end procedure;

    -- Set or Reset the in service bit for a processed interrupt
    procedure set_interrupt_in_service(
        variable interrupt_in_service : inout unsigned;
        variable interrupt_number : in integer;
        variable value_to_be_set : in std_logic;
        signal signals : out t_signals_out
    ) is
    begin
        interrupt_in_service(interrupt_number) := value_to_be_set;
        -- TODO: Connect to out_signals used to interrupt busy e.g., to a interrupt dispatcher for
        -- multicore systems
        case interrupt_number is
            -- TODO: add here your SimStm mapping
            when 0 =>
                -- signals.out_signal_3000 <= value_to_be_set;
            when 1 =>
                -- signals.out_signal_3002 <= value_to_be_set;
            when others =>
                null;
        end case;
    end procedure;

end package body;
