library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_wishbone_256_pkg is

    type t_wishbone_down_256 is record
        adr : std_logic_vector(31 downto 0);
        sel : std_logic_vector(31 downto 0);
        data : std_logic_vector(255 downto 0);
        we : std_logic;
        stb : std_logic;
        cyc : std_logic;
    end record;

    type t_wishbone_up_256 is record
        clk : std_logic;
        data : std_logic_vector(255 downto 0);
        ack : std_logic;
    end record;
    
    type t_wishbone_trace_256 is record
        wishbone_down : t_wishbone_down_256;
        wishbone_up : t_wishbone_up_256;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function wishbone_down_256_init return t_wishbone_down_256;
    function wishbone_up_256_init return t_wishbone_up_256;

    procedure write_wishbone_256(signal wishbone_down : out t_wishbone_down_256;
                             signal wishbone_up : in t_wishbone_up_256;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_wishbone_256(signal wishbone_down : out t_wishbone_down_256;
                            signal wishbone_up : in t_wishbone_up_256;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_bus_wishbone_256_pkg is

    function wishbone_down_256_init return t_wishbone_down_256 is
        variable init : t_wishbone_down_256;
    begin
        init.adr := (others => '0');
        init.sel := (others => '0');
        init.data := (others => '0');
        init.we := '0';
        init.stb := '0';
        init.cyc := '0';
        return init;
    end;
    
    function wishbone_up_256_init return t_wishbone_up_256 is
        variable init : t_wishbone_up_256;
    begin
        init.clk := '0';
        init.data := (others => '0');
        init.ack := '0';
        return init;
    end;

    procedure write_wishbone_256(signal wishbone_down : out t_wishbone_down_256;
                             signal wishbone_up : in t_wishbone_up_256;
                             variable address : in unsigned;
                             variable data : in unsigned;
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is

        variable sel : std_logic_vector(31 downto 0);
        variable data_temp : std_logic_vector(255 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_256_init;
            return;
        end if;
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));
        case access_width is
            when 8 =>
                sel := "00000000000000000000000000000001";
                data_temp := std_logic_vector(data(255 downto 0)) and x"00000000000000000000000000000000000000000000000000000000000000FF";
            when 16 =>
                sel := "00000000000000000000000000000011";
                data_temp := std_logic_vector(data(255 downto 0)) and x"000000000000000000000000000000000000000000000000000000000000FFFF";
            when 32 =>
                sel := "00000000000000000000000000001111";
                data_temp := std_logic_vector(data(255 downto 0)) and x"00000000000000000000000000000000000000000000000000000000FFFFFFFF";
             when 64 =>
                sel := "00000000000000000000000011111111";
                data_temp := std_logic_vector(data(255 downto 0)) and x"000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF";
             when 128 =>
                sel := "00000000000000001111111111111111";
                data_temp := std_logic_vector(data(255 downto 0)) and x"00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
             when 256 =>
                sel := "11111111111111111111111111111111";
                data_temp := std_logic_vector(data(255 downto 0)) and x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";                 
            when others =>
        end case;

        case address(4 downto 0) is
            when "00000" =>
                wishbone_down.sel <= sel;
                wishbone_down.data <= data_temp;
            when "00001" =>
                wishbone_down.sel <= sel(30 downto 0) & '0';
                wishbone_down.data <= data_temp(247 downto 0) & x"00";
            when "00010" =>
                wishbone_down.sel <= sel(29 downto 0) & "00";
                wishbone_down.data <= data_temp(239 downto 0) & x"0000";
            when "00011" =>
                wishbone_down.sel <= sel(28 downto 0) & "000";
                wishbone_down.data <= data_temp(231 downto 0) & x"000000";
            when "00100" =>
                wishbone_down.sel <= sel(27 downto 0) & "0000";
                wishbone_down.data <= data_temp(223 downto 0) & x"00000000";
            when "00101" =>
                wishbone_down.sel <= sel(26 downto 0) & "00000";
                wishbone_down.data <= data_temp(215 downto 0) & x"0000000000";
            when "00110" =>
                wishbone_down.sel <= sel(25 downto 0) & "000000";
                wishbone_down.data <= data_temp(207 downto 0) & x"000000000000";
            when "00111" =>
                wishbone_down.sel <= sel(24 downto 0) & "0000000";
                wishbone_down.data <= data_temp(199 downto 0) & x"00000000000000";  
            when "01000" =>
                wishbone_down.sel <= sel(23 downto 0) & "00000000";
                wishbone_down.data <= data_temp(191 downto 0) & x"0000000000000000";  
            when "01001" =>
                wishbone_down.sel <= sel(22 downto 0) & "000000000";
                wishbone_down.data <= data_temp(183 downto 0) & x"000000000000000000";
            when "01010" =>
                wishbone_down.sel <= sel(21 downto 0) & "0000000000";
                wishbone_down.data <= data_temp(175 downto 0) & x"00000000000000000000";
            when "01011" =>
                wishbone_down.sel <= sel(20 downto 0) & "00000000000";
                wishbone_down.data <= data_temp(167 downto 0) & x"0000000000000000000000";
            when "01100" =>
                wishbone_down.sel <= sel(19 downto 0) & "000000000000";
                wishbone_down.data <= data_temp(159 downto 0) & x"000000000000000000000000";
            when "01101" =>
                wishbone_down.sel <= sel(18 downto 0) & "0000000000000";
                wishbone_down.data <= data_temp(151 downto 0) & x"00000000000000000000000000";
            when "01110" =>
                wishbone_down.sel <= sel(17 downto 0) & "00000000000000";
                wishbone_down.data <= data_temp(143 downto 0) & x"0000000000000000000000000000";
            when "01111" =>
                wishbone_down.sel <= sel(16 downto 0) & "000000000000000";
                wishbone_down.data <= data_temp(135 downto 0) & x"000000000000000000000000000000";          
            when "10000" =>
                wishbone_down.sel <= sel(15 downto 0) & "0000000000000000";
                wishbone_down.data <= data_temp(127 downto 0) & x"00000000000000000000000000000000";  
            when "10001" =>
                wishbone_down.sel <= sel(14 downto 0) & "00000000000000000";
                wishbone_down.data <= data_temp(119 downto 0) & x"0000000000000000000000000000000000";
            when "10010" =>
                wishbone_down.sel <= sel(13 downto 0) & "000000000000000000";
                wishbone_down.data <= data_temp(111 downto 0) & x"000000000000000000000000000000000000";
            when "10011" =>
                wishbone_down.sel <= sel(12 downto 0) & "0000000000000000000";
                wishbone_down.data <= data_temp(103 downto 0) & x"00000000000000000000000000000000000000";
            when "10100" =>
                wishbone_down.sel <= sel(11 downto 0) & "00000000000000000000";
                wishbone_down.data <= data_temp(95 downto 0) & x"0000000000000000000000000000000000000000";
            when "10101" =>
                wishbone_down.sel <= sel(10 downto 0) & "000000000000000000000";
                wishbone_down.data <= data_temp(87 downto 0) & x"000000000000000000000000000000000000000000";
            when "10110" =>
                wishbone_down.sel <= sel(9 downto 0) & "0000000000000000000000";
                wishbone_down.data <= data_temp(79 downto 0) & x"00000000000000000000000000000000000000000000";
            when "10111" =>
                wishbone_down.sel <= sel(8 downto 0) & "00000000000000000000000";
                wishbone_down.data <= data_temp(71 downto 0) & x"0000000000000000000000000000000000000000000000";  
            when "11000" =>
                wishbone_down.sel <= sel(7 downto 0) & "000000000000000000000000";
                wishbone_down.data <= data_temp(63 downto 0) & x"000000000000000000000000000000000000000000000000";  
            when "11001" =>
                wishbone_down.sel <= sel(6 downto 0) & "0000000000000000000000000";
                wishbone_down.data <= data_temp(55 downto 0) & x"00000000000000000000000000000000000000000000000000";
            when "11010" =>
                wishbone_down.sel <= sel(5 downto 0) & "00000000000000000000000000";
                wishbone_down.data <= data_temp(47 downto 0) & x"0000000000000000000000000000000000000000000000000000";
            when "11011" =>
                wishbone_down.sel <= sel(4 downto 0) & "000000000000000000000000000";
                wishbone_down.data <= data_temp(39 downto 0) & x"000000000000000000000000000000000000000000000000000000";
            when "11100" =>
                wishbone_down.sel <= sel(3 downto 0) & "0000000000000000000000000000";
                wishbone_down.data <= data_temp(31 downto 0) & x"00000000000000000000000000000000000000000000000000000000";
            when "11101" =>
                wishbone_down.sel <= sel(2 downto 0) & "00000000000000000000000000000";
                wishbone_down.data <= data_temp(23 downto 0) & x"0000000000000000000000000000000000000000000000000000000000";
            when "11110" =>
                wishbone_down.sel <= sel(1 downto 0) & "000000000000000000000000000000";
                wishbone_down.data <= data_temp(15 downto 0) & x"000000000000000000000000000000000000000000000000000000000000";
            when "11111" =>
                wishbone_down.sel <= sel(0) & "0000000000000000000000000000000";
                wishbone_down.data <= data_temp(7 downto 0) & x"00000000000000000000000000000000000000000000000000000000000000";                                              
            when others =>
        end case;

        wishbone_down.we <= '1';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_256_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_256_init;
                return;
            end if;
            if wishbone_up.ack then
                exit;
            end if;
        end loop;  
        wishbone_down <= wishbone_down_256_init;
        successfull := true;
    end procedure;

    procedure read_wishbone_256(signal wishbone_down : out t_wishbone_down_256;
                            signal wishbone_up : in t_wishbone_up_256;
                            variable address : in unsigned;
                            variable data : out unsigned;
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is

        variable sel : std_logic_vector(31 downto 0);
        variable data_temp : std_logic_vector(255 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;       
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_256_init;
            return;
        end if;        
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));

        case access_width is
            when 8 => 
                sel := "00000000000000000000000000000001";
            when 16 => 
                sel := "00000000000000000000000000000011";
            when 32 => 
                sel := "00000000000000000000000000001111";
            when 64 => 
                sel := "00000000000000000000000011111111";
            when 128 => 
                sel := "00000000000000001111111111111111";
            when 256 => 
                sel := "11111111111111111111111111111111";                                  
            when others =>
        end case;

        case address(4 downto 0) is
            when "00000" =>
                wishbone_down.sel <= sel;
            when "00001" =>
                wishbone_down.sel <= sel(30 downto 0) & '0';
            when "00010" =>
                wishbone_down.sel <= sel(29 downto 0) & "00";
            when "00011" =>
                wishbone_down.sel <= sel(28 downto 0) & "000";
            when "00100" =>
                wishbone_down.sel <= sel(27 downto 0) & "0000";
            when "00101" =>
                wishbone_down.sel <= sel(26 downto 0) & "00000";
            when "00110" =>
                wishbone_down.sel <= sel(25 downto 0) & "000000";
            when "00111" =>
                wishbone_down.sel <= sel(24 downto 0) & "0000000";
            when "01000" =>
                wishbone_down.sel <= sel(23 downto 0) & "00000000";
            when "01001" =>
                wishbone_down.sel <= sel(22 downto 0) & "000000000";
            when "01010" =>
                wishbone_down.sel <= sel(21 downto 0) & "0000000000";
            when "01011" =>
                wishbone_down.sel <= sel(20 downto 0) & "00000000000";
            when "01100" =>
                wishbone_down.sel <= sel(19 downto 0) & "000000000000";
            when "01101" =>
                wishbone_down.sel <= sel(18 downto 0) & "0000000000000";
            when "01110" =>
                wishbone_down.sel <= sel(17 downto 0) & "00000000000000";
            when "01111" =>
                wishbone_down.sel <= sel(16 downto 0) & "000000000000000";
            when "10000" =>
                wishbone_down.sel <= sel(15 downto 0) & "0000000000000000";
            when "10001" =>
                wishbone_down.sel <= sel(14 downto 0) & "00000000000000000";
            when "10010" =>
                wishbone_down.sel <= sel(13 downto 0) & "000000000000000000";
            when "10011" =>
                wishbone_down.sel <= sel(12 downto 0) & "0000000000000000000";
            when "10100" =>
                wishbone_down.sel <= sel(11 downto 0) & "00000000000000000000";
            when "10101" =>
                wishbone_down.sel <= sel(10 downto 0) & "000000000000000000000";
            when "10110" =>
                wishbone_down.sel <= sel(9 downto 0) & "0000000000000000000000";
            when "10111" =>
                wishbone_down.sel <= sel(8 downto 0) & "00000000000000000000000";
            when "11000" =>
                wishbone_down.sel <= sel(7 downto 0) & "000000000000000000000000";
            when "11001" =>
                wishbone_down.sel <= sel(6 downto 0) & "0000000000000000000000000";
            when "11010" =>
                wishbone_down.sel <= sel(5 downto 0) & "00000000000000000000000000";
            when "11011" =>
                wishbone_down.sel <= sel(4 downto 0) & "000000000000000000000000000";
            when "11100" =>
                wishbone_down.sel <= sel(3 downto 0) & "0000000000000000000000000000";
            when "11101" =>
                wishbone_down.sel <= sel(2 downto 0) & "00000000000000000000000000000";
            when "11110" =>
                wishbone_down.sel <= sel(1 downto 0) & "000000000000000000000000000000";
            when "11111" =>
                wishbone_down.sel <= sel(0) & "0000000000000000000000000000000";                                                    
            when others =>
        end case;

        wishbone_down.data <= (others => '0');
        wishbone_down.we <= '0';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_256_init;
            return;
        end if;

        loop
            wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
            if now > start_time + timeout then
                wishbone_down <= wishbone_down_256_init;
                return;
            end if;
            if wishbone_up.ack then
                exit;
            end if;
        end loop;  

        wishbone_down <= wishbone_down_256_init;

        case address(4 downto 0) is
            when "00000" => data_temp := wishbone_up.data(255 downto 0);
            when "00001" => data_temp := x"00" & wishbone_up.data(255 downto 8);
            when "00010" => data_temp := x"0000" & wishbone_up.data(255 downto 16);
            when "00011" => data_temp := x"000000" & wishbone_up.data(255 downto 24);
            when "00100" => data_temp := x"00000000" & wishbone_up.data(255 downto 32);
            when "00101" => data_temp := x"0000000000" & wishbone_up.data(255 downto 40);
            when "00110" => data_temp := x"000000000000" & wishbone_up.data(255 downto 48);
            when "00111" => data_temp := x"00000000000000" & wishbone_up.data(255 downto 56);
            when "01000" => data_temp := x"0000000000000000" & wishbone_up.data(255 downto 64);
            when "01001" => data_temp := x"000000000000000000" & wishbone_up.data(255 downto 72);
            when "01010" => data_temp := x"00000000000000000000" & wishbone_up.data(255 downto 80);
            when "01011" => data_temp := x"0000000000000000000000" & wishbone_up.data(255 downto 88);
            when "01100" => data_temp := x"000000000000000000000000" & wishbone_up.data(255 downto 96);
            when "01101" => data_temp := x"00000000000000000000000000" & wishbone_up.data(255 downto 104);
            when "01110" => data_temp := x"0000000000000000000000000000" & wishbone_up.data(255 downto 112);
            when "01111" => data_temp := x"000000000000000000000000000000" & wishbone_up.data(255 downto 120);
            when "10000" => data_temp := x"00000000000000000000000000000000" & wishbone_up.data(255 downto 128);
            when "10001" => data_temp := x"0000000000000000000000000000000000" & wishbone_up.data(255 downto 136);
            when "10010" => data_temp := x"000000000000000000000000000000000000" & wishbone_up.data(255 downto 144);
            when "10011" => data_temp := x"00000000000000000000000000000000000000" & wishbone_up.data(255 downto 152);
            when "10100" => data_temp := x"0000000000000000000000000000000000000000" & wishbone_up.data(255 downto 160);
            when "10101" => data_temp := x"000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 168);
            when "10110" => data_temp := x"00000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 176);
            when "10111" => data_temp := x"0000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 184);
            when "11000" => data_temp := x"000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 192);
            when "11001" => data_temp := x"00000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 200);
            when "11010" => data_temp := x"0000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 208);
            when "11011" => data_temp := x"000000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 216);
            when "11100" => data_temp := x"00000000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 224);
            when "11101" => data_temp := x"0000000000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 232);
            when "11110" => data_temp := x"000000000000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 240);
            when "11111" => data_temp := x"00000000000000000000000000000000000000000000000000000000000000" & wishbone_up.data(255 downto 248);                                      
            when others =>
        end case;
        data := to_unsigned(0, data'length);
        case access_width is
            when 8 => data(255 downto 0) := unsigned(data_temp and x"00000000000000000000000000000000000000000000000000000000000000FF");
            when 16 => data(255 downto 0) := unsigned(data_temp and x"000000000000000000000000000000000000000000000000000000000000FFFF");
            when 32 => data(255 downto 0) := unsigned(data_temp and x"00000000000000000000000000000000000000000000000000000000FFFFFFFF");
            when 64 => data(255 downto 0) := unsigned(data_temp and x"000000000000000000000000000000000000000000000000FFFFFFFFFFFFFFFF");
            when 128 => data(255 downto 0) := unsigned(data_temp and x"00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");  
            when 256 => data(255 downto 0) := unsigned(data_temp and x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");            
            when others =>
        end case;

        wishbone_down <= wishbone_down_256_init;
        successfull := true;

    end procedure;

end package body;
