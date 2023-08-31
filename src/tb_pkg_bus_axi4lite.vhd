library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package tb_pkg_bus_axi4lite is
    type t_axi4lite_down is record
        awvalid : std_logic;
        awaddr : std_logic_vector(31 downto 0);
        awprot : std_logic_vector(2 downto 0);
        wvalid : std_logic;
        wdata : std_logic_vector(31 downto 0);
        wstrb : std_logic_vector(3 downto 0);
        bready : std_logic;
        arvalid : std_logic;
        araddr : std_logic_vector(31 downto 0);
        arprot : std_logic_vector(2 downto 0);
        rready : std_logic;
    end record;

    type t_axi4lite_up is record
        awready : std_logic;
        wready : std_logic;
        bvalid : std_logic;
        bresp : std_logic_vector(1 downto 0);
        arready : std_logic;
        rvalid : std_logic;
        rdata : std_logic_vector(31 downto 0);
        rresp : std_logic_vector(1 downto 0);
    end record;

    function axi4lite_down_init return t_axi4lite_down;
    function axi4lite_up_init return t_axi4lite_up;

    procedure write_axi4lite(signal clk : in std_logic;
                             signal axi4lite_down : out t_axi4lite_down;
                             signal axi4lite_up : in t_axi4lite_up;
                             variable address : in std_logic_vector(31 downto 0);
                             variable data : in std_logic_vector(31 downto 0);
                             variable b_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_axi4lite(signal clk : in std_logic;
                            signal axi4lite_down : out t_axi4lite_down;
                            signal axi4lite_up : in t_axi4lite_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_pkg_bus_axi4lite is
    function axi4lite_up_init return t_axi4lite_up is
        variable init : t_axi4lite_up;
    begin
        init.awready := 'U';
        init.wready := 'U';
        init.bvalid := 'U';
        init.bresp := (others => 'U');
        init.arready := 'U';
        init.rvalid := 'U';
        init.rdata := (others => 'U');
        init.rresp := (others => 'U');
        return init;
    end;

    function axi4lite_down_init return t_axi4lite_down is
        variable init : t_axi4lite_down;
    begin
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
    end;

    procedure write_axi4lite(signal clk : in std_logic;
                             signal axi4lite_down : out t_axi4lite_down;
                             signal axi4lite_up : in t_axi4lite_up;
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
        axi4lite_down <= axi4lite_down_init;
        axi4lite_down.awaddr <= address(31 downto 2) & "00";

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
                axi4lite_down.wstrb <= byteenable;
                axi4lite_down.wdata <= data_temp;
            when "01" =>
                axi4lite_down.wstrb <= byteenable(2 downto 0) & '0';
                axi4lite_down.wdata <= data_temp(23 downto 0) & x"00";
            when "10" =>
                axi4lite_down.wstrb <= byteenable(1 downto 0) & "00";
                axi4lite_down.wdata <= data_temp(15 downto 0) & x"0000";
            when "11" =>
                axi4lite_down.wstrb <= byteenable(0) & "000";
                axi4lite_down.wdata <= data_temp(7 downto 0) & x"000000";
            when others =>
        end case;

        axi4lite_down.awvalid <= '1';
        axi4lite_down.wvalid <= '0';
        axi4lite_down.bready <= '0';
        wait until rising_edge(clk);
        wait on axi4lite_up.awready until axi4lite_up.awready = '0';

        axi4lite_down.awvalid <= '0';
        axi4lite_down.wvalid <= '1';
        axi4lite_down.bready <= '0';
        wait until rising_edge(clk);
        wait on axi4lite_up.wready until axi4lite_up.wready = '0';

        axi4lite_down.awvalid <= '0';
        axi4lite_down.wvalid <= '0';
        axi4lite_down.bready <= '1';
        wait until rising_edge(clk);
        wait on axi4lite_up.bvalid until axi4lite_up.bvalid = '0';

        axi4lite_down.awvalid <= '0';
        axi4lite_down.wvalid <= '0';
        axi4lite_down.bready <= '0';
        axi4lite_down <= axi4lite_down_init;
        wait until rising_edge(clk);
        successfull := true;
    end procedure;

    procedure read_axi4lite(signal clk : in std_logic;
                            signal axi4lite_down : out t_axi4lite_down;
                            signal axi4lite_up : in t_axi4lite_up;
                            variable address : in std_logic_vector(31 downto 0);
                            variable data : out std_logic_vector(31 downto 0);
                            variable b_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        axi4lite_down <= axi4lite_down_init;
        axi4lite_down.araddr <= address(31 downto 2) & "00";

        axi4lite_down.arvalid <= '1';
        axi4lite_down.rready <= '0';
        wait until rising_edge(clk);
        wait on axi4lite_up.arready until axi4lite_up.arready = '0';

        axi4lite_down.arvalid <= '0';
        axi4lite_down.rready <= '1';
        wait until rising_edge(clk);
        wait on axi4lite_up.rvalid until axi4lite_up.rvalid = '0';

        data_temp := axi4lite_up.rdata;
        axi4lite_down <= axi4lite_down_init;
        wait until rising_edge(clk);

        case address(1 downto 0) is
            when "00" => data_temp := data_temp;
            when "01" => data_temp := x"00" & data_temp(31 downto 8);
            when "10" => data_temp := x"0000" & data_temp(31 downto 16);
            when "11" => data_temp := x"000000" & data_temp(31 downto 24);
            when others =>
        end case;
        case b_width is
            when 8 => data := data_temp and x"000000FF";
            when 16 => data := data_temp and x"0000FFFF";
            when 32 => data := data_temp and x"FFFFFFFF";
            when others =>
        end case;
        successfull := true;
    end procedure;
end;
