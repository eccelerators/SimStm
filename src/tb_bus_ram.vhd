-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Created by Eccelerators
--
-- Description:
--   Simple RAM bus helper package used by SimStm bus access instructions.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_ram_pkg is
    generic(
        G_ADDR_W : positive := 32;
        G_DATA_W : positive := 32
    );
    constant C_WE_W : positive := G_DATA_W / 8;

    type t_ram_down is record
        address : std_logic_vector(G_ADDR_W - 1 downto 0);
        write_enable : std_logic_vector(C_WE_W - 1 downto 0);
        write_data : std_logic_vector(G_DATA_W - 1 downto 0);
    end record;

    type t_ram_up is record
        clk : std_logic;
        read_data : std_logic_vector(G_DATA_W - 1 downto 0);
    end record;

    type t_ram_trace is record
        ram_down : t_ram_down;
        ram_up : t_ram_up;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function ram_down_init return t_ram_down;
    function ram_up_init return t_ram_up;

    procedure write_ram(signal ram_down : out t_ram_down;
                        signal ram_up : in t_ram_up;
                        variable address : in unsigned;
                        variable data : in unsigned;
                        variable access_width : in integer;
                        variable successfull : out boolean;
                        variable timeout : in time);

    procedure read_ram(signal ram_down : out t_ram_down;
                       signal ram_up : in t_ram_up;
                       variable address : in unsigned;
                       variable data : out unsigned;
                       variable access_width : in integer;
                       variable successfull : out boolean;
                       variable timeout : in time);

end package;

package body tb_bus_ram_pkg is

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

    function ram_down_init return t_ram_down is
        variable init : t_ram_down;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_ram_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_ram_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        assert G_ADDR_W mod 8 = 0
        report "tb_bus_ram_pkg: G_ADDR_W must be a multiple of 8, got " & integer'image(G_ADDR_W) severity failure;
        init.address := (others => '0');
        init.write_enable := (others => '0');
        init.write_data := (others => '0');
        return init;
    end function;

    function ram_up_init return t_ram_up is
        variable init : t_ram_up;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_ram_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_ram_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        init.clk := '0';
        init.read_data := (others => '0');
        return init;
    end function;

    procedure write_ram(signal ram_down : out t_ram_down;
                        signal ram_up : in t_ram_up;
                        variable address : in unsigned;
                        variable data : in unsigned;
                        variable access_width : in integer;
                        variable successfull : out boolean;
                        variable timeout : in time) is

        variable byte_offset : integer;
        variable we_base : std_logic_vector(C_WE_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "write_ram: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "write_ram: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        byte_offset := to_integer(unsigned(std_logic_vector(address(C_WE_W - 1 downto 0))));
        num_bytes := access_width / 8;

        we_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            we_base(i) := '1';
        end loop;

        data_temp := (others => '0');
        data_temp(access_width - 1 downto 0) := std_logic_vector(data(access_width - 1 downto 0));

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_init;
            return;
        end if;

        ram_down.address <= std_logic_vector(address(G_ADDR_W - 1 downto 0));

        if byte_offset = 0 then
            ram_down.write_enable <= we_base;
            ram_down.write_data <= data_temp;
        else
            ram_down.write_enable <= we_base(C_WE_W - 1 - byte_offset downto 0) & std_logic_vector(to_unsigned(0, byte_offset));
            ram_down.write_data <= data_temp(G_DATA_W - 1 - byte_offset * 8 downto 0) & std_logic_vector(to_unsigned(0, byte_offset * 8));
        end if;

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_init;
            return;
        end if;

        ram_down <= ram_down_init;
        successfull := true;
    end procedure;

    procedure read_ram(signal ram_down : out t_ram_down;
                       signal ram_up : in t_ram_up;
                       variable address : in unsigned;
                       variable data : out unsigned;
                       variable access_width : in integer;
                       variable successfull : out boolean;
                       variable timeout : in time) is

        variable byte_offset : integer;
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "read_ram: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "read_ram: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        byte_offset := to_integer(unsigned(std_logic_vector(address(C_WE_W - 1 downto 0))));

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_init;
            return;
        end if;

        ram_down.address <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        ram_down.write_data <= (others => '0');
        ram_down.write_enable <= (others => '0');

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_init;
            return;
        end if;

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_init;
            return;
        end if;

        if byte_offset = 0 then
            data_temp := ram_up.read_data;
        else
            data_temp := std_logic_vector(to_unsigned(0, byte_offset * 8)) & ram_up.read_data(G_DATA_W - 1 downto byte_offset * 8);
        end if;

        data := to_unsigned(0, data'length);
        data(access_width - 1 downto 0) := unsigned(data_temp(access_width - 1 downto 0));

        ram_down <= ram_down_init;
        successfull := true;
    end procedure;

end package body;
