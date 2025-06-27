library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity InstructionDecoder is
  port(
    instruction : in  std_logic_vector(31 downto 0);
	 PC_in		 : in  std_logic_vector(6 downto 0);
    opcode      : out std_logic_vector(6 downto 0);
    rd          : out std_logic_vector(4 downto 0);
    funct3      : out std_logic_vector(2 downto 0);
    rs1         : out std_logic_vector(4 downto 0);
    rs2         : out std_logic_vector(4 downto 0);
    funct7      : out std_logic_vector(6 downto 0);
	 PC_out		 : out std_logic_vector(6 downto 0);
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
  opcode <= instruction(6 downto 0);
  rd     <= instruction(11 downto 7);
  funct3 <= instruction(14 downto 12);
  rs1    <= instruction(19 downto 15);
  rs2    <= instruction(24 downto 20);
  funct7 <= instruction(31 downto 25);

  -- I-type immediate (12-bit) → sign-extend to 32
  imm_I <= std_logic_vector(
             signext(
               signed(instruction(31 downto 20)),
               32
             )
           );

  -- S-type immediate: [31:25] & [11:7]
  imm_S <= std_logic_vector(
             signext(
               signed(instruction(31 downto 25) & instruction(11 downto 7)),
               32
             )
           );

  -- B-type immediate: {inst[31], inst[7], inst[30:25], inst[11:8], '0'}
  imm_B <= std_logic_vector(
             signext(
               signed(
                 instruction(31) &
                 instruction(7) &
                 instruction(30 downto 25) &
                 instruction(11 downto 8) &
                 '0'
               ),
               32
             )
           );

  -- U-type immediate: [31:12] << 12
  imm_U <= instruction(31 downto 12) & (11 downto 0 => '0');

  -- J-type immediate: {inst[31], inst[19:12], inst[20], inst[30:21], '0'}
  imm_J <= std_logic_vector(
             signext(
               signed(
                 instruction(31) &
                 instruction(19 downto 12) &
                 instruction(20) &
                 instruction(30 downto 21) &
                 '0'
               ),
               32
             )
           );

  -- Shift amount (lower 5 bits of I-type immediate)
  shamt <= instruction(24 downto 20);
  PC_out <= PC_in;
  
end Behavioral;
