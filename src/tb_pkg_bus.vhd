library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_pkg_bus_avalonmm.all;
use work.tb_pkg_bus_axi4lite.all;
use work.tb_pkg_bus_wishbone.all;

package tb_pkg_bus is
    type t_bus_down is record
        wishbone : t_wishbone_down;
        avalonmm : t_avalonmm_down;
        axi4lite : t_axi4lite_down;
    end record;

    type t_bus_up is record
        wishbone : t_wishbone_up;
        avalonmm : t_avalonmm_up;
        axi4lite : t_axi4lite_up;
    end record;

    function bus_down_init return t_bus_down;
    function bus_up_init return t_bus_up;

    procedure bus_write(signal clk : in std_logic;
                        signal bus_down : out t_bus_down;
                        signal bus_up : in t_bus_up;
                        variable address : in std_logic_vector(31 downto 0);
                        variable data : in std_logic_vector(31 downto 0);
                        variable b_width : in integer;
                        variable bus_number : in integer;
                        variable valid : out integer;
                        variable successfull : out boolean;
                        variable timeout : in time);

    procedure bus_read(signal clk : in std_logic;
                       signal bus_down : out t_bus_down;
                       signal bus_up : in t_bus_up;
                       variable address : in std_logic_vector(31 downto 0);
                       variable data : out std_logic_vector(31 downto 0);
                       variable b_width : in integer;
                       variable bus_number : in integer;
                       variable valid : out integer;
                       variable successfull : out boolean;
                       variable timeout : in time);
end;

package body tb_pkg_bus is
    function bus_up_init return t_bus_up is
        variable init : t_bus_up;
    begin
        init.wishbone := wishbone_up_init;
        init.avalonmm := avalonmm_up_init;
        init.axi4lite := axi4lite_up_init;
        return init;
    end;

    function bus_down_init return t_bus_down is
        variable init : t_bus_down;
    begin
        init.wishbone := wishbone_down_init;
        init.avalonmm := avalonmm_down_init;
        init.axi4lite := axi4lite_down_init;
        return init;
    end;

    procedure bus_write(signal clk : in std_logic;
                        signal bus_down : out t_bus_down;
                        signal bus_up : in t_bus_up;
                        variable address : in std_logic_vector(31 downto 0);
                        variable data : in std_logic_vector(31 downto 0);
                        variable b_width : in integer;
                        variable bus_number : in integer;
                        variable valid : out integer;
                        variable successfull : out boolean;
                        variable timeout : in time) is
    begin
        valid := 1;
        case bus_number is
            when 0 =>
                write_wishbone(clk,
                               bus_down.wishbone,
                               bus_up.wishbone,
                               address,
                               data,
                               b_width,
                               successfull,
                               timeout);

            when 1 =>
                write_avalonmm(clk,
                               bus_down.avalonmm,
                               bus_up.avalonmm,
                               address,
                               data,
                               b_width,
                               successfull,
                               timeout);

            when 2 =>
                write_axi4lite(clk,
                               bus_down.axi4lite,
                               bus_up.axi4lite,
                               address,
                               data,
                               b_width,
                               successfull,
                               timeout);
            when others =>
                valid := 0;
        end case;

    end procedure;

    procedure bus_read(signal clk : in std_logic;
                       signal bus_down : out t_bus_down;
                       signal bus_up : in t_bus_up;
                       variable address : in std_logic_vector(31 downto 0);
                       variable data : out std_logic_vector(31 downto 0);
                       variable b_width : in integer;
                       variable bus_number : in integer;
                       variable valid : out integer;
                       variable successfull : out boolean;
                       variable timeout : in time) is
    begin
        valid := 1;
        case bus_number is
            when 0 =>
                read_wishbone(clk,
                              bus_down.wishbone,
                              bus_up.wishbone,
                              address,
                              data,
                              b_width,
                              successfull,
                              timeout);

            when 1 =>
                read_avalonmm(clk,
                              bus_down.avalonmm,
                              bus_up.avalonmm,
                              address,
                              data,
                              b_width,
                              successfull,
                              timeout);

            when 2 =>
                read_axi4lite(clk,
                              bus_down.axi4lite,
                              bus_up.axi4lite,
                              address,
                              data,
                              b_width,
                              successfull,
                              timeout);
            when others =>
                valid := 0;
        end case;

    end procedure;
end;
