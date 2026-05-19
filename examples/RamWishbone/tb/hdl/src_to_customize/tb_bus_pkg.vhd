package tb_bus_wishbone_32_pkg_inst is new work.tb_bus_wishbone_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 32);
package tb_bus_wishbone_64_pkg_inst is new work.tb_bus_wishbone_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 64);
package tb_bus_wishbone_128_pkg_inst is new work.tb_bus_wishbone_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 128);
package tb_bus_wishbone_256_pkg_inst is new work.tb_bus_wishbone_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 256);
package tb_bus_avalon_32_pkg_inst is new work.tb_bus_avalon_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 32);
package tb_bus_avalon_64_pkg_inst is new work.tb_bus_avalon_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 64);
package tb_bus_axi4lite_32_pkg_inst is new work.tb_bus_axi4lite_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 32);
package tb_bus_ram_32_pkg_inst is new work.tb_bus_ram_pkg
    generic map(G_ADDR_W => 32, G_DATA_W => 32);

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_bus_wishbone_32_pkg_inst.all;
use work.tb_bus_wishbone_64_pkg_inst.all;
use work.tb_bus_wishbone_128_pkg_inst.all;
use work.tb_bus_wishbone_256_pkg_inst.all;
use work.tb_bus_avalon_32_pkg_inst.all;
use work.tb_bus_avalon_64_pkg_inst.all;
use work.tb_bus_axi4lite_32_pkg_inst.all;
use work.tb_bus_ram_32_pkg_inst.all;
use work.tb_base_pkg.all;

package tb_bus_pkg is

    type t_bus_down is record
        avalonmm32 : work.tb_bus_avalon_32_pkg_inst.t_avalonmm_down;
        avalonmm64 : work.tb_bus_avalon_64_pkg_inst.t_avalonmm_down;
        axi4lite32 : work.tb_bus_axi4lite_32_pkg_inst.t_axi4lite_down;
        wishbone32 : work.tb_bus_wishbone_32_pkg_inst.t_wishbone_down;
        wishbone64 : work.tb_bus_wishbone_64_pkg_inst.t_wishbone_down;
        wishbone128 : work.tb_bus_wishbone_128_pkg_inst.t_wishbone_down;
        wishbone256 : work.tb_bus_wishbone_256_pkg_inst.t_wishbone_down;
        ram32 : work.tb_bus_ram_32_pkg_inst.t_ram_down;
    end record;

    type t_bus_up is record
        avalonmm32 : work.tb_bus_avalon_32_pkg_inst.t_avalonmm_up;
        avalonmm64 : work.tb_bus_avalon_64_pkg_inst.t_avalonmm_up;
        axi4lite32 : work.tb_bus_axi4lite_32_pkg_inst.t_axi4lite_up;
        wishbone32 : work.tb_bus_wishbone_32_pkg_inst.t_wishbone_up;
        wishbone64 : work.tb_bus_wishbone_64_pkg_inst.t_wishbone_up;
        wishbone128 : work.tb_bus_wishbone_128_pkg_inst.t_wishbone_up;
        wishbone256 : work.tb_bus_wishbone_256_pkg_inst.t_wishbone_up;
        ram32 : work.tb_bus_ram_32_pkg_inst.t_ram_up;
    end record;

    type t_bus_trace is record
        avalonmm32_trace : work.tb_bus_avalon_32_pkg_inst.t_avalonmm_trace;
        avalonmm64_trace : work.tb_bus_avalon_64_pkg_inst.t_avalonmm_trace;
        axi4lite32_trace : work.tb_bus_axi4lite_32_pkg_inst.t_axi4lite_trace;
        wishbone32_trace : work.tb_bus_wishbone_32_pkg_inst.t_wishbone_trace;
        wishbone64_trace : work.tb_bus_wishbone_64_pkg_inst.t_wishbone_trace;
        wishbone128_trace : work.tb_bus_wishbone_128_pkg_inst.t_wishbone_trace;
        wishbone256_trace : work.tb_bus_wishbone_256_pkg_inst.t_wishbone_trace;
        ram32_trace : work.tb_bus_ram_32_pkg_inst.t_ram_trace;
    end record;

    function bus_down_init return t_bus_down;
    function bus_up_init return t_bus_up;

    procedure bus_write(signal bus_down : out t_bus_down;
                        signal bus_up : in t_bus_up;
                        variable address : in unsigned;
                        variable data : in unsigned;
                        variable access_width : in integer;
                        variable bus_number : in integer;
                        variable valid : out integer;
                        variable successfull : out boolean;
                        variable timeout : in time);

    procedure bus_read(signal bus_down : out t_bus_down;
                       signal bus_up : in t_bus_up;
                       variable address : in unsigned;
                       variable data : out unsigned;
                       variable access_width : in integer;
                       variable bus_number : in integer;
                       variable valid : out integer;
                       variable successfull : out boolean;
                       variable timeout : in time);
end;

package body tb_bus_pkg is

    function bus_down_init return t_bus_down is
        variable init : t_bus_down;
    begin
        init.avalonmm32 := work.tb_bus_avalon_32_pkg_inst.avalonmm_down_init;
        init.avalonmm64 := work.tb_bus_avalon_64_pkg_inst.avalonmm_down_init;
        init.axi4lite32 := work.tb_bus_axi4lite_32_pkg_inst.axi4lite_down_init;
        init.wishbone32 := work.tb_bus_wishbone_32_pkg_inst.wishbone_down_init;
        init.wishbone64 := work.tb_bus_wishbone_64_pkg_inst.wishbone_down_init;
        init.wishbone128 := work.tb_bus_wishbone_128_pkg_inst.wishbone_down_init;
        init.wishbone256 := work.tb_bus_wishbone_256_pkg_inst.wishbone_down_init;
        init.ram32 := work.tb_bus_ram_32_pkg_inst.ram_down_init;
        return init;
    end;

    function bus_up_init return t_bus_up is
        variable init : t_bus_up;
    begin
        init.avalonmm32 := work.tb_bus_avalon_32_pkg_inst.avalonmm_up_init;
        init.avalonmm64 := work.tb_bus_avalon_64_pkg_inst.avalonmm_up_init;
        init.axi4lite32 := work.tb_bus_axi4lite_32_pkg_inst.axi4lite_up_init;
        init.wishbone32 := work.tb_bus_wishbone_32_pkg_inst.wishbone_up_init;
        init.wishbone64 := work.tb_bus_wishbone_64_pkg_inst.wishbone_up_init;
        init.wishbone128 := work.tb_bus_wishbone_128_pkg_inst.wishbone_up_init;
        init.wishbone256 := work.tb_bus_wishbone_256_pkg_inst.wishbone_up_init;
        init.ram32 := work.tb_bus_ram_32_pkg_inst.ram_up_init;
        return init;
    end;

    procedure bus_write(signal bus_down : out t_bus_down;
                        signal bus_up : in t_bus_up;
                        variable address : in unsigned;
                        variable data : in unsigned;
                        variable access_width : in integer;
                        variable bus_number : in integer;
                        variable valid : out integer;
                        variable successfull : out boolean;
                        variable timeout : in time) is
    begin
        valid := 1;
        case bus_number is
            when 0 =>
                assert false
                report "write to unassigned bus e.g., local bus in procedure"
                severity failure;
            when 1 =>
                work.tb_bus_avalon_32_pkg_inst.write_avalonmm(
                    bus_down.avalonmm32,
                    bus_up.avalonmm32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 2 =>
                work.tb_bus_avalon_64_pkg_inst.write_avalonmm(
                    bus_down.avalonmm64,
                    bus_up.avalonmm64,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 3 =>
                work.tb_bus_axi4lite_32_pkg_inst.write_axi4lite(
                    bus_down.axi4lite32,
                    bus_up.axi4lite32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 4 =>
                work.tb_bus_wishbone_32_pkg_inst.write_wishbone(
                    bus_down.wishbone32,
                    bus_up.wishbone32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 5 =>
                work.tb_bus_wishbone_64_pkg_inst.write_wishbone(
                    bus_down.wishbone64,
                    bus_up.wishbone64,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 6 =>
                work.tb_bus_wishbone_128_pkg_inst.write_wishbone(
                    bus_down.wishbone128,
                    bus_up.wishbone128,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 7 =>
                work.tb_bus_wishbone_256_pkg_inst.write_wishbone(
                    bus_down.wishbone256,
                    bus_up.wishbone256,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 8 =>
                work.tb_bus_ram_32_pkg_inst.write_ram(
                    bus_down.ram32,
                    bus_up.ram32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when others =>
                valid := 0;
        end case;

    end procedure;

    procedure bus_read(
        signal bus_down : out t_bus_down;
        signal bus_up : in t_bus_up;
        variable address : in unsigned;
        variable data : out unsigned;
        variable access_width : in integer;
        variable bus_number : in integer;
        variable valid : out integer;
        variable successfull : out boolean;
        variable timeout : in time) is
    begin
        valid := 1;
        case bus_number is
            when 0 =>
                assert false
                report "read of unassigned bus e.g., local bus in procedure"
                severity failure;
            when 1 =>
                work.tb_bus_avalon_32_pkg_inst.read_avalonmm(
                    bus_down.avalonmm32,
                    bus_up.avalonmm32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 2 =>
                work.tb_bus_avalon_64_pkg_inst.read_avalonmm(
                    bus_down.avalonmm64,
                    bus_up.avalonmm64,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 3 =>
                work.tb_bus_axi4lite_32_pkg_inst.read_axi4lite(
                    bus_down.axi4lite32,
                    bus_up.axi4lite32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 4 =>
                work.tb_bus_wishbone_32_pkg_inst.read_wishbone(
                    bus_down.wishbone32,
                    bus_up.wishbone32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 5 =>
                work.tb_bus_wishbone_64_pkg_inst.read_wishbone(
                    bus_down.wishbone64,
                    bus_up.wishbone64,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 6 =>
                work.tb_bus_wishbone_128_pkg_inst.read_wishbone(
                    bus_down.wishbone128,
                    bus_up.wishbone128,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 7 =>
                work.tb_bus_wishbone_256_pkg_inst.read_wishbone(
                    bus_down.wishbone256,
                    bus_up.wishbone256,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when 8 =>
                work.tb_bus_ram_32_pkg_inst.read_ram(
                    bus_down.ram32,
                    bus_up.ram32,
                    address,
                    data,
                    access_width,
                    successfull,
                    timeout);

            when others =>
                valid := 0;
        end case;

    end procedure;
end package body;
