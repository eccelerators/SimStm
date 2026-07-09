library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dut is
    port(
      clk_i : in std_logic;
      rst_i : in std_logic;
      avm_waitrequest_o : out std_logic;
      avm_write_i : in std_logic;
      avm_read_i : in std_logic;
      avm_address_i : in std_logic_vector(7 downto 0);
      avm_writedata_i : in std_logic_vector(31 downto 0);
      avm_byteenable_i : in std_logic_vector(3 downto 0);
      avm_burstcount_i : in std_logic_vector(7 downto 0);
      avm_readdata_o : out std_logic_vector(31 downto 0);
      avm_readdatavalid_o : out std_logic
    );
end entity;

architecture rtl of Dut is
begin
    i_RamAvalon_32 : entity work.RamAvalon
        generic map(
            ADDRESS_WIDTH => 8,
            DATA_WIDTH => 32
        )
        port map(
            -- avalon slave signals.
            clk_i => clk_i,
            rst_i => rst_i,
            avm_waitrequest_o => avm_waitrequest_o,
            avm_write_i => avm_write_i,
            avm_read_i => avm_read_i,
            avm_address_i => avm_address_i,
            avm_writedata_i => avm_writedata_i,
            avm_byteenable_i => avm_byteenable_i,
            avm_burstcount_i => avm_burstcount_i,
            avm_readdata_o => avm_readdata_o,
            avm_readdatavalid_o => avm_readdatavalid_o
        );

end architecture;
