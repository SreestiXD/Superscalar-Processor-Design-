library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionDecoder is
  port(
    instruction : in  std_logic_vector(31 downto 0);
    PC_in       : in  std_logic_vector(31 downto 0);
    valid_in    : in  std_logic;
	 
    opcode      : out std_logic_vector(6 downto 0);
    rd          : out std_logic_vector(4 downto 0);
    funct3      : out std_logic_vector(2 downto 0);
    rs1         : out std_logic_vector(4 downto 0);
    rs2         : out std_logic_vector(4 downto 0);
    funct7      : out std_logic_vector(6 downto 0);
    PC_out      : out std_logic_vector(31 downto 0);
    valid_out   : out std_logic;
    -- Sign-extended immediates
    imm_I       : out std_logic_vector(31 downto 0);
    imm_S       : out std_logic_vector(31 downto 0);
    imm_B       : out std_logic_vector(31 downto 0);
    imm_U       : out std_logic_vector(31 downto 0);
    imm_J       : out std_logic_vector(31 downto 0);
    -- Shift amount for I-type shifts
    shamt       : out std_logic_vector(4 downto 0)
  );
end InstructionDecoder;

architecture Behavioral of InstructionDecoder is
  function signext(input : signed; size : natural) return signed is
  begin
    return resize(input, size);
  end function;
begin
  process(instruction, PC_in, valid_in)
  begin
    if valid_in = '1' then
      opcode  <= instruction(6 downto 0);
      rd      <= instruction(11 downto 7);
      funct3  <= instruction(14 downto 12);
      rs1     <= instruction(19 downto 15);
      rs2     <= instruction(24 downto 20);
      funct7  <= instruction(31 downto 25);
  
      imm_I <= std_logic_vector(signext(signed(instruction(31 downto 20)), 32));
      imm_S <= std_logic_vector(signext(signed(instruction(31 downto 25) & instruction(11 downto 7)), 32));
      imm_B <= std_logic_vector(signext(signed(instruction(31) & instruction(7) & instruction(30 downto 25) & instruction(11 downto 8) & '0'), 32));
      imm_U <= instruction(31 downto 12) & (11 downto 0 => '0');
      imm_J <= std_logic_vector(signext(signed(instruction(31) & instruction(19 downto 12) & instruction(20) & instruction(30 downto 21) & '0'), 32));
  
      shamt <= instruction(24 downto 20);
      PC_out <= PC_in;
    else
      opcode  <= (others => '0');
      rd      <= (others => '0');
      funct3  <= (others => '0');
      rs1     <= (others => '0');
      rs2     <= (others => '0');
      funct7  <= (others => '0');

      imm_I   <= (others => '0');
      imm_S   <= (others => '0');
      imm_B   <= (others => '0');
      imm_U   <= (others => '0');
      imm_J   <= (others => '0');

      shamt   <= (others => '0');
      PC_out  <= (others => '0');
    end if;

    valid_out <= valid_in;
  end process;
end Behavioral;
