library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_axi4lite_32_pkg is
    type t_axi4lite_down_32 is record
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

    type t_axi4lite_up_32 is record
        clk : std_logic;
        awready : std_logic;
        wready : std_logic;
        bvalid : std_logic;
        bresp : std_logic_vector(1 downto 0);
        arready : std_logic;
        rvalid : std_logic;
        rdata : std_logic_vector(31 downto 0);
        rresp : std_logic_vector(1 downto 0);
    end record;
    
    type t_axi4lite_access is
    record
        wprivileged : std_logic;
        wsecure : std_logic;
        winstruction : std_logic;
        rprivileged : std_logic;
        rsecure : std_logic;
        rinstruction : std_logic;
    end record;
    
    type t_axi4lite_trace_32 is record
        axi4lite_down_32 : t_axi4lite_down_32;
        axi4lite_up_32 : t_axi4lite_up_32;
        axi4lite_access : t_axi4lite_access;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function axi4lite_down_32_init return t_axi4lite_down_32;
    function axi4lite_up_32_init return t_axi4lite_up_32;

    procedure write_axi4lite_32(signal axi4lite_down : out t_axi4lite_down_32;
                             signal axi4lite_up : in t_axi4lite_up_32;
                             variable address : in unsigned(c_stm_value_width - 1 downto 0);
                             variable data : in unsigned(c_stm_value_width - 1 downto 0);
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_axi4lite_32(signal axi4lite_down : out t_axi4lite_down_32;
                            signal axi4lite_up : in t_axi4lite_up_32;
                            variable address : in unsigned(c_stm_value_width - 1 downto 0);
                            variable data : out unsigned(c_stm_value_width - 1 downto 0);
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_bus_axi4lite_32_pkg is

    function axi4lite_down_32_init return t_axi4lite_down_32 is
        variable init : t_axi4lite_down_32;
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

    function axi4lite_up_32_init return t_axi4lite_up_32 is
        variable init : t_axi4lite_up_32;
    begin
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
    end;

    procedure write_axi4lite_32(signal axi4lite_down : out t_axi4lite_down_32;
                             signal axi4lite_up : in t_axi4lite_up_32;
                             variable address : in unsigned(c_stm_value_width - 1 downto 0);
                             variable data : in unsigned(c_stm_value_width - 1 downto 0);
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is

        variable byteenable : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
        variable awready_present : boolean := false;
        variable wready_present : boolean := false;
    begin
        successfull := false;
        wait until rising_edge(axi4lite_up.clk);
        axi4lite_down <= axi4lite_down_32_init;
        axi4lite_down.awaddr <= std_logic_vector(address(31 downto 0));

        case access_width is
            when 8 =>
                byteenable := "0001";
                data_temp := std_logic_vector(data(31 downto 0)) and x"000000FF";
            when 16 =>
                byteenable := "0011";
                data_temp := std_logic_vector(data(31 downto 0)) and x"0000FFFF";
            when 32 =>
                byteenable := "1111";
                data_temp := std_logic_vector(data(31 downto 0)) and x"FFFFFFFF";
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
        axi4lite_down.wvalid <= '1';
        axi4lite_down.bready <= '0';
        loop
        	wait until rising_edge(axi4lite_up.clk);
	        if axi4lite_up.awready then
	         	axi4lite_down.awvalid <= '0';
	        	awready_present := true;
	        end if;
	        if axi4lite_up.wready then
	            axi4lite_down.wvalid <= '0';
	        	wready_present := true;
	        end if;
        	if awready_present and wready_present then
        		exit;
        	end if;    
        end loop;

        axi4lite_down.bready <= '1';
        loop
        	wait until rising_edge(axi4lite_up.clk);
        	if axi4lite_up.bvalid then
        		exit;
        	end if;
        end loop;        

        axi4lite_down.bready <= '0';
        axi4lite_down <= axi4lite_down_32_init;
        wait until rising_edge(axi4lite_up.clk);
        successfull := true;
    end procedure;

    procedure read_axi4lite_32(signal axi4lite_down : out t_axi4lite_down_32;
                            signal axi4lite_up : in t_axi4lite_up_32;
                            variable address : in unsigned(c_stm_value_width - 1 downto 0);
                            variable data : out unsigned(c_stm_value_width - 1 downto 0);
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is

        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(axi4lite_up.clk);        
        axi4lite_down <= axi4lite_down_32_init;
        axi4lite_down.araddr <= std_logic_vector(address(31 downto 0));

        axi4lite_down.arvalid <= '1';
        axi4lite_down.rready <= '0';
        
        loop
        	wait until rising_edge(axi4lite_up.clk);
        	if axi4lite_up.arready then
        		exit;
        	end if;
        end loop;   

        axi4lite_down.arvalid <= '0';
        axi4lite_down.rready <= '1';   
        loop
        	wait until rising_edge(axi4lite_up.clk);
        	if axi4lite_up.rvalid then
        		exit;
        	end if;
        end loop;           
        
        data_temp := axi4lite_up.rdata;
        axi4lite_down <= axi4lite_down_32_init;
        wait until rising_edge(axi4lite_up.clk);

        case address(1 downto 0) is
            when "00" => data_temp := data_temp;
            when "01" => data_temp := x"00" & data_temp(31 downto 8);
            when "10" => data_temp := x"0000" & data_temp(31 downto 16);
            when "11" => data_temp := x"000000" & data_temp(31 downto 24);
            when others =>
        end case;
        
        data := (others => '0');
        case access_width is
            when 8 => data(31 downto 0) := unsigned(data_temp and x"000000FF");
            when 16 => data(31 downto 0) := unsigned(data_temp and x"0000FFFF");
            when 32 => data(31 downto 0) := unsigned(data_temp and x"FFFFFFFF");
            when others =>
        end case;
        successfull := true;
    end procedure;

end package body;
