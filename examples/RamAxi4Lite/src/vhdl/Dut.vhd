library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.basic.all;

entity Dut is
    port(
        Clk : in std_logic;
        Rst : in std_logic;
        AWVALID : in std_logic;
        AWADDR : in std_logic_vector;
        AWPROT : in std_logic_vector(2 downto 0);
        AWREADY : out std_logic;
        WVALID : in std_logic;
        WDATA : in std_logic_vector(31 downto 0);
        WSTRB : in std_logic_vector(3 downto 0);
        WREADY : out std_logic;
        BREADY : in std_logic;
        BVALID : out std_logic;
        BRESP : out std_logic_vector(1 downto 0);
        ARVALID : in std_logic;
        ARADDR : in std_logic_vector;
        ARPROT : in std_logic_vector(2 downto 0);
        ARREADY : out std_logic;
        RREADY : in std_logic;
        RVALID : out std_logic;
        RDATA : out std_logic_vector(31 downto 0);
        RRESP : out std_logic_vector(1 downto 0)
    );
end entity;

architecture rtl of Dut is
begin
    i_RamAxi4Lite_32 : entity work.RamAxi4Lite
        generic map(
            ADDRESS_WIDTH => 8
        )
        port map(
            clk => clk,
            rst => rst,
            AWVALID => AWVALID,
            AWADDR => AWADDR,
            AWPROT => AWPROT,
            AWREADY => AWREADY,
            WVALID => WVALID,
            WDATA => WDATA,
            WSTRB => WSTRB,
            WREADY => WREADY,
            BREADY => BREADY,
            BVALID => BVALID,
            BRESP => BRESP,
            ARVALID => ARVALID,
            ARADDR => ARADDR,
            ARPROT => ARPROT,
            ARREADY => ARREADY,
            RREADY => RREADY,
            RVALID => RVALID,
            RDATA => RDATA,
            RRESP => RRESP
        );

end architecture;
