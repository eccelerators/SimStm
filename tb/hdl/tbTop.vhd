-- ******************************************************************************
-- 
--                   /------o
--             eccelerators
--          o------/
-- 
--  This file is an Eccelerators GmbH sample project.
-- 
--  MIT License:
--  Copyright (c) 2023 Eccelerators GmbH
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
    generic (
        stimulus_path : string := "tb/simstm/";
        stimulus_file : string := "testMain.stm";
        stimulus_main_entry_label : string := "$testMain";
        stimulus_test_suite_index : integer := 255
    );
end;

architecture behavioural of tbTop is

    constant NsPerClk : natural := 10;

    signal Clk : std_logic := '0';
    signal Rst : std_logic := '1';
    
    signal executing_line : integer := 0;
    signal executing_file : text_line;
    signal marker : std_logic_vector(15 downto 0) := (others => '0');
    signal standard_test_error_count : std_logic_vector(31 downto 0);
     
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
    signals_in.in_signal_3 <= standard_test_error_count;
    -- 
    -- standard outputs
    InitDut <= signals_out.out_signal_0;
    -- signals_out.out_signal_3 <= expected_standard_test_error_count already connected in tb_simstm
   
    -- interrupts
    signals_in.in_signal_1000 <= '0';
    signals_in.in_signal_1001 <= '0';
        
    -- user inputs and outputs
    signals_in.in_signal_2000 <= signals_out.out_signal_3000;
    signals_in.in_signal_2001 <= signals_out.out_signal_3001;
    signals_in.in_signal_2002 <= signals_out.out_signal_3002;
    signals_in.in_signal_2003 <= signals_out.out_signal_3003;
    
    Rst <= InitDut;
    
    i_tb_simstm : entity work.tb_simstm
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file          
        )
        port map (
            executing_line => executing_line,
            executing_file => executing_file,
            standard_test_error_count => standard_test_error_count,
            marker => marker,
            signals_in => signals_in,
            signals_out => signals_out,
            bus_down => bus_down,
            bus_up => bus_up
        ); 
        
    i_RamWishbone : entity work.RamWishbone
        generic map (
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32,
            GRANULARITY => 8
        )
        port map(
        -- wishbone slave signals.
            i_rst => Rst,
            i_clk => Clk,
            i_adr => bus_down.wishbone.adr(7 downto 0),
            i_dat => bus_down.wishbone.data,
            i_we  => bus_down.wishbone.we,
            i_sel => bus_down.wishbone.sel,
            i_cyc => bus_down.wishbone.cyc,
            i_stb => bus_down.wishbone.stb,
            o_dat => bus_up.wishbone.data,
            o_ack => bus_up.wishbone.ack,
            o_stall => open,
            o_rty => open,
            o_err => open
        );
               
        bus_up.wishbone.clk <= Clk;      
                
    i_RamAvalon : entity work.RamAvalon
        generic map (
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32
        )
        port map(
        -- avalon slave signals.
            clk_i => Clk,
            rst_i => Rst,
            avm_waitrequest_o => bus_up.avalonmm.waitrequest,
            avm_write_i => bus_down.avalonmm.write,
            avm_read_i => bus_down.avalonmm.read,
            avm_address_i => bus_down.avalonmm.address(7 downto 0),
            avm_writedata_i => bus_down.avalonmm.writedata,
            avm_byteenable_i => bus_down.avalonmm.byteenable,
            avm_burstcount_i => x"00",
            avm_readdata_o => bus_up.avalonmm.readdata,
            avm_readdatavalid_o => open
        );
        
        bus_up.avalonmm.clk <= Clk;
               
    i_RamAxi4Lite : entity work.RamAxi4Lite
        generic map (
            ADDRESS_WIDTH => 8
        )
        port map (
            Clk => Clk,
            Rst => Rst,
            AWVALID => bus_down.axi4lite.awvalid,
            AWADDR => bus_down.axi4lite.awaddr(15 downto 0),
            AWPROT => bus_down.axi4lite.awprot,
            AWREADY => bus_up.axi4lite.awready,
            WVALID => bus_down.axi4lite.wvalid,
            WDATA => bus_down.axi4lite.wdata,
            WSTRB => bus_down.axi4lite.wstrb,
            WREADY => bus_up.axi4lite.wready,
            BREADY => bus_down.axi4lite.bready,
            BVALID => bus_up.axi4lite.bvalid,
            BRESP => bus_up.axi4lite.bresp,
            ARVALID => bus_down.axi4lite.arvalid,
            ARADDR => bus_down.axi4lite.araddr(15 downto 0),
            ARPROT => bus_down.axi4lite.arprot,
            ARREADY => bus_up.axi4lite.arready,
            RREADY => bus_down.axi4lite.rready,
            RVALID => bus_up.axi4lite.rvalid,
            RDATA => bus_up.axi4lite.rdata,
            RRESP => bus_up.axi4lite.rresp
        );
        
    bus_up.axi4lite.clk <= Clk;
                                                                  
end architecture;