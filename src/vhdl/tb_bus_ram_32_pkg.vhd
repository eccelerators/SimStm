library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tb_base_pkg.all;

package tb_bus_ram_32_pkg is

    type t_ram_down_32 is record
        address : std_logic_vector(31 downto 0);
        write_enable : std_logic_vector(3 downto 0);
        write_data : std_logic_vector(31 downto 0);
    end record;

    type t_ram_up_32 is record
        clk : std_logic;
        read_data : std_logic_vector(31 downto 0);
    end record;

    type t_ram_trace_32 is record
        ram_down : t_ram_down_32;
        ram_up : t_ram_up_32;
        hxs_unoccupied_access : std_logic;
        hxs_timeout_access : std_logic;
    end record;

    function ram_down_32_init return t_ram_down_32;
    function ram_up_32_init return t_ram_up_32;

    procedure write_ram_32(signal ram_down : out t_ram_down_32;
                           signal ram_up : in t_ram_up_32;
                           variable address : in unsigned;
                           variable data : in unsigned;
                           variable access_width : in integer;
                           variable successfull : out boolean;
                           variable timeout : in time);

    procedure read_ram_32(signal ram_down : out t_ram_down_32;
                          signal ram_up : in t_ram_up_32;
                          variable address : in unsigned;
                          variable data : out unsigned;
                          variable access_width : in integer;
                          variable successfull : out boolean;
                          variable timeout : in time);
end;

package body tb_bus_ram_32_pkg is

    function ram_down_32_init return t_ram_down_32 is
        variable init : t_ram_down_32;
    begin
        init.address := (others => '0');
        init.write_enable := (others => '0');
        init.write_data := (others => '0');
        return init;
    end;

    function ram_up_32_init return t_ram_up_32 is
        variable init : t_ram_up_32;
    begin
        init.clk := '0';
        init.read_data := (others => '0');
        return init;
    end;

    procedure write_ram_32(signal ram_down : out t_ram_down_32;
                           signal ram_up : in t_ram_up_32;
                           variable address : in unsigned;
                           variable data : in unsigned;
                           variable access_width : in integer;
                           variable successfull : out boolean;
                           variable timeout : in time) is

        variable write_enable : std_logic_vector(3 downto 0);
        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_32_init;
            return;
        end if;
        ram_down.address <= std_logic_vector(address(31 downto 0));
        case access_width is
            when 8 =>
                write_enable := "0001";
                data_temp := std_logic_vector(data(31 downto 0)) and x"000000FF";
            when 16 =>
                write_enable := "0011";
                data_temp := std_logic_vector(data(31 downto 0)) and x"0000FFFF";
            when 32 =>
                write_enable := "1111";
                data_temp := std_logic_vector(data(31 downto 0)) and x"FFFFFFFF";
            when others =>
        end case;

        case address(1 downto 0) is
            when "00" =>
                ram_down.write_enable <= write_enable;
                ram_down.write_data <= data_temp;
            when "01" =>
                ram_down.write_enable <= write_enable(2 downto 0) & '0';
                ram_down.write_data <= data_temp(23 downto 0) & x"00";
            when "10" =>
                ram_down.write_enable <= write_enable(1 downto 0) & "00";
                ram_down.write_data <= data_temp(15 downto 0) & x"0000";
            when "11" =>
                ram_down.write_enable <= write_enable(0) & "000";
                ram_down.write_data <= data_temp(7 downto 0) & x"000000";
            when others =>
        end case;

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_32_init;
            return;
        end if;

        ram_down <= ram_down_32_init;
        successfull := true;
    end procedure;

    procedure read_ram_32(signal ram_down : out t_ram_down_32;
                          signal ram_up : in t_ram_up_32;
                          variable address : in unsigned;
                          variable data : out unsigned;
                          variable access_width : in integer;
                          variable successfull : out boolean;
                          variable timeout : in time) is

        variable data_temp : std_logic_vector(31 downto 0);
        constant start_time : time := now;
    begin
        successfull := false;
        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_32_init;
            return;
        end if;
        ram_down.address <= std_logic_vector(address(31 downto 0));
        ram_down.write_data <= (others => '0');
        ram_down.write_enable <= (others => '0');
        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_32_init;
            return;
        end if;

        wait until rising_edge(ram_up.clk) or (now > start_time + timeout);
        if now > start_time + timeout then
            ram_down <= ram_down_32_init;
            return;
        end if;

        case address(1 downto 0) is
            when "00" => data_temp := ram_up.read_data;
            when "01" => data_temp := x"00" & ram_up.read_data(31 downto 8);
            when "10" => data_temp := x"0000" & ram_up.read_data(31 downto 16);
            when "11" => data_temp := x"000000" & ram_up.read_data(31 downto 24);
            when others =>
        end case;

        data := to_unsigned(0, data'length);
        case access_width is
            when 8 => data(31 downto 0) := unsigned(data_temp and x"000000FF");
            when 16 => data(31 downto 0) := unsigned(data_temp and x"0000FFFF");
            when 32 => data(31 downto 0) := unsigned(data_temp and x"FFFFFFFF");
            when others =>
        end case;

        ram_down <= ram_down_32_init;
        successfull := true;
    end procedure;

end package body;
