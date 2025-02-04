-- ******************************************************************************
--
--                   /------o
--             eccelerators
--          o------/
--
--  This file is an Eccelerators GmbH sample project.
--
--  MIT License:
--  Copyright (c) 2025 Eccelerators GmbH
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- ******************************************************************************

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

use work.basic.all;

entity Ram is
	generic(
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

	signal Ram : array_of_std_logic_vector(0 to 63)(31 downto 0) := InitialCellValues;
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
