library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_avalon_64_pkg is
    type t_avalonmm_down_64 is record
        address : std_logic_vector(31 downto 0);
        byteenable : std_logic_vector(7 downto 0);
        writedata : std_logic_vector(63 downto 0);
        read : std_logic;
        write : std_logic;
    end record;

    type t_avalonmm_up_64 is record
        clk : std_logic;
        readdata : std_logic_vector(63 downto 0);
        waitrequest : std_logic;
    end record;
    
    type t_avalonmm_trace_64 is record
        avalonmm_down : t_avalonmm_down_64;
        avalonmm_up : t_avalonmm_up_64;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function avalonmm_down_64_init return t_avalonmm_down_64;
    function avalonmm_up_64_init return t_avalonmm_up_64;

    procedure write_avalonmm_64(signal avalonmm_down : out t_avalonmm_down_64;
                             signal avalonmm_up : in t_avalonmm_up_64;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_avalonmm_64(signal avalonmm_down : out t_avalonmm_down_64;
                            signal avalonmm_up : in t_avalonmm_up_64;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_bus_avalon_64_pkg is

    function avalonmm_down_64_init return t_avalonmm_down_64 is
        variable init : t_avalonmm_down_64;
    begin
        init.address := (others => '0');
        init.byteenable := (others => '0');
        init.writedata := (others => '0');
        init.read := '0';
        init.write := '0';
        return init;
    end;
    
    function avalonmm_up_64_init return t_avalonmm_up_64 is
        variable init : t_avalonmm_up_64;
    begin
        init.clk := '0';
        init.readdata := (others => '0');
        init.waitrequest := '0';
        return init;
    end;

    procedure write_avalonmm_64(signal avalonmm_down : out t_avalonmm_down_64;
                             signal avalonmm_up : in t_avalonmm_up_64;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is

        variable byteenable : std_logic_vector(7 downto 0);
        variable data_temp : std_logic_vector(63 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;
        avalonmm_down.address <= std_logic_vector(address(31 downto 0));       
        case access_width is
            when 8 =>
                byteenable := "00000001";
                data_temp := std_logic_vector(data(63 downto 0)) and x"00000000000000FF";
            when 16 =>
                byteenable := "00000011";
                data_temp := std_logic_vector(data(63 downto 0)) and x"000000000000FFFF";
            when 32 =>
                byteenable := "00001111";
                data_temp := std_logic_vector(data(63 downto 0)) and x"00000000FFFFFFFF";
             when 64 =>
                byteenable := "11111111";
                data_temp := std_logic_vector(data(63 downto 0)) and x"FFFFFFFFFFFFFFFF";               
            when others =>
        end case;
       
        case address(2 downto 0) is
            when "000" =>
                avalonmm_down.byteenable <= byteenable;
                avalonmm_down.writedata <= data_temp;
            when "001" =>
                avalonmm_down.byteenable <= byteenable(6 downto 0) & '0';
                avalonmm_down.writedata <= data_temp(55 downto 0) & x"00";
            when "010" =>
                avalonmm_down.byteenable <= byteenable(5 downto 0) & "00";
                avalonmm_down.writedata <= data_temp(47 downto 0) & x"0000";
            when "011" =>
                avalonmm_down.byteenable <= byteenable(4 downto 0) & "000";
                avalonmm_down.writedata <= data_temp(39 downto 0) & x"000000";
            when "100" =>
                avalonmm_down.byteenable <= byteenable(3 downto 0) & "0000";
                avalonmm_down.writedata <= data_temp(31 downto 0) & x"00000000";
            when "101" =>
                avalonmm_down.byteenable <= byteenable(2 downto 0) & "00000";
                avalonmm_down.writedata <= data_temp(23 downto 0) & x"0000000000";
            when "110" =>
                avalonmm_down.byteenable <= byteenable(1 downto 0) & "000000";
                avalonmm_down.writedata <= data_temp(15 downto 0) & x"000000000000";
            when "111" =>
                avalonmm_down.byteenable <= byteenable(0) & "0000000";
                avalonmm_down.writedata <= data_temp(7 downto 0) & x"00000000000000";                
            when others =>
        end case;

        avalonmm_down.read <= '0';
        avalonmm_down.write <= '1';
        wait until (rising_edge(avalonmm_up.clk) and avalonmm_up.waitrequest = '0') or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;

        avalonmm_down <= avalonmm_down_64_init;
        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;

        successfull := true;
    end procedure;

    procedure read_avalonmm_64(signal avalonmm_down : out t_avalonmm_down_64;
                            signal avalonmm_up : in t_avalonmm_up_64;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is

        variable byteenable : std_logic_vector(7 downto 0);
        variable data_temp : std_logic_vector(63 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;
        avalonmm_down.address <= std_logic_vector(address(31 downto 0));

        case access_width is
            when 8 =>
                byteenable := "00000001";
            when 16 =>
                byteenable := "00000011";
            when 32 =>
                byteenable := "00001111";
            when 64 =>
                byteenable := "11111111";            
            when others =>
        end case;

        case address(2 downto 0) is
            when "000" =>
                avalonmm_down.byteenable <= byteenable;
            when "001" =>
                avalonmm_down.byteenable <= byteenable(6 downto 0) & '0';
            when "010" =>
                avalonmm_down.byteenable <= byteenable(5 downto 0) & "00";
            when "011" =>
                avalonmm_down.byteenable <= byteenable(4 downto 0) & "000";
            when "100" =>
                avalonmm_down.byteenable <= byteenable(3 downto 0) & "0000";
            when "101" =>
                avalonmm_down.byteenable <= byteenable(2 downto 0) & "00000";
            when "110" =>
                avalonmm_down.byteenable <= byteenable(1 downto 0) & "000000";
            when "111" =>
                avalonmm_down.byteenable <= byteenable(0) & "0000000";               
            when others =>
        end case;        

        avalonmm_down.writedata <= (others => '0');
        avalonmm_down.read <= '1';
        avalonmm_down.write <= '0';

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;

        wait until (rising_edge(avalonmm_up.clk) and avalonmm_up.waitrequest = '0') or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;

        avalonmm_down <= avalonmm_down_64_init;

        case address(2 downto 0) is
            when "000" => data_temp := avalonmm_up.readdata(63 downto 0);
            when "001" => data_temp := x"00" & avalonmm_up.readdata(63 downto 8);
            when "010" => data_temp := x"0000" & avalonmm_up.readdata(63 downto 16);
            when "011" => data_temp := x"000000" & avalonmm_up.readdata(63 downto 24);
            when "100" => data_temp := x"00000000" & avalonmm_up.readdata(63 downto 32);
            when "101" => data_temp := x"0000000000" & avalonmm_up.readdata(63 downto 40);
            when "110" => data_temp := x"000000000000" & avalonmm_up.readdata(63 downto 48);
            when "111" => data_temp := x"00000000000000" & avalonmm_up.readdata(63 downto 56);            
            when others =>
        end case;
        
        data := to_unsigned(0, data'length);
        case access_width is
            when 8 => data(63 downto 0) := unsigned(data_temp and x"00000000000000FF");
            when 16 => data(63 downto 0) := unsigned(data_temp and x"000000000000FFFF");
            when 32 => data(63 downto 0) := unsigned(data_temp and x"00000000FFFFFFFF");
            when 64 => data(63 downto 0) := unsigned(data_temp and x"FFFFFFFFFFFFFFFF");
            when others =>
        end case;

        wait until rising_edge(avalonmm_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            avalonmm_down <= avalonmm_down_64_init;
            return;
        end if;

        successfull := true;
    end procedure;

end package body;
