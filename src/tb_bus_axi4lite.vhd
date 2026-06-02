-------------------------------------------------------------------------------
-- SimStm
--
-- SPDX-License-Identifier: Apache-2.0
--
-- Copyright:
--   - Created by Eccelerators
--
-- Description:
--   AXI4-Lite bus helper package used by SimStm bus access instructions.
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;

package tb_bus_axi4lite_pkg is
    generic(
        G_ADDR_W : positive := 32;
        G_DATA_W : positive := 32
    );
    constant C_STRB_W : positive := G_DATA_W / 8;

    type t_axi4lite_down is record
        awvalid : std_logic;
        awaddr : std_logic_vector(G_ADDR_W - 1 downto 0);
        awprot : std_logic_vector(2 downto 0);
        wvalid : std_logic;
        wdata : std_logic_vector(G_DATA_W - 1 downto 0);
        wstrb : std_logic_vector(C_STRB_W - 1 downto 0);
        bready : std_logic;
        arvalid : std_logic;
        araddr : std_logic_vector(G_ADDR_W - 1 downto 0);
        arprot : std_logic_vector(2 downto 0);
        rready : std_logic;
    end record;

    type t_axi4lite_up is record
        clk : std_logic;
        awready : std_logic;
        wready : std_logic;
        bvalid : std_logic;
        bresp : std_logic_vector(1 downto 0);
        arready : std_logic;
        rvalid : std_logic;
        rdata : std_logic_vector(G_DATA_W - 1 downto 0);
        rresp : std_logic_vector(1 downto 0);
    end record;

    type t_axi4lite_access is record
        wprivileged : std_logic;
        wsecure : std_logic;
        winstruction : std_logic;
        rprivileged : std_logic;
        rsecure : std_logic;
        rinstruction : std_logic;
    end record;

    type t_axi4lite_trace is record
        axi4lite_down : t_axi4lite_down;
        axi4lite_up : t_axi4lite_up;
        axi4lite_access : t_axi4lite_access;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function axi4lite_down_init return t_axi4lite_down;
    function axi4lite_up_init return t_axi4lite_up;

    procedure write_axi4lite(signal axi4lite_down : out t_axi4lite_down;
                             signal axi4lite_up : in t_axi4lite_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_axi4lite(signal axi4lite_down : out t_axi4lite_down;
                            signal axi4lite_up : in t_axi4lite_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);

end package;

package body tb_bus_axi4lite_pkg is

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

    function axi4lite_down_init return t_axi4lite_down is
        variable init : t_axi4lite_down;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_axi4lite_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_axi4lite_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        assert G_ADDR_W mod 8 = 0
        report "tb_bus_axi4lite_pkg: G_ADDR_W must be a multiple of 8, got " & integer'image(G_ADDR_W) severity failure;
        init.awvalid := '0';
        init.awaddr := (others => '0');
        init.awprot := (others => '0');
        init.wvalid := '0';
        init.wdata := (others => '0');
        init.wstrb := (others => '0');
        init.bready := '0';
        init.arvalid := '0';
        init.araddr := (others => '0');
        init.arprot := (others => '0');
        init.rready := '0';
        return init;
    end function;

    function axi4lite_up_init return t_axi4lite_up is
        variable init : t_axi4lite_up;
    begin
        assert G_DATA_W mod 8 = 0
        report "tb_bus_axi4lite_pkg: G_DATA_W must be a multiple of 8, got " & integer'image(G_DATA_W) severity failure;
        assert f_is_power_of_two(G_DATA_W)
        report "tb_bus_axi4lite_pkg: G_DATA_W must be a power of two, got " & integer'image(G_DATA_W) severity failure;
        init.clk := '0';
        init.awready := '0';
        init.wready := '0';
        init.bvalid := '0';
        init.bresp := (others => '0');
        init.arready := '0';
        init.rvalid := '0';
        init.rdata := (others => '0');
        init.rresp := (others => '0');
        return init;
    end function;

    procedure write_axi4lite(signal axi4lite_down : out t_axi4lite_down;
                             signal axi4lite_up : in t_axi4lite_up;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable strb_base : std_logic_vector(C_STRB_W - 1 downto 0);
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        variable num_bytes : integer;
        variable awready_present : boolean := false;
        variable wready_present : boolean := false;
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "write_axi4lite: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "write_axi4lite: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_STRB_W  -1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));
        num_bytes := access_width / 8;

        strb_base := (others => '0');
        for i in 0 to num_bytes - 1 loop
            strb_base(i) := '1';
        end loop;

        data_temp := (others => '0');
        data_temp(access_width - 1 downto 0) := std_logic_vector(data(access_width - 1 downto 0));

        wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            axi4lite_down <= axi4lite_down_init;
            return;
        end if;

        axi4lite_down <= axi4lite_down_init;
        axi4lite_down.awaddr <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        axi4lite_down.wstrb <= std_logic_vector(shift_left(unsigned(strb_base), byte_offset));
        axi4lite_down.wdata <= std_logic_vector(shift_left(unsigned(data_temp), byte_offset * 8));

        axi4lite_down.awvalid <= '1';
        axi4lite_down.wvalid <= '1';
        axi4lite_down.bready <= '0';

        loop
            wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                axi4lite_down <= axi4lite_down_init;
                return;
            end if;
            if axi4lite_up.awready = '1' then
                axi4lite_down.awvalid <= '0';
                awready_present := true;
            end if;
            if axi4lite_up.wready = '1' then
                axi4lite_down.wvalid <= '0';
                wready_present := true;
            end if;
            if awready_present and wready_present then
                exit;
            end if;
        end loop;

        axi4lite_down.bready <= '1';
        loop
            wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                axi4lite_down <= axi4lite_down_init;
                return;
            end if;
            if axi4lite_up.bvalid = '1' then
                exit;
            end if;
        end loop;

        axi4lite_down <= axi4lite_down_init;
        successfull := true;
    end procedure;

    procedure read_axi4lite(signal axi4lite_down : out t_axi4lite_down;
                            signal axi4lite_up : in t_axi4lite_up;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is
        variable num_of_address_bits_for_bytes : integer;
        variable byte_offset : integer;
        variable data_temp : std_logic_vector(G_DATA_W - 1 downto 0);
        constant start_time : time := now;
    begin
        assert access_width mod 8 = 0 and f_is_power_of_two(access_width)
        report "read_axi4lite: access_width must be a power-of-two multiple of 8, got " & integer'image(access_width) severity failure;
        assert access_width <= G_DATA_W
        report "read_axi4lite: access_width exceeds G_DATA_W" severity failure;

        successfull := false;
        num_of_address_bits_for_bytes := get_num_bits(C_STRB_W  -1);
        byte_offset := to_integer(address(num_of_address_bits_for_bytes - 1 downto 0));

        wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            axi4lite_down <= axi4lite_down_init;
            return;
        end if;

        axi4lite_down <= axi4lite_down_init;
        axi4lite_down.araddr <= std_logic_vector(address(G_ADDR_W - 1 downto 0));
        axi4lite_down.arvalid <= '1';
        axi4lite_down.rready <= '0';

        loop
            wait until rising_edge(axi4lite_up.clk);
            if axi4lite_up.arready = '1' then
                exit;
            end if;
        end loop;

        axi4lite_down.arvalid <= '0';
        axi4lite_down.rready <= '1';

        loop
            wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                axi4lite_down <= axi4lite_down_init;
                return;
            end if;
            if axi4lite_up.rvalid = '1' then
                exit;
            end if;
        end loop;

        data_temp := axi4lite_up.rdata;
        axi4lite_down <= axi4lite_down_init;

        wait until rising_edge(axi4lite_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            axi4lite_down <= axi4lite_down_init;
            return;
        end if;

        data_temp := std_logic_vector(shift_right(unsigned(data_temp), byte_offset * 8));

        data := to_unsigned(0, data'length);
        data(access_width - 1 downto 0) := unsigned(data_temp(access_width - 1 downto 0));

        successfull := true;
    end procedure;

end package body;
