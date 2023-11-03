library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library work;
    use work.tb_signals_pkg.all;

entity tb_top is
    generic (
        stimulus_path : string := "./../";
        stimulus_file : string := "test.stm"
    );
end;

architecture behavioural of tb_top is
    signal Clk100M : std_logic := '0';
    signal Rst     : std_logic := '1';
    signal nRst    : std_logic := '0';
    signal SimDone : std_logic;

    signal signals_out : t_signals_out;
    signal signals_in : t_signals_in;
begin
    Rst     <= transport '0' after 100 ns;
    Clk100M <= transport (not Clk100M) and (not SimDone)  after 10 ns / 2;

	nRst <= not Rst;

    tb_simstm_i : entity work.tb_simstm
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            Clk     => Clk100M,
            Rst     => Rst,
            SimDone => SimDone
        );

end;
