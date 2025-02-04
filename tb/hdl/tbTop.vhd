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
use work.basic.all;

entity tbTop is
    generic(
        stimulus_path : string := "tb/simstm/";
        stimulus_file : string := "testMain.stm";
        stimulus_main_entry_label : string := "$testMain";
        stimulus_test_suite_index : integer := 255;
        Ram32InitialCellValues : array_of_std_logic_vector(0 to 63)(31 downto 0) := (others => x"BABABABA");
        machine_value_width : integer := 2 ** (stimulus_test_suite_index rem 4) * 32;
        machine_address_width : integer := 31
    );
end;

architecture behavioural of tbTop is

    signal Clk : std_logic := '0';
    signal Rst : std_logic := '1';

    signal executing_line : integer := 0;
    signal executing_file : text_line;
    signal marker : std_logic_vector(15 downto 0) := (others => '0');
    signal verify_passes : std_logic_vector(31 downto 0);
    signal verify_failures : std_logic_vector(31 downto 0);
    signal bus_timeout_passes : std_logic_vector(31 downto 0);
    signal bus_timeout_failures : std_logic_vector(31 downto 0);

    signal signals_in : t_signals_in;
    signal signals_out : t_signals_out;
    signal bus_down : t_bus_down;
    signal bus_up : t_bus_up;

    signal InitDut : std_logic;

begin

    Clk <= transport (not Clk) after 10 ns / 2; -- 100MHz

    -- standard inputs
    -- signals_in.in_signal_0 actual simulation time already supplied by package
    signals_in.in_signal_1 <= std_logic_vector(to_unsigned(stimulus_test_suite_index, 32));
    -- signals_in.in_signal_2 constant 0 already supplied by package
    signals_in.in_signal_3 <= verify_passes;
    signals_in.in_signal_4 <= verify_failures;
    signals_in.in_signal_5 <= bus_timeout_passes;
    signals_in.in_signal_6 <= bus_timeout_failures;
    -- signals_in.in_signal_7 Machine value width

    -- standard outputs
    InitDut <= signals_out.out_signal_0;
    -- signals_out.out_signal_4 <= expected_standard_test_verify_failure_count already connected in tb_simstm
    -- signals_out.out_signal_6 <= expected_bus_timeout_test_failure_count already connected in tb_simstm

    -- interrupts
    signals_in.in_signal_1000 <= signals_out.out_signal_3002;
    signals_in.in_signal_1001 <= signals_out.out_signal_3003;

    -- user inputs and outputs
    signals_in.in_signal_2000 <= signals_out.out_signal_3000;
    signals_in.in_signal_2001 <= signals_out.out_signal_3001;
    signals_in.in_signal_2002 <= signals_out.out_signal_3002;
    signals_in.in_signal_2003 <= signals_out.out_signal_3003;

    Rst <= InitDut;

    i_tb_simstm : entity work.tb_simstm
        generic map(
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file,
            stimulus_main_entry_label => stimulus_main_entry_label,
            machine_value_width => machine_value_width,
            machine_address_width => machine_address_width
        )
        port map(
            executing_line => executing_line,
            executing_file => executing_file,
            verify_passes => verify_passes,
            verify_failures => verify_failures,
            bus_timeout_passes => bus_timeout_passes,
            bus_timeout_failures => bus_timeout_failures,
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
            i_rst => Rst,
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

    bus_up.wishbone32.clk <= Clk;

    i_RamWishbone_64 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 7,
            DATA_WIDTH => 64,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => Rst,
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

    bus_up.wishbone64.clk <= Clk;

    i_RamWishbone_128 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 6,
            DATA_WIDTH => 128,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => Rst,
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

    bus_up.wishbone128.clk <= Clk;

    i_RamWishbone_256 : entity work.RamWishbone
        generic map(
            ADDRESS_WIDTH => 5,
            DATA_WIDTH => 256,
            GRANULARITY => 8
        )
        port map(
            -- wishbone slave signals.
            i_rst => Rst,
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

    bus_up.wishbone256.clk <= Clk;

    i_RamAvalon_32 : entity work.RamAvalon
        generic map(
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32
        )
        port map(
            -- avalon slave signals.
            clk_i => bus_up.avalonmm32.clk,
            rst_i => Rst,
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

    bus_up.avalonmm32.clk <= Clk;

    i_RamAvalon_64 : entity work.RamAvalon
        generic map(
            ADDRESS_WIDTH => 7,
            DATA_WIDTH => 64
        )
        port map(
            -- avalon slave signals.
            clk_i => bus_up.avalonmm64.clk,
            rst_i => Rst,
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

    bus_up.avalonmm64.clk <= Clk;

    i_RamAxi4Lite_32 : entity work.RamAxi4Lite
        generic map(
            ADDRESS_WIDTH => 8
        )
        port map(
            Clk => bus_up.axi4lite32.clk,
            Rst => Rst,
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

    bus_up.axi4lite32.clk <= Clk;

    i_Ram32 : entity work.Ram
        generic map(
            InitialCellValues => Ram32InitialCellValues
        )
        port map(
            Clk => bus_up.ram32.clk,
            WriteEnable => bus_down.ram32.write_enable,
            Address => bus_down.ram32.address(9 downto 2),
            WriteData => bus_down.ram32.write_data,
            ReadData => bus_up.ram32.read_data
        );

    bus_up.ram32.clk <= Clk;

end architecture;
