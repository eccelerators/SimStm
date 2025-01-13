library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_wishbone_128_pkg is

    type t_wishbone_down_128 is record
        adr : std_logic_vector(31 downto 0);
        sel : std_logic_vector(15 downto 0);
        data : std_logic_vector(127 downto 0);
        we : std_logic;
        stb : std_logic;
        cyc : std_logic;
    end record;

    type t_wishbone_up_128 is record
        clk : std_logic;
        data : std_logic_vector(127 downto 0);
        ack : std_logic;
    end record;
    
    type t_wishbone_trace_128 is record
        wishbone_down : t_wishbone_down_128;
        wishbone_up : t_wishbone_up_128;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function wishbone_down_128_init return t_wishbone_down_128;
    function wishbone_up_128_init return t_wishbone_up_128;

    procedure write_wishbone_128(signal wishbone_down : out t_wishbone_down_128;
                             signal wishbone_up : in t_wishbone_up_128;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_wishbone_128(signal wishbone_down : out t_wishbone_down_128;
                            signal wishbone_up : in t_wishbone_up_128;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_bus_wishbone_128_pkg is

    function wishbone_down_128_init return t_wishbone_down_128 is
        variable init : t_wishbone_down_128;
    begin
        init.adr := (others => '0');
        init.sel := (others => '0');
        init.data := (others => '0');
        init.we := '0';
        init.stb := '0';
        init.cyc := '0';
        return init;
    end;
    
    function wishbone_up_128_init return t_wishbone_up_128 is
        variable init : t_wishbone_up_128;
    begin
        init.clk := '0';
        init.data := (others => '0');
        init.ack := '0';
        return init;
    end;

    procedure write_wishbone_128(signal wishbone_down : out t_wishbone_down_128;
                             signal wishbone_up : in t_wishbone_up_128;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is

        variable sel : std_logic_vector(15 downto 0);
        variable data_temp : std_logic_vector(127 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_128_init;
            return;
        end if;
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));
        case access_width is
            when 8 =>
                sel := "0000000000000001";
                data_temp := std_logic_vector(data(127 downto 0)) and x"000000000000000000000000000000FF";
            when 16 =>
                sel := "0000000000000011";
                data_temp := std_logic_vector(data(127 downto 0)) and x"0000000000000000000000000000FFFF";
            when 32 =>
                sel := "0000000000001111";
                data_temp := std_logic_vector(data(127 downto 0)) and x"000000000000000000000000FFFFFFFF";
             when 64 =>
                sel := "0000000011111111";
                data_temp := std_logic_vector(data(127 downto 0)) and x"0000000000000000FFFFFFFFFFFFFFFF";
             when 128 =>
                sel := "1111111111111111";
                data_temp := std_logic_vector(data(127 downto 0)) and x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";               
            when others =>
        end case;

        case address(3 downto 0) is
            when "0000" =>
                wishbone_down.sel <= sel;
                wishbone_down.data <= data_temp;
            when "0001" =>
                wishbone_down.sel <= sel(14 downto 0) & '0';
                wishbone_down.data <= data_temp(119 downto 0) & x"00";
            when "0010" =>
                wishbone_down.sel <= sel(13 downto 0) & "00";
                wishbone_down.data <= data_temp(111 downto 0) & x"0000";
            when "0011" =>
                wishbone_down.sel <= sel(12 downto 0) & "000";
                wishbone_down.data <= data_temp(103 downto 0) & x"000000";
            when "0100" =>
                wishbone_down.sel <= sel(11 downto 0) & "0000";
                wishbone_down.data <= data_temp(95 downto 0) & x"00000000";
            when "0101" =>
                wishbone_down.sel <= sel(10 downto 0) & "00000";
                wishbone_down.data <= data_temp(87 downto 0) & x"0000000000";
            when "0110" =>
                wishbone_down.sel <= sel(9 downto 0) & "000000";
                wishbone_down.data <= data_temp(79 downto 0) & x"000000000000";
            when "0111" =>
                wishbone_down.sel <= sel(8 downto 0) & "0000000";
                wishbone_down.data <= data_temp(71 downto 0) & x"00000000000000";  
            when "1000" =>
                wishbone_down.sel <= sel(7 downto 0) & "00000000";
                wishbone_down.data <= data_temp(63 downto 0) & x"0000000000000000";  
            when "1001" =>
                wishbone_down.sel <= sel(6 downto 0) & "000000000";
                wishbone_down.data <= data_temp(55 downto 0) & x"000000000000000000";
            when "1010" =>
                wishbone_down.sel <= sel(5 downto 0) & "0000000000";
                wishbone_down.data <= data_temp(47 downto 0) & x"00000000000000000000";
            when "1011" =>
                wishbone_down.sel <= sel(4 downto 0) & "00000000000";
                wishbone_down.data <= data_temp(39 downto 0) & x"0000000000000000000000";
            when "1100" =>
                wishbone_down.sel <= sel(3 downto 0) & "000000000000";
                wishbone_down.data <= data_temp(31 downto 0) & x"000000000000000000000000";
            when "1101" =>
                wishbone_down.sel <= sel(2 downto 0) & "0000000000000";
                wishbone_down.data <= data_temp(23 downto 0) & x"00000000000000000000000000";
            when "1110" =>
                wishbone_down.sel <= sel(1 downto 0) & "00000000000000";
                wishbone_down.data <= data_temp(15 downto 0) & x"0000000000000000000000000000";
            when "1111" =>
                wishbone_down.sel <= sel(0) & "000000000000000";
                wishbone_down.data <= data_temp(7 downto 0) & x"000000000000000000000000000000";                               
            when others =>
        end case;

        wishbone_down.we <= '1';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_128_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_128_init;
                return;
            end if;
            if wishbone_up.ack then
                exit;
            end if;
        end loop;  
        wishbone_down <= wishbone_down_128_init;
        successfull := true;
    end procedure;

    procedure read_wishbone_128(signal wishbone_down : out t_wishbone_down_128;
                            signal wishbone_up : in t_wishbone_up_128;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is

        variable sel : std_logic_vector(15 downto 0);
        variable data_temp : std_logic_vector(127 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;       
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_128_init;
            return;
        end if;        
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));

        case access_width is
            when 8 => 
                sel := "0000000000000001";
            when 16 => 
                sel := "0000000000000011";
            when 32 => 
                sel := "0000000000001111";
            when 64 => 
                sel := "0000000011111111";
            when 128 => 
                sel := "1111111111111111";                
            when others =>
        end case;

        case address(3 downto 0) is
            when "0000" =>
                wishbone_down.sel <= sel;
            when "0001" =>
                wishbone_down.sel <= sel(14 downto 0) & '0';
            when "0010" =>
                wishbone_down.sel <= sel(13 downto 0) & "00";
            when "0011" =>
                wishbone_down.sel <= sel(12 downto 0) & "000";
            when "0100" =>
                wishbone_down.sel <= sel(11 downto 0) & "0000";
            when "0101" =>
                wishbone_down.sel <= sel(10 downto 0) & "00000";
            when "0110" =>
                wishbone_down.sel <= sel(9 downto 0) & "000000";
            when "0111" =>
                wishbone_down.sel <= sel(8 downto 0) & "0000000";
            when "1000" =>
                wishbone_down.sel <= sel(7 downto 0) & "00000000";
            when "1001" =>
                wishbone_down.sel <= sel(6 downto 0) & "000000000";
            when "1010" =>
                wishbone_down.sel <= sel(5 downto 0) & "0000000000";
            when "1011" =>
                wishbone_down.sel <= sel(4 downto 0) & "00000000000";
            when "1100" =>
                wishbone_down.sel <= sel(3 downto 0) & "000000000000";
            when "1101" =>
                wishbone_down.sel <= sel(2 downto 0) & "0000000000000";
            when "1110" =>
                wishbone_down.sel <= sel(1 downto 0) & "00000000000000";
            when "1111" =>
                wishbone_down.sel <= sel(0) & "000000000000000";                                
            when others =>
        end case;

        wishbone_down.data <= (others => '0');
        wishbone_down.we <= '0';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_128_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_128_init;
                return;
            end if;
            if wishbone_up.ack then
                exit;
            end if;
        end loop;  

        wishbone_down <= wishbone_down_128_init;

        case address(3 downto 0) is
            when "0000" => data_temp := wishbone_up.data(127 downto 0);
            when "0001" => data_temp := x"00" & wishbone_up.data(127 downto 8);
            when "0010" => data_temp := x"0000" & wishbone_up.data(127 downto 16);
            when "0011" => data_temp := x"000000" & wishbone_up.data(127 downto 24);
            when "0100" => data_temp := x"00000000" & wishbone_up.data(127 downto 32);
            when "0101" => data_temp := x"0000000000" & wishbone_up.data(127 downto 40);
            when "0110" => data_temp := x"000000000000" & wishbone_up.data(127 downto 48);
            when "0111" => data_temp := x"00000000000000" & wishbone_up.data(127 downto 56);
            when "1000" => data_temp := x"0000000000000000" & wishbone_up.data(127 downto 64);
            when "1001" => data_temp := x"000000000000000000" & wishbone_up.data(127 downto 72);
            when "1010" => data_temp := x"00000000000000000000" & wishbone_up.data(127 downto 80);
            when "1011" => data_temp := x"0000000000000000000000" & wishbone_up.data(127 downto 88);
            when "1100" => data_temp := x"000000000000000000000000" & wishbone_up.data(127 downto 96);
            when "1101" => data_temp := x"00000000000000000000000000" & wishbone_up.data(127 downto 104);
            when "1110" => data_temp := x"0000000000000000000000000000" & wishbone_up.data(127 downto 112);
            when "1111" => data_temp := x"000000000000000000000000000000" & wishbone_up.data(127 downto 120);                       
            when others =>
        end case;
        data := to_unsigned(0, data'length);
        case access_width is
            when 8 => data(127 downto 0) := unsigned(data_temp and x"000000000000000000000000000000FF");
            when 16 => data(127 downto 0) := unsigned(data_temp and x"0000000000000000000000000000FFFF");
            when 32 => data(127 downto 0) := unsigned(data_temp and x"000000000000000000000000FFFFFFFF");
            when 64 => data(127 downto 0) := unsigned(data_temp and x"0000000000000000FFFFFFFFFFFFFFFF");
            when 128 => data(127 downto 0) := unsigned(data_temp and x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");            
            when others =>
        end case;

        wishbone_down <= wishbone_down_128_init;
        successfull := true;

    end procedure;

end package body;
