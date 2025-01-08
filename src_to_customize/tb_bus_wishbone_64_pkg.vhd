library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_wishbone_64_pkg is

    type t_wishbone_down_64 is record
        adr : std_logic_vector(31 downto 0);
        sel : std_logic_vector(7 downto 0);
        data : std_logic_vector(63 downto 0);
        we : std_logic;
        stb : std_logic;
        cyc : std_logic;
    end record;

    type t_wishbone_up_64 is record
        clk : std_logic;
        data : std_logic_vector(63 downto 0);
        ack : std_logic;
    end record;
    
    type t_wishbone_trace_64 is record
        wishbone_down : t_wishbone_down_64;
        wishbone_up : t_wishbone_up_64;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function wishbone_down_64_init return t_wishbone_down_64;
    function wishbone_up_64_init return t_wishbone_up_64;

    procedure write_wishbone_64(signal wishbone_down : out t_wishbone_down_64;
                             signal wishbone_up : in t_wishbone_up_64;
                             variable address : in unsigned(c_stm_value_width - 1 downto 0);
                             variable data : in unsigned(c_stm_value_width - 1 downto 0);
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time);

    procedure read_wishbone_64(signal wishbone_down : out t_wishbone_down_64;
                            signal wishbone_up : in t_wishbone_up_64;
                            variable address : in unsigned(c_stm_value_width - 1 downto 0);
                            variable data : out unsigned(c_stm_value_width - 1 downto 0);
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time);
end;

package body tb_bus_wishbone_64_pkg is
    function wishbone_up_64_init return t_wishbone_up_64 is
        variable init : t_wishbone_up_64;
    begin
        init.clk := '0';
        init.data := (others => '0');
        init.ack := '0';
        return init;
    end;

    function wishbone_down_64_init return t_wishbone_down_64 is
        variable init : t_wishbone_down_64;
    begin
        init.adr := (others => '0');
        init.sel := (others => '0');
        init.data := (others => '0');
        init.we := '0';
        init.stb := '0';
        init.cyc := '0';
        return init;
    end;

    procedure write_wishbone_64(signal wishbone_down : out t_wishbone_down_64;
                             signal wishbone_up : in t_wishbone_up_64;
                             variable address : in unsigned(c_stm_value_width - 1 downto 0);
                             variable data : in unsigned(c_stm_value_width - 1 downto 0);
                             variable access_width : in integer;
                             variable successfull : out boolean;
                             variable timeout : in time) is

        variable sel : std_logic_vector(7 downto 0);
        variable data_temp : std_logic_vector(63 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));
        case access_width is
            when 8 =>
                sel := "0001";
                data_temp := std_logic_vector(data(63 downto 0)) and x"00000000000000FF";
            when 16 =>
                sel := "0011";
                data_temp := std_logic_vector(data(63 downto 0)) and x"000000000000FFFF";
            when 32 =>
                sel := "1111";
                data_temp := std_logic_vector(data(63 downto 0)) and x"00000000FFFFFFFF";
             when 64 =>
                sel := "11111111";
                data_temp := std_logic_vector(data(63 downto 0)) and x"FFFFFFFFFFFFFFFF";               
            when others =>
        end case;

        case address(2 downto 0) is
            when "000" =>
                wishbone_down.sel <= sel;
                wishbone_down.data <= data_temp;
            when "001" =>
                wishbone_down.sel <= sel(6 downto 0) & '0';
                wishbone_down.data <= data_temp(55 downto 0) & x"00";
            when "010" =>
                wishbone_down.sel <= sel(5 downto 0) & "00";
                wishbone_down.data <= data_temp(47 downto 0) & x"0000";
            when "011" =>
                wishbone_down.sel <= sel(4 downto 0) & "000";
                wishbone_down.data <= data_temp(39 downto 0) & x"000000";
            when "100" =>
                wishbone_down.sel <= sel(3 downto 0) & "0000";
                wishbone_down.data <= data_temp(31 downto 0) & x"00000000";
            when "101" =>
                wishbone_down.sel <= sel(2 downto 0) & "00000";
                wishbone_down.data <= data_temp(23 downto 0) & x"0000000000";
            when "110" =>
                wishbone_down.sel <= sel(1 downto 0) & "000000";
                wishbone_down.data <= data_temp(15 downto 0) & x"000000000000";
            when "111" =>
                wishbone_down.sel <= sel(0) & "0000000";
                wishbone_down.data <= data_temp(7 downto 0) & x"00000000000000";                
            when others =>
        end case;

        wishbone_down.we <= '1';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        wait on wishbone_up.ack until wishbone_up.ack = '1'or (now > start_time + timeout);
        
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        wishbone_down <= wishbone_down_64_init;
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        successfull := true;
    end procedure;

    procedure read_wishbone_64(signal wishbone_down : out t_wishbone_down_64;
                            signal wishbone_up : in t_wishbone_up_64;
                            variable address : in unsigned(c_stm_value_width - 1 downto 0);
                            variable data : out unsigned(c_stm_value_width - 1 downto 0);
                            variable access_width : in integer;
                            variable successfull : out boolean;
                            variable timeout : in time) is

        variable sel : std_logic_vector(7 downto 0);
        variable data_temp : std_logic_vector(63 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;       
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;        
        wishbone_down.adr <= std_logic_vector(address(31 downto 0));

        case access_width is
            when 8 => sel := "00000001";
            when 16 => sel := "00000011";
            when 32 => sel := "00001111";
            when 64 => sel := "11111111";
            when others =>
        end case;

        case address(2 downto 0) is
            when "000" =>
                wishbone_down.sel <= sel;
            when "001" =>
                wishbone_down.sel <= sel(6 downto 0) & '0';
            when "010" =>
                wishbone_down.sel <= sel(5 downto 0) & "00";
            when "011" =>
                wishbone_down.sel <= sel(4 downto 0) & "000";
            when "100" =>
                wishbone_down.sel <= sel(3 downto 0) & "0000";
            when "101" =>
                wishbone_down.sel <= sel(2 downto 0) & "00000";
            when "110" =>
                wishbone_down.sel <= sel(1 downto 0) & "000000";
            when "111" =>
                wishbone_down.sel <= sel(0) & "0000000";            
            when others =>
        end case;

        wishbone_down.data <= (others => '0');
        wishbone_down.we <= '0';
        wishbone_down.stb <= '1';
        wishbone_down.cyc <= '1';
        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        wait on wishbone_up.ack until wishbone_up.ack = '1' or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;

        wishbone_down <= wishbone_down_64_init;

        case address(2 downto 0) is
            when "000" => data_temp := wishbone_up.data(63 downto 0);
            when "001" => data_temp := x"00" & wishbone_up.data(63 downto 8);
            when "010" => data_temp := x"0000" & wishbone_up.data(63 downto 16);
            when "011" => data_temp := x"000000" & wishbone_up.data(63 downto 24);
            when "100" => data_temp := x"00000000" & wishbone_up.data(63 downto 32);
            when "101" => data_temp := x"0000000000" & wishbone_up.data(63 downto 40);
            when "110" => data_temp := x"000000000000" & wishbone_up.data(63 downto 48);
            when "111" => data_temp := x"00000000000000" & wishbone_up.data(63 downto 56);            
            when others =>
        end case;
        case access_width is
            when 8 => data(63 downto 0) := unsigned(data_temp and x"00000000000000FF");
            when 16 => data(63 downto 0) := unsigned(data_temp and x"000000000000FFFF");
            when 32 => data(63 downto 0) := unsigned(data_temp and x"00000000FFFFFFFF");
            when 64 => data(63 downto 0) := unsigned(data_temp and x"FFFFFFFFFFFFFFFF");
            when others =>
        end case;

        wait until rising_edge(wishbone_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            wishbone_down <= wishbone_down_64_init;
            return;
        end if;
        successfull := true;

    end procedure;

end package body;
