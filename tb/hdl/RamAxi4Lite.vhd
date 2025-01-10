library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity RamAxi4Lite is
    generic(
        ADDRESS_WIDTH : positive -- Determines the size of the RAM (num. of words = 2**ADDRESS_WIDTH)
        -- DATA_WIDTH is 32 bits for Axi4Lite
        -- GRANULARITY is 8 bits for Axi4Lite
    );
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
end;

architecture Behavioural of RamAxi4Lite is

    type T_Axi4LiteWriteState is (
        Axi4LiteWriteStateIdle,
        Axi4LiteWriteStateAddress,
        Axi4LiteWriteStateData,
        Axi4LiteWriteStateResp,        
        Axi4LiteWriteStateDone
    );

    type T_Axi4LiteReadState is (
        Axi4LiteReadStateIdle,
        Axi4LiteReadStateAddress,
        Axi4LiteReadStateData,
        Axi4LiteReadStateDone
    );

    signal Axi4LiteReadState : T_Axi4LiteReadState;
    signal Axi4LiteWriteState : T_Axi4LiteWriteState;

    signal ReadAck : std_logic;
    signal ReadData : std_logic_vector(31 downto 0);
    signal Read : std_logic;
    signal ReadAddress : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
    signal WriteAck : std_logic;
    signal Write : std_logic;
    signal WriteAddress : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
    signal WriteData : std_logic_vector(31 downto 0);
    signal WriteStrobe : std_logic_vector(3 downto 0);
    
    type T_Ram is array (0 to 2 ** ADDRESS_WIDTH - 1) of std_logic_vector(WriteData'range);
            
    signal Ram : T_Ram := (0 to 2 ** ADDRESS_WIDTH - 1 => (others => '0'));
    signal RamAddress : std_logic_vector(ADDRESS_WIDTH - 1 downto 0);
    signal RamReadAddress : std_logic_vector(RamAddress'range);
    signal RamByteSelect : std_logic_vector(3 downto 0);
    
    signal WriteDiffRam : std_logic;
    signal ReadDiffRam : std_logic;
    signal DelWriteDiffRam : std_logic;
    signal ReadDecRam : std_logic_vector(2 downto 0);
    signal WriteDecRam : std_logic_vector(1 downto 0);
    signal DataWritten : std_logic_vector(31 downto 0);

begin

    prcAxi4LiteRead : process(Clk, Rst) is
    begin
        if Rst = '1' then
            ARREADY <= '0';
            RVALID <= '0';
            RDATA <= (others => '0');
            Read <= '0';
            ReadAddress <= (ReadAddress'range => '0');
            Axi4LiteReadState <= Axi4LiteReadStateIdle;
        elsif rising_edge(Clk) then
            ARREADY <= '0';
            RVALID <= '0';
            case Axi4LiteReadState is
                when Axi4LiteReadStateIdle =>
                    Read <= '0';
                    ReadAddress <= (ReadAddress'range => '0');
                    if ARVALID = '1' then
                        ReadAddress <= ARADDR;
                        Axi4LiteReadState <= Axi4LiteReadStateAddress;
                    end if;
                when Axi4LiteReadStateAddress =>
                    ARREADY <= '1';
                    Axi4LiteReadState <= Axi4LiteReadStateData;
                    Read <= '1';
                when Axi4LiteReadStateData =>                   
                    RDATA <= ReadData;
                    if ReadAck = '1' then
                        RVALID <= '1';
                        Axi4LiteReadState <= Axi4LiteReadStateDone;
                    end if;
                when Axi4LiteReadStateDone =>
                    RVALID <= '1';
                    if RREADY = '1' then
                        RVALID <= '0';
                        ReadAddress <= (ReadAddress'range => '0');
                        Read <= '0';
                        Axi4LiteReadState <= Axi4LiteReadStateIdle;
                    end if;
            end case;
        end if;
    end process;
    
    RRESP <= "00";

    prcAxi4LiteWrite : process(Clk, Rst) is
    begin
        if Rst = '1' then
            AWREADY <= '0';
            WREADY <= '0';
            BVALID <= '0';
            Write <= '0';
            WriteAddress <= (WriteAddress'range => '0');
            WriteData <= (others => '0');
            WriteStrobe <= (others => '0');
            Axi4LiteWriteState <= Axi4LiteWriteStateIdle;
        elsif rising_edge(Clk) then
            AWREADY <= '0';
            WREADY <= '0';
            BVALID <= '0';
            case Axi4LiteWriteState is
                when Axi4LiteWriteStateIdle =>
                    Write <= '0';
                    WriteAddress <= (WriteAddress'range => '0');
                    if AWVALID = '1' then
                        WriteAddress <= AWADDR;
                        Axi4LiteWriteState <= Axi4LiteWriteStateAddress;
                    end if;
                when Axi4LiteWriteStateAddress =>
                    AWREADY <= '1';
                    WREADY <= '1';
                    Axi4LiteWriteState <= Axi4LiteWriteStateData;
                when Axi4LiteWriteStateData =>
                    WREADY <= '1';
                    WriteData <= WDATA;
                    WriteStrobe <= WSTRB;
                    if WVALID = '1' then
                        WREADY <= '0';
                        Write <= '1';
                        Axi4LiteWriteState <= Axi4LiteWriteStateResp;
                    end if;
                when Axi4LiteWriteStateResp =>
                    Write <= '1';
                    if WriteAck = '1' then
                        Write <= '0';
                        BVALID <= '1';
                        Axi4LiteWriteState <= Axi4LiteWriteStateDone;
                    end if;
                when Axi4LiteWriteStateDone =>
                    BVALID <= '1';
                    if BREADY = '1' then
                        WriteAddress <= (WriteAddress'range => '0');                      
                        BVALID <= '0';
                        Axi4LiteWriteState <= Axi4LiteWriteStateIdle;
                    end if;
            end case;
        end if;
    end process;
    
    BRESP <= "00";
   
    prcRamCtrl : process (Clk, Rst)
    begin
        if (Rst = '1') then
            ReadDecRam <= (others => '0');
            WriteDecRam <= (others => '0');
            DelWriteDiffRam <= '0'; 
            ReadAck <= '0';
            WriteAck <= '0';
            DataWritten <= (others => '0');
            RamAddress <= (RamAddress'range => '0');
            RamByteSelect <= (others => '0');
        elsif rising_edge(Clk) then
            ReadDecRam <= Read & ReadDecRam(2 downto 1); 
            WriteDecRam <= Write & WriteDecRam(1);
            DelWriteDiffRam <= WriteDiffRam;
            ReadAck <= ReadDecRam(0);
            WriteAck <= WriteDecRam(0);
            if (WriteDiffRam = '1') then
                if (WriteStrobe(3) = '1') then DataWritten(31 downto 24) <= WriteData(31 downto 24); end if;
                if (WriteStrobe(2) = '1') then DataWritten(23 downto 16) <= WriteData(23 downto 16); end if;
                if (WriteStrobe(1) = '1') then DataWritten(15 downto 8) <= WriteData(15 downto 8); end if;
                if (WriteStrobe(0) = '1') then DataWritten(7 downto 0) <= WriteData(7 downto 0); end if;
                RamAddress <= WriteAddress;
                RamByteSelect <= WriteStrobe;
            end if;
            if (ReadDiffRam = '1') then
                RamAddress <= ReadAddress;
            end if;
        end if;
    end process;
    
    WriteDiffRam <= WriteDecRam(1) and not WriteDecRam(0);
    ReadDiffRam <= ReadDecRam(2) and not ReadDecRam(1);

    prcRam : process(Clk) is
    begin
        if rising_edge(Clk) then
            for i in 0 to RamByteSelect'left loop   
                if RamByteSelect(i) = '1' and DelWriteDiffRam = '1' then
                    Ram(to_integer(unsigned(RamAddress)))(i * 8 + 7 downto i * 8) <= DataWritten(i * 8 + 7 downto i * 8);
                end if;
            end loop;
            RamReadAddress <= RamAddress;
        end if;
    end process;

    ReadData <= Ram(to_integer(unsigned(RamReadAddress)));

end architecture;

