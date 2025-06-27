library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity IF_ID_pipeline_reg is
  port (
    clk         : in  std_logic;
    Stall       : in  std_logic;    -- when '1', hold current state
    Flush       : in  std_logic;    -- when '1', inject a bubble
    -- Inputs from IF stage
    Instr1_in   : in  std_logic_vector(31 downto 0);
    Instr2_in   : in  std_logic_vector(31 downto 0);
    PC_in       : in  std_logic_vector(6 downto 0);  
    PC_plus4_in : in  std_logic_vector(6 downto 0); 
	 PC_plus8_in : in  std_logic_vector(6 downto 0); 
    Valid_in    : in  std_logic;
    -- Outputs to ID stage
    Instr1_out  : out std_logic_vector(31 downto 0);
    Instr2_out  : out std_logic_vector(31 downto 0);
    PC_out      : out std_logic_vector(6 downto 0);
    PC_plus4_out: out std_logic_vector(6 downto 0);
    PC_plus8_out: out std_logic_vector(6 downto 0);
    Valid_out   : out std_logic
  );
end IF_ID_pipeline_reg;

architecture RTL of IF_ID_pipeline_reg is
  signal r_Instr1 : std_logic_vector(31 downto 0);
  signal r_Instr2 : std_logic_vector(31 downto 0);
  signal r_PC     : std_logic_vector(6 downto 0);
  signal r_PC_plus4    : std_logic_vector(6 downto 0);
  signal r_PC_plus8    : std_logic_vector(6 downto 0);
  signal r_Valid  : std_logic;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if Stall = '1' then
        -- hold previous values
        r_Instr1 <= r_Instr1;
        r_Instr2 <= r_Instr2;
        r_PC     <= r_PC;
        r_PC_plus4    <= r_PC_plus4;
        r_PC_plus8    <= r_PC_plus8;
        r_Valid  <= r_Valid;
      elsif Flush = '1' then
        -- inject bubble (NOPs)
        r_Instr1 <= (others => '0');
        r_Instr2 <= (others => '0');
        r_PC     <= (others => '0');
        r_PC_plus4    <= (others => '0');
        r_PC_plus8    <= (others => '0');
		  r_Valid  <= '0';
      else
        -- normal 
        r_Instr1 <= Instr1_in;
        r_Instr2 <= Instr2_in;
        r_PC     <= PC_in;
        r_PC_plus4    <= PC_plus4_in;
        r_PC_plus8    <= PC_plus8_in;
        r_Valid  <= Valid_in;
      end if;
    end if;
  end process;

  -- drive outputs
  Instr1_out <= r_Instr1;
  Instr2_out <= r_Instr2;
  PC_out     <= r_PC;
  NPC_out    <= r_NPC;
  Valid_out  <= r_Valid;

end RTL;
