library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

use work.basic.all;

entity Ram is
    generic (
        InitialCellValues : array_of_std_logic_vector
    );
	port(
		Clk : in std_logic;
		WriteEnable : in std_logic_vector;
		Address : in std_logic_vector;
		WriteData : in std_logic_vector;
		ReadData : out std_logic_vector
	);
end entity;

architecture RTL of Ram is
			
	signal Ram :array_of_std_logic_vector(0 to 63)(31 downto 0) := InitialCellValues;
	signal ReadAddress : std_logic_vector(Address'range);

begin

	RamProc : process(Clk) is
	begin
		if rising_edge(Clk) then
            for i in 0 to WriteEnable'left loop   
                if WriteEnable(i) = '1' then
                    Ram(to_integer(unsigned(Address)))(i * 8 + 7 downto i * 8) <= WriteData(i * 8 + 7 downto i * 8);
                end if;
            end loop;
			ReadAddress <= Address;
		end if;
	end process;

	ReadData <= Ram(to_integer(unsigned(ReadAddress)));

end architecture;
