library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dut is
    port(
        Rst : in std_logic;
        Clk : in std_logic;
        Active : out std_logic;
        StepDown : in std_logic;
        StepUp : in std_logic;
        Count : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of Dut is

signal shDown : std_logic_vector(2 downto 0);
signal shUp : std_logic_vector(2 downto 0);
signal counter : unsigned( 7 downto 0);

begin

    Count <= std_logic_vector(counter);
    
    proc : process(Clk) is
    begin
        if rising_edge(Clk) then
            if Rst then
                Active <= '0';
                shDown <= (others => '0');
                shUp <= (others => '0');
                counter <= (others => '0');
            else
                Active <= '1';
                shDown <= StepDown & shDown(2 downto 1);
                shUp <= StepUp & shUp(2 downto 1);
                if shDown(1 downto 0) = "10" then
                    counter <= counter - 1;
                elsif shUp(1 downto 0) = "10" then
                    counter <= counter + 1;
                end if;
            end if;

        end if;
    end process;
    
end architecture;
