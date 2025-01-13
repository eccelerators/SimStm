-- source from: https://github.com/mbitsnbites/wishbone-blocks/blob/master/vhdl/wb_ram.vhd
-- with Modified ACK

----------------------------------------------------------------------------------------------------
-- Copyright (c) 2019 Marcus Geelnard
--
-- This software is provided 'as-is', without any express or implied warranty. In no event will the
-- authors be held liable for any damages arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose, including commercial
-- applications, and to alter it and redistribute it freely, subject to the following restrictions:
--
--  1. The origin of this software must not be misrepresented; you must not claim that you wrote
--     the original software. If you use this software in a product, an acknowledgment in the
--     product documentation would be appreciated but is not required.
--
--  2. Altered source versions must be plainly marked as such, and must not be misrepresented as
--     being the original software.
--
--  3. This notice may not be removed or altered from any source distribution.
----------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- This is a single-ported RAM module with the following properties:
--   * Wishbone B4 pipelined interface (see: https://cdn.opencores.org/downloads/wbspec_b4.pdf)
--   * Configurable size.
--   * Configurable data width.
--   * Configurable word granularity (for the SEL signal).
--   * Byte enable / select for write operations.
--   * Single cycle read/write operation.
--   * Synthesizes to BRAM.
----------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RamWishbone is
  generic(
    ADDRESS_WIDTH : positive;  -- Determines the size of the RAM (num. of words = 2**ADDRESS_WIDTH)
    DATA_WIDTH : positive := 32;  -- -- Number of data bits, must be a multiple of GRANULARITY
    GRANULARITY : positive := 8  -- Usually 8 (for byte granularity)
  );
  port(
    -- Wishbone SLAVE signals.
    i_rst : in std_logic;
    i_clk : in std_logic;
    i_adr : in std_logic_vector(ADDRESS_WIDTH-1 downto 0);
    i_dat : in std_logic_vector(DATA_WIDTH-1 downto 0);
    i_we : in std_logic;
    i_sel : in std_logic_vector(DATA_WIDTH/GRANULARITY-1 downto 0);
    i_cyc : in std_logic;
    i_stb : in std_logic;
    o_dat : out std_logic_vector(DATA_WIDTH-1 downto 0);
    o_ack : out std_logic;
    o_stall : out std_logic;
    o_rty : out std_logic;
    o_err : out std_logic
  );
end entity;

architecture rtl of RamWishbone is
  constant C_NUM_WORDS : positive := 2**ADDRESS_WIDTH;
  constant C_PARTS_PER_WORD : positive := DATA_WIDTH / GRANULARITY;

  subtype T_PART is std_logic_vector(GRANULARITY-1 downto 0);
  type T_PART_ARRAY is array (0 to C_NUM_WORDS-1) of T_PART;
  type T_MEM is array (0 to C_PARTS_PER_WORD-1) of T_PART_ARRAY;

  signal s_mem : T_MEM := (others => ( others => (others => '0')));
  signal pre_ack : std_logic := '0';
begin
  o_ack <= pre_ack;

  process(i_rst, i_clk)
    variable v_adr : integer range 0 to C_NUM_WORDS-1;
    variable v_req : std_logic;
  begin
    if i_rst = '1' then
      o_dat <= (others => '0');
      pre_ack <= '0';
    elsif rising_edge(i_clk) then
      -- Is this a valid request for this Wishbone slave?
      v_req := i_cyc and i_stb and not pre_ack;

      -- Get the address.
      v_adr := to_integer(unsigned(i_adr));

      -- Write?
      if v_req = '1' and i_we = '1' then
        for k in 0 to C_PARTS_PER_WORD-1 loop
          if i_sel(k) = '1' then
            s_mem(k)(v_adr) <= i_dat(GRANULARITY*(k+1)-1 downto GRANULARITY*k);
          end if;
        end loop;
      end if;

      -- We always read.
      for k in 0 to C_PARTS_PER_WORD-1 loop
        o_dat(GRANULARITY*(k+1)-1 downto GRANULARITY*k) <= s_mem(k)(v_adr);
      end loop;

      -- Ack that we have dealt with the request.
      pre_ack <= v_req;
    end if;
  end process;

  -- Note: STALL, RTY and ERR are always deasserted, as we respond in one clock cycle and there is
  -- no risk of any errors.
  o_stall <= '0';
  o_rty <= '0';
  o_err <= '0';
end architecture;