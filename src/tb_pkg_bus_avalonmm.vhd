library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_pkg_bus_avalonmm is
    type t_avalonmm_down is record
        address : std_logic_vector(31 downto 0);
        byteenable : std_logic_vector(3 downto 0);
        writedata : std_logic_vector(31 downto 0);
        read : std_logic;
        write : std_logic;
    end record;

    type t_avalonmm_up is record
        readdata : std_logic_vector(31 downto 0);
        waitrequest : std_logic;
    end record;

    function avalonmm_down_init return t_avalonmm_down;
    function avalonmm_up_init return t_avalonmm_up;

    procedure write_avalonmm(signal clk : in std_logic;
                             signal avalonmm_down : out t_avalonmm_down;
                             signal avalonmm_up : in t_avalonmm_up;
                             variable address : in std_logic_vector(31 downto 0);
                             variable data : in std_logic_vector(31 downto 0);
                             variable b_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_avalonmm(signal clk : in std_logic;
                            signal avalonmm_down : out t_avalonmm_down;
                            signal avalonmm_up : in t_avalonmm_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_pkg_bus_avalonmm is
    function avalonmm_up_init return t_avalonmm_up is
        variable init : t_avalonmm_up;
    begin
        init.readdata := (others => 'U');
        init.waitrequest := 'U';
        return init;
    end;

    function avalonmm_down_init return t_avalonmm_down is
        variable init : t_avalonmm_down;
    begin
        init.address := (others => '0');
        init.byteenable := (others => '0');
        init.writedata := (others => '0');
        init.read := '0';
        init.write := '0';
        return init;
    end;

    procedure write_avalonmm(signal clk : in std_logic;
                             signal avalonmm_down : out t_avalonmm_down;
                             signal avalonmm_up : in t_avalonmm_up;
                             variable address : in std_logic_vector(31 downto 0);
                             variable data : in std_logic_vector(31 downto 0);
                             variable b_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is
        variable byteenable : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        avalonmm_down.address <= address(31 downto 2) & "00";
        case b_width is
            when 8 =>
                byteenable := "0001";
                data_temp := data and x"000000FF";
            when 16 =>
                byteenable := "0011";
                data_temp := data and x"0000FFFF";
            when 32 =>
                byteenable := "1111";
                data_temp := data and x"FFFFFFFF";
            when others =>
        end case;

        case address(1 downto 0) is
            when "00" =>
                avalonmm_down.byteenable <= byteenable;
                avalonmm_down.writedata <= data_temp;
            when "01" =>
                avalonmm_down.byteenable <= byteenable(2 downto 0) & '0';
                avalonmm_down.writedata <= data_temp(23 downto 0) & x"00";
            when "10" =>
                avalonmm_down.byteenable <= byteenable(1 downto 0) & "00";
                avalonmm_down.writedata <= data_temp(15 downto 0) & x"0000";
            when "11" =>
                avalonmm_down.byteenable <= byteenable(0) & "000";
                avalonmm_down.writedata <= data_temp(7 downto 0) & x"000000";
            when others =>
        end case;

        avalonmm_down.read <= '0';
        avalonmm_down.write <= '1';
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        wait on avalonmm_up.waitrequest until avalonmm_up.waitrequest = '0' or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        avalonmm_down <= avalonmm_down_init;
        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        successfull := true;
    end procedure;

    procedure read_avalonmm(signal clk : in std_logic;
                            signal avalonmm_down : out t_avalonmm_down;
                            signal avalonmm_up : in t_avalonmm_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is
        variable byteenable : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        avalonmm_down.address <= address(31 downto 2) & "00";

        case b_width is
            when 8 => byteenable := "0001";
            when 16 => byteenable := "0011";
            when 32 => byteenable := "1111";
            when others =>
        end case;

        case address(1 downto 0) is
            when "00" =>
                avalonmm_down.byteenable <= byteenable;
            when "01" =>
                avalonmm_down.byteenable <= byteenable(2 downto 0) & '0';
            when "10" =>
                avalonmm_down.byteenable <= byteenable(1 downto 0) & "00";
            when "11" =>
                avalonmm_down.byteenable <= byteenable(0) & "000";
            when others =>
        end case;

        avalonmm_down.writedata <= (others => '0');
        avalonmm_down.read <= '1';
        avalonmm_down.write <= '0';

        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        wait on avalonmm_up.waitrequest until avalonmm_up.waitrequest = '0' or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        wait until rising_edge(clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        avalonmm_down <= avalonmm_down_init;

        case address(1 downto 0) is
            when "00" => data_temp := avalonmm_up.readdata;
            when "01" => data_temp := x"00" & avalonmm_up.readdata(31 downto 8);
            when "10" => data_temp := x"0000" & avalonmm_up.readdata(31 downto 16);
            when "11" => data_temp := x"000000" & avalonmm_up.readdata(31 downto 24);
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
            avalonmm_down <= avalonmm_down_init;
            return;
        end if;

        successfull := true;
    end procedure;
end;
