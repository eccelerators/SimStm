library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.tb_bus_pkg.all;

entity tb_top is
    generic (
        stimulus_path : string := "./../";
        stimulus_file : string := "test.stm"
    );
end;

architecture behavioural of tb_top is
    signal clk100m : std_logic := '0';
    signal rst     : std_logic := '1';
    signal nrst    : std_logic := '0';
    signal simdone : std_logic;

    signal bus_down : t_bus_down;
    signal bus_up   : t_bus_up;
begin
    rst     <= transport '0' after 100 ns;
    clk100m <= transport (not clk100m) and (not simdone) after 10 ns / 2;

	nrst <= not rst;

    tb_simstm_i : entity work.tb_simstm
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            clk     => clk100m,
            rst     => rst,
            simdone => simdone,
            bus_down => bus_down,
            bus_up   => bus_up
        );


    ram : entity work.wb_ram
        generic map (
            adr_width => 8,
            dat_width => 32,
            granularity => 8
        )
        port map(
        -- wshbone slave signals.
            i_rst => rst,
            i_clk => clk100m,
            i_adr => bus_down.wishbone.adr(7 downto 0),
            i_dat => bus_down.wishbone.data,
            i_we  => bus_down.wishbone.we,
            i_sel => bus_down.wishbone.sel,
            i_cyc => bus_down.wishbone.cyc,
            i_stb => bus_down.wishbone.stb,
            o_dat => bus_up.wishbone.data,
            o_ack => bus_up.wishbone.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );
end;
