library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.basic.all;

entity Dut is
    generic(
        Ram32InitialCellValues : array_of_std_logic_vector(0 to 63)(31 downto 0) := (others => x"BABABABA")
    );
    port(
        Clk : in std_logic;
        WriteEnable : in std_logic_vector;
        Address : in std_logic_vector;
        WriteData : in std_logic_vector;
        ReadData : out std_logic_vector
    );
end entity;

architecture rtl of Dut is
begin
    i_Ram32 : entity work.Ram
        generic map(
            InitialCellValues => Ram32InitialCellValues
        )
        port map(
            Clk => Clk,
            WriteEnable => WriteEnable,
            Address => Address,
            WriteData => WriteData,
            ReadData => ReadData
        );
end architecture;
