library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionFetch is
    generic (
        MEM_DEPTH : integer := 32  -- Number of 32-bit instructions
    );
    port (
        clk            : in  std_logic;
		  PC 				  : in  std_logic_vector(6 downto 0);;
        BranchTaken    : in  std_logic;
        BranchTarget   : in  std_logic_vector(31 downto 0);
        Stall          : in  std_logic;
        Flush          : in  std_logic;
        Instr1         : out std_logic_vector(31 downto 0);
        Instr2         : out std_logic_vector(31 downto 0);
        PC_plus4       : out std_logic_vector(6 downto 0);
        PC_plus8       : out std_logic_vector(6 downto 0);
        Fetch_Valid    : out std_logic;
        PC_out         : out std_logic_vector(6 downto 0)
    );
end InstructionFetch;

architecture Behavioral of InstructionFetch is
    --Component: Instruction memory
    type mem_type is array(0 to MEM_DEPTH-1) of std_logic_vector(6 downto 0);
    signal InstrMem : mem_type := (others => (others => '0')); -- Will fill the IMEM later (8 instructions) !!!!
	 -- Note: To initialize InstrMem with actual instructions, I will use a memory initialization file
	 
    --Component: Program Counter register
    signal PC_reg    : std_logic_vector(6 downto 0) := (others => '0');
    signal valid_reg : std_logic := '0';
begin
    process(clk, reset)
    begin
        if rising_edge(clk) then
            if Stall = '1' then
                -- Hold PC and valid signal
                PC_reg    <= PC_reg;
                valid_reg <= valid_reg;
            else
                if BranchTaken = '1' then
                    PC_reg    <= BranchTarget;
                    valid_reg <= '1';  
                else
                    -- Normal sequential fetch
                    PC_reg <= std_logic_vector(unsigned(PC_reg) + 8);
                    if Flush = '1' then
                        valid_reg <= '0';
                    else
                        valid_reg <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Instruction fetch
    Instr1 <= InstrMem( to_integer(unsigned(PC_reg(6 downto 2))) );
	 Instr2 <= InstrMem( to_integer(unsigned(PC_reg(6 downto 2))) + 1 );
	 
    -- Output next-PC values and debug signals
    PC_plus4    <= std_logic_vector(unsigned(PC_reg) + 4);
    PC_plus8    <= std_logic_vector(unsigned(PC_reg) + 8);
    PC_out      <= PC_reg;
    Fetch_Valid <= valid_reg;

end Behavioral;