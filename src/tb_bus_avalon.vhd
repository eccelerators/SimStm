-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Created by Eccelerators
--
-- Description:
--   Avalon-MM bus helper package used by SimStm bus access instructions.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;
use work.basic.all;

package tb_bus_avalon_pkg is
    generic(
        G_ADDR_W : positive := 32;
        G_DATA_W : positive := 64
    );
    constant C_BE_W : positive := G_DATA_W / 8;
    constant C_BYTE_SEL_W : natural := C_BE_W - 1;

    type t_avalonmm_down is record
        address : std_logic_vector(G_ADDR_W - 1 downto 0);
        byteenable : std_logic_vector(C_BE_W - 1 downto 0);
        writedata : std_logic_vector(G_DATA_W - 1 downto 0);
        read : std_logic;
        write : std_logic;
    end record;

    type t_avalonmm_up is record
        clk : std_logic;
        readdata : std_logic_vector(G_DATA_W - 1 downto 0);
        waitrequest : std_logic;
    end record;

    type t_avalonmm_trace is record
        avalonmm_down : t_avalonmm_down;
        avalonmm_up : t_avalonmm_up;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function avalonmm_down_init return t_avalonmm_down;
    function avalonmm_up_init return t_avalonmm_up;

    procedure write_avalonmm(signal avalonmm_down : out t_avalonmm_down;
                             signal avalonmm_up : in t_avalonmm_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_avalonmm(signal avalonmm_down : out t_avalonmm_down;
                            signal avalonmm_up : in t_avalonmm_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);

end package;

package body tb_bus_avalon_pkg is

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

    function avalonmm_down_init return t_avalonmm_down is
        variable init : t_avalonmm_down;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_avalon_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W)
        severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_avalon_pkg: G_DATA_W must be a power of two (8,16,32,64,...), got " & integer'image(G_DATA_W)
        severity failure;
        assert G_DATA_W >= 8 and G_DATA_W <= 1024
        report "tb_bus_avalon_pkg: G_DATA_W out of supported range [8..1024], got " & integer'image(G_DATA_W)
        severity failure;
        assert G_ADDR_W mod 8 = 0
        report "tb_bus_avalon_pkg: G_ADDR_W must be a multiple of 8, got " & integer'image(G_ADDR_W)
        severity failure;

        init.address := (others => '0');
        init.byteenable := (others => '0');
        init.writedata := (others => '0');
        init.read := '0';
        init.write := '0';
        return init;
    end function;

    function avalonmm_up_init return t_avalonmm_up is
        variable init : t_avalonmm_up;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_avalon_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W)
        severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_avalon_pkg: G_DATA_W must be a power of two (8,16,32,64,...), got " & integer'image(G_DATA_W)
        severity failure;

        init.clk := '0';
        init.readdata := (others => '0');
        init.waitrequest := '0';
        return init;
    end function;

    procedure write_avalonmm(signal avalonmm_down : out t_avalonmm_down;
                             signal avalonmm_up : in t_avalonmm_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable be_base : std_logic_vector(C_BE_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "write_avalonmm: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width)
        severity failure;
        assert access_width <= G_DATA_W
        report "write_avalonmm: access_width (" & integer'image(access_width) & ") exceeds G_DATA_W (" & integer'image(G_DATA_W) & ")"
        severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_BE_W  -1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));
        num_bytes := access_width / 8;
        
        be_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            be_base(i) := '1';
        end loop;

        data_temp := (others => '0');
        data_temp(access_width - 1 downto 0) := std_logic_vector(data(access_width - 1 downto 0));

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        avalonmm_down.address <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        avalonmm_down.byteenable <= std_logic_vector(shift_left(unsigned(be_base), byte_offset));
        avalonmm_down.writedata <= std_logic_vector(shift_left(unsigned(data_temp), byte_offset * 8));

        avalonmm_down.read <= '0';
        avalonmm_down.write <= '1';

        wait until (rising_edge(avalonmm_up.clk) and avalonmm_up.waitrequest = '0') or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        loop
            wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                avalonmm_down <= avalonmm_down_init;
                return;
            end if;
            if avalonmm_up.waitrequest = '0' then
                exit;
            end if;
        end loop;

        successfull := true;
    end procedure;

    procedure read_avalonmm(signal avalonmm_down : out t_avalonmm_down;
                            signal avalonmm_up : in t_avalonmm_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable be_base : std_logic_vector(C_BE_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "read_avalonmm: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width)
        severity failure;
        assert access_width <= G_DATA_W
        report "read_avalonmm: access_width (" & integer'image(access_width) & ") exceeds G_DATA_W (" & integer'image(G_DATA_W) & ")"
        severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_BE_W  -1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));
        num_bytes := access_width / 8;

        be_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            be_base(i) := '1';
        end loop;

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        avalonmm_down.address <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        avalonmm_down.byteenable <= std_logic_vector(shift_left(unsigned(be_base), byte_offset));

        avalonmm_down.writedata <= (others => '0');
        avalonmm_down.read <= '1';
        avalonmm_down.write <= '0';

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        wait until (rising_edge(avalonmm_up.clk) and avalonmm_up.waitrequest = '0') or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        avalonmm_down <= avalonmm_down_init;
        data_temp := std_logic_vector(shift_right(unsigned(avalonmm_up.readdata), byte_offset * 8));

        data := to_unsigned(0, data'length);
        data(access_width - 1 downto 0) := unsigned(data_temp(access_width - 1 downto 0));

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        successfull := true;
    end procedure;

end package body;
