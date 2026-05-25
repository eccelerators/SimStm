-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Created by Eccelerators
--
-- Description:
--   Wishbone bus helper package used by SimStm bus access instructions.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;
use work.basic.all;

package tb_bus_wishbone_pkg is
    generic(
        G_ADDR_W : positive := 32;
        G_DATA_W : positive := 32
    );
    constant C_SEL_W : positive := G_DATA_W / 8;

    type t_wishbone_down is record
        adr : std_logic_vector(G_ADDR_W - 1 downto 0);
        sel : std_logic_vector(C_SEL_W - 1 downto 0);
        data : std_logic_vector(G_DATA_W - 1 downto 0);
        we : std_logic;
        stb : std_logic;
        cyc : std_logic;
    end record;

    type t_wishbone_up is record
        clk : std_logic;
        data : std_logic_vector(G_DATA_W - 1 downto 0);
        ack : std_logic;
    end record;

    type t_wishbone_trace is record
        wishbone_down : t_wishbone_down;
        wishbone_up : t_wishbone_up;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function wishbone_down_init return t_wishbone_down;
    function wishbone_up_init return t_wishbone_up;

    procedure write_wishbone(signal wishbone_down : out t_wishbone_down;
                             signal wishbone_up : in t_wishbone_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_wishbone(signal wishbone_down : out t_wishbone_down;
                            signal wishbone_up : in t_wishbone_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);

end package;

package body tb_bus_wishbone_pkg is

    function f_is_power_of_two(n : positive) return boolean is
        variable v : positive := n;
    begin
        while v > 1 loop
            if (v mod 2) /= 0 then
                return false;
            end if;
            v := v / 2;
        end loop;
        return true;
    end function;

    function wishbone_down_init return t_wishbone_down is
        variable init : t_wishbone_down;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_wishbone_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_wishbone_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        assert G_ADDR_W mod 8 = 0
        report "tb_bus_wishbone_pkg: G_ADDR_W must be a multiple of 8, got " & integer'image(G_ADDR_W) severity failure;
        init.adr := (others => '0');
        init.sel := (others => '0');
        init.data := (others => '0');
        init.we := '0';
        init.stb := '0';
        init.cyc := '0';
        return init;
    end function;

    function wishbone_up_init return t_wishbone_up is
        variable init : t_wishbone_up;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_wishbone_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_wishbone_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        init.clk := '0';
        init.data := (others => '0');
        init.ack := '0';
        return init;
    end function;

    procedure write_wishbone(signal wishbone_down : out t_wishbone_down;
                             signal wishbone_up : in t_wishbone_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable sel_base : std_logic_vector(C_SEL_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "write_wishbone: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "write_wishbone: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_SEL_W - 1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));
        num_bytes := access_width / 8;

        sel_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            sel_base(i) := '1';
        end loop;

        data_temp := (others => '0');
        data_temp(access_width - 1 downto 0) := std_logic_vector(data(access_width - 1 downto 0));

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wishbone_down.adr <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        wishbone_down.sel <= std_logic_vector(shift_left(unsigned(sel_base), byte_offset));
        wishbone_down.data <= std_logic_vector(shift_left(unsigned(data_temp), byte_offset * 8));

        wishbone_down.we <= '1';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_init;
                return;
            end if;
            if wishbone_up.ack = '1' then
                exit;
            end if;
        end loop;

        wishbone_down <= wishbone_down_init;
        successfull := true;
    end procedure;

    procedure read_wishbone(signal wishbone_down : out t_wishbone_down;
                            signal wishbone_up : in t_wishbone_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time)is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable sel_base : std_logic_vector(C_SEL_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "read_wishbone: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "read_wishbone: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_SEL_W - 1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));
        num_bytes := access_width / 8;

        sel_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            sel_base(i) := '1';
        end loop;

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wishbone_down.adr <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        wishbone_down.sel <= std_logic_vector(shift_left(unsigned(sel_base), byte_offset));

        wishbone_down.data <= (others => '0');
        wishbone_down.we <= '0';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_init;
                return;
            end if;
            if wishbone_up.ack = '1' then
                exit;
            end if;
        end loop;

        wishbone_down <= wishbone_down_init;
        data_temp := std_logic_vector(shift_right(unsigned(wishbone_up.data), byte_offset * 8));

        data := to_unsigned(0, data'length);
        data(access_width - 1 downto 0) := unsigned(data_temp(access_width - 1 downto 0));

        successfull := true;
    end procedure;

end package body;
