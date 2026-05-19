library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.basic.all;

entity Dut is
    port(
        -- Wishbone SLAVE signals.
        i_rst : in std_logic;
        i_clk : in std_logic;
        i_adr : in std_logic_vector(7 downto 0);
        i_dat : in std_logic_vector(31 downto 0);
        i_we : in std_logic;
        i_sel : in std_logic_vector(3 downto 0);
        i_cyc : in std_logic;
        i_stb : in std_logic;
        o_dat : out std_logic_vector(31 downto 0);
        o_ack : out std_logic;
        o_stall : out std_logic;
        o_rty : out std_logic;
        o_err : out std_logic
    );
end entity;

architecture rtl of Dut is
begin
    i_RamWishbone_32 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => i_rst,
            i_clk => i_clk,
            i_adr => i_adr,
            i_dat => i_dat,
            i_we => i_we,
            i_sel => i_sel,
            i_cyc => i_cyc,
            i_stb => i_stb,
            o_dat => o_dat,
            o_ack => o_ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );

end architecture;
