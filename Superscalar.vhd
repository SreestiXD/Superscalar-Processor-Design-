library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library STD;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;  -- For reading std_logic_vector

entity InstructionFetch is
    generic (
        MEM_DEPTH : integer := 32  -- Number of 32-bit instructions
    );
    port (
        clk            : in  std_logic;
        PC             : in  std_logic_vector(31 downto 0);
        BranchTaken    : in  std_logic;
        BranchTarget   : in  std_logic_vector(31 downto 0);
        Stall          : in  std_logic;
        Flush          : in  std_logic;
        Jump           : in  std_logic;
        Jump_Target    : in  std_logic_vector(31 downto 0);
        
        Instr1         : out std_logic_vector(31 downto 0);
        Instr2         : out std_logic_vector(31 downto 0);
        PC_plus4       : out std_logic_vector(31 downto 0);
        PC_plus8       : out std_logic_vector(31 downto 0);
        Fetch_Valid    : out std_logic;
        PC_out         : out std_logic_vector(31 downto 0)
    );
end InstructionFetch;

architecture Behavioral of InstructionFetch is
    -- Instruction memory
    type mem_type is array(0 to MEM_DEPTH-1) of std_logic_vector(31 downto 0);
    signal InstrMem : mem_type := (others => (others => '0')); -- 32-instruction memory (to be initialized separately)

	 -- File loading 
	 file instr_file : text open read_mode is "instructions.txt";
  
    signal PC_reg        : std_logic_vector(31 downto 0);
    signal PC_in         : std_logic_vector(31 downto 0);
    signal Fetch_valid_s : std_logic := '1';

begin
	  -- Initialize IMEM once at simulation start
	 init_mem : process
		 variable line_buf : line;
		 variable i        : integer := 0;
		 variable instr    : std_logic_vector(31 downto 0);
		 begin
			while not endfile(instr_file) and i < MEM_DEPTH loop
				readline(instr_file, line_buf);
				read(line_buf, instr);
				InstrMem(i) <= instr;
				i := i + 1;
			end loop;
		 wait;  -- one-time init
	 end process;
	 process(clk)
    begin
        if rising_edge(clk) then
            if Stall = '1' then
                -- Hold PC and valid signal
                PC_reg        <= PC_reg;
                Fetch_valid_s <= Fetch_valid_s;
            else
                if Jump = '1' then
                    PC_reg        <= Jump_Target;
                    Fetch_valid_s <= '1';
                elsif BranchTaken = '1' then
                    PC_reg        <= BranchTarget;
                    Fetch_valid_s <= '1';
                else
                    PC_reg <= PC_in;
                    if Flush = '1' then
                        Fetch_valid_s <= '0';
                    else
                        Fetch_valid_s <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Combinational logic
    PC_in       <= PC;
    PC_plus4    <= std_logic_vector(unsigned(PC_reg) + 4);
    PC_plus8    <= std_logic_vector(unsigned(PC_reg) + 8);
    Instr1      <= InstrMem(to_integer(unsigned(PC_reg(31 downto 2))));
    Instr2      <= InstrMem(to_integer(unsigned(PC_reg(31 downto 2))) + 1);
    PC_out      <= PC_reg;
    Fetch_Valid <= Fetch_valid_s;

end Behavioral;
