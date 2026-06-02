-- ******************************************************************************
--
--                   /------o
--             eccelerators
--          o------/
--
--  This file is an Eccelerators GmbH sample project.
--
--  MIT License:
--  Copyright (c) 2025 Eccelerators GmbH
--
--  Permission is hereby granted, free of charge, to any person obtaining a copy
--  of this software and associated documentation files (the "Software"), to deal
--  in the Software without restriction, including without limitation the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in all
--  copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--  SOFTWARE.
-- ******************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.tb_base_pkg.all;
use work.tb_bus_pkg.all;
use work.tb_signals_pkg.all;

entity tbTop is
    generic(
        stimulus_path : string := "../tb/simstm/";
        stimulus_file : string := "testUnits.stm";
        stimulus_main_entry_label : string := "SimStmTest.testMain";
        stimulus_test_suite_index : integer := 255;
        machine_value_width : integer := 2 ** (stimulus_test_suite_index rem 4) * 32
    );
end;

architecture behavioural of tbTop is

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';

    signal executing_line : integer := 0;
    signal executing_file : text_line;
    signal marker : std_logic_vector(15 downto 0) := (others => '0');

    signal signals_in : t_signals_in := signals_in_init;
    signal signals_out : t_signals_out := signals_out_init;
    signal bus_down : t_bus_down := bus_down_init;
    signal bus_up : t_bus_up := bus_up_init;

begin

    clk <= transport (not clk) after 10 ns / 2; -- 100MHz

    -- base
    signals_in.test_suite_index <= stimulus_test_suite_index;
    signals_in.sim_time <= (now / 1 ns);
    signals_in.machine_value_width <= machine_value_width;
    rst <= signals_out.dut_reset;

    -- interrupt signal command tests
    signals_in.interrupt_a <= signals_out.provoke_interrupt_a;
    signals_in.interrupt_b <= signals_out.provoke_interrupt_b;

    -- I/O port signal command tests
    signals_in.loopback_1bit <= signals_out.loopback_1bit;
    signals_in.loopback_32bit <= signals_out.loopback_32bit;

    gen_cross : for i in signals_out.loopback_16bit_cross'range generate
        signals_in.loopback_16bit_cross(signals_out.loopback_16bit_cross'left - i) <= signals_out.loopback_16bit_cross(i);
    end generate;


    i_tb_simstm : entity work.tb_simstm
        generic map(
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file,
            stimulus_main_entry_label => stimulus_main_entry_label,
            machine_value_width => machine_value_width
        )
        port map(
            executing_line => executing_line,
            executing_file => executing_file,
            verify_assertions => signals_in.simstm_loopback_verify_assertions,
            verify_failures => signals_in.simstm_loopback_verify_failures,
            bus_timeout_assertions => signals_in.simstm_loopback_bus_timeout_assertions,
            bus_timeout_failures => signals_in.simstm_loopback_bus_timeout_failures,
            verify_failure_expected => signals_out.simstm_loopback_verify_failure_expected,
            bus_timeout_failure_expected => signals_out.simstm_loopback_bus_timeout_failure_expected,

            marker => marker,

            signals_in => signals_in,
            signals_out => signals_out,
            bus_down => bus_down,
            bus_up => bus_up
        );

    i_RamWishbone_32 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => rst,
            i_clk => bus_up.wishbone32.clk,
            i_adr => bus_down.wishbone32.adr(9 downto 2),
            i_dat => bus_down.wishbone32.data,
            i_we => bus_down.wishbone32.we,
            i_sel => bus_down.wishbone32.sel,
            i_cyc => bus_down.wishbone32.cyc,
            i_stb => bus_down.wishbone32.stb,
            o_dat => bus_up.wishbone32.data,
            o_ack => bus_up.wishbone32.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );

    bus_up.wishbone32.clk <= clk;

    i_RamWishbone_64 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 7,
            DATA_WIDTH => 64,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => rst,
            i_clk => bus_up.wishbone64.clk,
            i_adr => bus_down.wishbone64.adr(9 downto 3),
            i_dat => bus_down.wishbone64.data,
            i_we => bus_down.wishbone64.we,
            i_sel => bus_down.wishbone64.sel,
            i_cyc => bus_down.wishbone64.cyc,
            i_stb => bus_down.wishbone64.stb,
            o_dat => bus_up.wishbone64.data,
            o_ack => bus_up.wishbone64.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );

    bus_up.wishbone64.clk <= clk;

    i_RamWishbone_128 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 6,
            DATA_WIDTH => 128,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => rst,
            i_clk => bus_up.wishbone128.clk,
            i_adr => bus_down.wishbone128.adr(9 downto 4),
            i_dat => bus_down.wishbone128.data,
            i_we => bus_down.wishbone128.we,
            i_sel => bus_down.wishbone128.sel,
            i_cyc => bus_down.wishbone128.cyc,
            i_stb => bus_down.wishbone128.stb,
            o_dat => bus_up.wishbone128.data,
            o_ack => bus_up.wishbone128.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );

    bus_up.wishbone128.clk <= clk;

    i_RamWishbone_256 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 5,
            DATA_WIDTH => 256,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => rst,
            i_clk => bus_up.wishbone256.clk,
            i_adr => bus_down.wishbone256.adr(9 downto 5),
            i_dat => bus_down.wishbone256.data,
            i_we => bus_down.wishbone256.we,
            i_sel => bus_down.wishbone256.sel,
            i_cyc => bus_down.wishbone256.cyc,
            i_stb => bus_down.wishbone256.stb,
            o_dat => bus_up.wishbone256.data,
            o_ack => bus_up.wishbone256.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );

    bus_up.wishbone256.clk <= clk;

    i_RamAvalon_32 : entity work.RamAvalon
        generic map(
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32
        )
        port map(
            -- avalon slave signals.
            clk_i => bus_up.avalonmm32.clk,
            rst_i => rst,
            avm_waitrequest_o => bus_up.avalonmm32.waitrequest,
            avm_write_i => bus_down.avalonmm32.write,
            avm_read_i => bus_down.avalonmm32.read,
            avm_address_i => bus_down.avalonmm32.address(9 downto 2),
            avm_writedata_i => bus_down.avalonmm32.writedata,
            avm_byteenable_i => bus_down.avalonmm32.byteenable,
            avm_burstcount_i => x"01",
            avm_readdata_o => bus_up.avalonmm32.readdata,
            avm_readdatavalid_o => open
        );

    bus_up.avalonmm32.clk <= clk;

    i_RamAvalon_64 : entity work.RamAvalon
        generic map(
            ADDRESS_WIDTH => 7,
            DATA_WIDTH => 64
        )
        port map(
            -- avalon slave signals.
            clk_i => bus_up.avalonmm64.clk,
            rst_i => rst,
            avm_waitrequest_o => bus_up.avalonmm64.waitrequest,
            avm_write_i => bus_down.avalonmm64.write,
            avm_read_i => bus_down.avalonmm64.read,
            avm_address_i => bus_down.avalonmm64.address(9 downto 3),
            avm_writedata_i => bus_down.avalonmm64.writedata,
            avm_byteenable_i => bus_down.avalonmm64.byteenable,
            avm_burstcount_i => x"01",
            avm_readdata_o => bus_up.avalonmm64.readdata,
            avm_readdatavalid_o => open
        );

    bus_up.avalonmm64.clk <= clk;

    i_RamAxi4Lite_32 : entity work.RamAxi4Lite
        generic map(
            ADDRESS_WIDTH => 8
        )
        port map(
            clk => bus_up.axi4lite32.clk,
            rst => rst,
            AWVALID => bus_down.axi4lite32.awvalid,
            AWADDR => bus_down.axi4lite32.awaddr(9 downto 2),
            AWPROT => bus_down.axi4lite32.awprot,
            AWREADY => bus_up.axi4lite32.awready,
            WVALID => bus_down.axi4lite32.wvalid,
            WDATA => bus_down.axi4lite32.wdata,
            WSTRB => bus_down.axi4lite32.wstrb,
            WREADY => bus_up.axi4lite32.wready,
            BREADY => bus_down.axi4lite32.bready,
            BVALID => bus_up.axi4lite32.bvalid,
            BRESP => bus_up.axi4lite32.bresp,
            ARVALID => bus_down.axi4lite32.arvalid,
            ARADDR => bus_down.axi4lite32.araddr(9 downto 2),
            ARPROT => bus_down.axi4lite32.arprot,
            ARREADY => bus_up.axi4lite32.arready,
            RREADY => bus_down.axi4lite32.rready,
            RVALID => bus_up.axi4lite32.rvalid,
            RDATA => bus_up.axi4lite32.rdata,
            RRESP => bus_up.axi4lite32.rresp
        );

    bus_up.axi4lite32.clk <= clk;

    i_Ram32 : entity work.Ram
        port map(
            Clk => bus_up.ram32.clk,
            WriteEnable => bus_down.ram32.write_enable,
            Address => bus_down.ram32.address(9 downto 2),
            WriteData => bus_down.ram32.write_data,
            ReadData => bus_up.ram32.read_data
        );

    bus_up.ram32.clk <= clk;

end architecture;
