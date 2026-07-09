library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dut is
    port(
        Rst : in std_logic;
        Clk : in std_logic;
        Active : out std_logic
    );
end entity;

architecture rtl of Dut is
begin
    proc : process(Clk) is
    begin
        if rising_edge(Clk) then
            Active <= not Rst;
        end if;
    end process;
end architecture;
