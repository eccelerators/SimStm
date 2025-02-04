--MIT License
--
--Copyright (c) 2023 Michael Jørgensen
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RamAvalon is
   generic(
      ADDRESS_WIDTH : integer; -- Determines the size of the RAM (num. of words = 2**ADDRESS_WIDTH)
      DATA_WIDTH : integer := 32 -- Number of data bits
   );
   port(
      clk_i : in std_logic;
      rst_i : in std_logic;
      avm_waitrequest_o : out std_logic;
      avm_write_i : in std_logic;
      avm_read_i : in std_logic;
      avm_address_i : in std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
      avm_writedata_i : in std_logic_vector(DATA_WIDTH - 1 downto 0);
      avm_byteenable_i : in std_logic_vector(DATA_WIDTH / 8 - 1 downto 0);
      avm_burstcount_i : in std_logic_vector(7 downto 0);
      avm_readdata_o : out std_logic_vector(DATA_WIDTH - 1 downto 0);
      avm_readdatavalid_o : out std_logic
   );
end entity;

architecture simulation of RamAvalon is

   -- This defines a type containing an array of bytes
   type mem_type is array (0 to 2 ** ADDRESS_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

   signal write_burstcount : std_logic_vector(7 downto 0) := (others => '0');
   signal write_address : std_logic_vector(ADDRESS_WIDTH - 1 downto 0) := (others => '0');

   signal read_burstcount : std_logic_vector(7 downto 0) := (others => '0');
   signal read_address : std_logic_vector(ADDRESS_WIDTH - 1 downto 0) := (others => '0');

   signal mem_write_burstcount : std_logic_vector(7 downto 0) := (others => '0');
   signal mem_read_burstcount : std_logic_vector(7 downto 0) := (others => '0');
   signal mem_write_address : std_logic_vector(ADDRESS_WIDTH - 1 downto 0) := (others => '0');
   signal mem_read_address : std_logic_vector(ADDRESS_WIDTH - 1 downto 0) := (others => '0');

begin

   mem_write_address <= avm_address_i when write_burstcount = X"00" else
                        write_address;
   mem_read_address <= avm_address_i when read_burstcount = X"00" else
                       read_address;
   mem_write_burstcount <= avm_burstcount_i when write_burstcount = X"00" else
                           write_burstcount;
   mem_read_burstcount <= avm_burstcount_i when read_burstcount = X"00" else
                          read_burstcount;

   avm_waitrequest_o <= '0' when unsigned(read_burstcount) = 0 else
                        '1';

   mem_proc : process(clk_i)
      variable mem_v : mem_type := (others => (others => '0'));
   begin
      if rising_edge(clk_i) then
         avm_readdatavalid_o <= '0';

         if avm_write_i = '1' and avm_waitrequest_o = '0' then
            write_address <= std_logic_vector(unsigned(mem_write_address) + 1);
            write_burstcount <= std_logic_vector(unsigned(mem_write_burstcount) - 1);

            -- report "Writing 0x" & to_hstring(avm_writedata_i) &
            --        " to 0x" & to_hstring(mem_write_address) &
            --        " with burstcount " & to_hstring(write_burstcount) &
            --        " and byteenable 0x" & to_hstring(avm_byteenable_i);

            for b in 0 to DATA_WIDTH / 8 - 1 loop
               if avm_byteenable_i(b) = '1' then
                  mem_v(to_integer(unsigned(mem_write_address)))(8 * b + 7 downto 8 * b) := avm_writedata_i(8 * b + 7 downto 8 * b);
               end if;
            end loop;

         end if;

         if (avm_read_i = '1' and avm_waitrequest_o = '0') or to_integer(unsigned(read_burstcount)) > 0 then
            read_address <= std_logic_vector(unsigned(mem_read_address) + 1);
            read_burstcount <= std_logic_vector(unsigned(mem_read_burstcount) - 1);

            avm_readdata_o <= mem_v(to_integer(unsigned(mem_read_address)));
            avm_readdatavalid_o <= '1';

            --report "Reading 0x" & to_hstring(mem_v(to_integer(unsigned(mem_read_address)))) &
            --       " from 0x" & to_hstring(mem_read_address) &
            --       " with burstcount " & to_hstring(read_burstcount);
         end if;

         if rst_i = '1' then
            write_burstcount <= (others => '0');
            read_burstcount <= (others => '0');
         end if;
      end if;
   end process;

end architecture;
