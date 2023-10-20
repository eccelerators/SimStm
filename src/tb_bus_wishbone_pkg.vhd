library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_pkg_bus_wishbone is
    type t_wishbone_down is record
        adr : std_logic_vector(31 downto 0);
        sel : std_logic_vector(3 downto 0);
        data : std_logic_vector(31 downto 0);
        we : std_logic;
        stb : std_logic;
        cyc : std_logic;
    end record;

    type t_wishbone_up is record
        data : std_logic_vector(31 downto 0);
        ack : std_logic;
    end record;

    function wishbone_down_init return t_wishbone_down;
    function wishbone_up_init return t_wishbone_up;

    procedure write_wishbone(signal clk : in std_logic;
                             signal wishbone_down : out t_wishbone_down;
                             signal wishbone_up : in t_wishbone_up;
                             variable address : in std_logic_vector(31 downto 0);
                             variable data : in std_logic_vector(31 downto 0);
                             variable b_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_wishbone(signal clk : in std_logic;
                            signal wishbone_down : out t_wishbone_down;
                            signal wishbone_up : in t_wishbone_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_pkg_bus_wishbone is
    function wishbone_up_init return t_wishbone_up is
        variable init : t_wishbone_up;
    begin
        init.data := (others => 'U');
        init.ack := 'U';
        return init;
    end;

    function wishbone_down_init return t_wishbone_down is
        variable init : t_wishbone_down;
    begin
        init.adr := (others => '0');
        init.sel := (others => '0');
        init.data := (others => '0');
        init.we := '0';
        init.stb := '0';
        init.cyc := '0';
        return init;
    end;

    procedure write_wishbone(signal clk : in std_logic;
                             signal wishbone_down : out t_wishbone_down;
                             signal wishbone_up : in t_wishbone_up;
                             variable address : in std_logic_vector(31 downto 0);
                             variable data : in std_logic_vector(31 downto 0);
                             variable b_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is
        variable sel : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wishbone_down.adr <= address(31 downto 2) & "00";
        case b_width is
            when 8 =>
                sel := "0001";
                data_temp := data and x"000000FF";
            when 16 =>
                sel := "0011";
                data_temp := data and x"0000FFFF";
            when 32 =>
                sel := "1111";
                data_temp := data and x"FFFFFFFF";
            when others =>
        end case;

        case address(1 downto 0) is
            when "00" =>
                wishbone_down.sel <= sel;
                wishbone_down.data <= data_temp;
            when "01" =>
                wishbone_down.sel <= sel(2 downto 0) & '0';
                wishbone_down.data <= data_temp(23 downto 0) & x"00";
            when "10" =>
                wishbone_down.sel <= sel(1 downto 0) & "00";
                wishbone_down.data <= data_temp(15 downto 0) & x"0000";
            when "11" =>
                wishbone_down.sel <= sel(0) & "000";
                wishbone_down.data <= data_temp(7 downto 0) & x"000000";
            when others =>
        end case;

        wishbone_down.we <= '1';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wait on wishbone_up.ack until wishbone_up.ack = '1';
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wishbone_down <= wishbone_down_init;
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        successfull := true;
    end procedure;

    procedure read_wishbone(signal clk : in std_logic;
                            signal wishbone_down : out t_wishbone_down;
                            signal wishbone_up : in t_wishbone_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is
        variable sel : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wishbone_down.adr <= address(31 downto 2) & "00";

        case b_width is
            when 8 => sel := "0001";
            when 16 => sel := "0011";
            when 32 => sel := "1111";
            when others =>
        end case;

        case address(1 downto 0) is
            when "00" =>
                wishbone_down.sel <= sel;
            when "01" =>
                wishbone_down.sel <= sel(2 downto 0) & '0';
            when "10" =>
                wishbone_down.sel <= sel(1 downto 0) & "00";
            when "11" =>
                wishbone_down.sel <= sel(0) & "000";
            when others =>
        end case;

        wishbone_down.data <= (others => '0');
        wishbone_down.we <= '0';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wait on wishbone_up.ack until wishbone_up.ack = '1' or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;

        wishbone_down <= wishbone_down_init;

        case address(1 downto 0) is
            when "00" => data_temp := wishbone_up.data;
            when "01" => data_temp := x"00" & wishbone_up.data(31 downto 8);
            when "10" => data_temp := x"0000" & wishbone_up.data(31 downto 16);
            when "11" => data_temp := x"000000" & wishbone_up.data(31 downto 24);
            when others =>
        end case;
        case b_width is
            when 8 => data := data_temp and x"000000FF";
            when 16 => data := data_temp and x"0000FFFF";
            when 32 => data := data_temp and x"FFFFFFFF";
            when others =>
        end case;

        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_init;
            return;
        end if;
        successfull := true;

    end procedure;
end;
