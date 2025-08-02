library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControlUnit is
  port (
    opcode        : in  std_logic_vector(6 downto 0);
    imm_J         : in  std_logic_vector(31 downto 0);
    PC_in         : in  std_logic_vector(31 downto 0);
    funct3        : in  std_logic_vector(2 downto 0);
    funct7        : in  std_logic_vector(6 downto 0);
    valid_in      : in  std_logic;

    jump          : out std_logic;
    jump_target   : out std_logic_vector(31 downto 0);
    jump_select   : out std_logic;

    ALU_Op        : out std_logic_vector(2 downto 0);
    ALU_src1      : out std_logic;
    ALU_src2      : out std_logic_vector(2 downto 0);

    MemWrite      : out std_logic;
    MemRead       : out std_logic;
    MemToReg      : out std_logic
  );
end ControlUnit;

architecture Behavioral of ControlUnit is
  constant OPCODE_JAL     : std_logic_vector(6 downto 0) := "1101111";
  constant OPCODE_JALR    : std_logic_vector(6 downto 0) := "1100111";
  constant OPCODE_R       : std_logic_vector(6 downto 0) := "0110011";
  constant OPCODE_I       : std_logic_vector(6 downto 0) := "0010011";
  constant OPCODE_LOAD    : std_logic_vector(6 downto 0) := "0000011";
  constant OPCODE_STORE   : std_logic_vector(6 downto 0) := "0100011";
  constant OPCODE_BRANCH  : std_logic_vector(6 downto 0) := "1100011";
  constant OPCODE_LUI     : std_logic_vector(6 downto 0) := "0110111";
  constant OPCODE_AUIPC   : std_logic_vector(6 downto 0) := "0010111";

  constant F7_SUB : std_logic_vector(6 downto 0) := "0100000";
  constant F7_ADD : std_logic_vector(6 downto 0) := "0000000";
begin

  process(opcode, imm_J, PC_in, valid_in, funct3, funct7)
  begin
    -- Default values
    jump         <= '0';
    jump_target  <= (others => '0');
    jump_select  <= '0';
    MemWrite     <= '0';
    MemRead      <= '0';
    MemToReg     <= '0';
    ALU_Op       <= "000";
    ALU_src1     <= '0';
    ALU_src2     <= "000";

    -- JUMP logic
    if valid_in = '1' and (opcode = OPCODE_JAL or opcode = OPCODE_JALR) then
      jump         <= '1';
      jump_target  <= std_logic_vector(signed(PC_in) + signed(imm_J));
      jump_select  <= '1';  -- This instruction is responsible for the jump
    end if;

    -- ALU Control logic
    if opcode = OPCODE_R then
      case funct3 is
        when "000" =>
          if funct7 = F7_SUB then
            ALU_Op <= "001"; -- SUB
          else
            ALU_Op <= "000"; -- ADD
          end if;
        when "111" => ALU_Op <= "010"; -- AND
        when "110" => ALU_Op <= "011"; -- OR
        when "100" => ALU_Op <= "100"; -- XOR
        when "010" => ALU_Op <= "101"; -- SLT
        when others => ALU_Op <= "000";
      end case;

    elsif opcode = OPCODE_I then
      case funct3 is
        when "000" => ALU_Op <= "000"; -- ADDI
        when "111" => ALU_Op <= "010"; -- ANDI
        when "110" => ALU_Op <= "011"; -- ORI
        when "100" => ALU_Op <= "100"; -- XORI
        when "010" => ALU_Op <= "101"; -- SLTI
        when others => ALU_Op <= "000";
      end case;

    elsif opcode = OPCODE_BRANCH then
      case funct3 is
        when "000" => ALU_Op <= "001"; -- BEQ → SUB
        when "001" => ALU_Op <= "001"; -- BNE → SUB
        when "100" => ALU_Op <= "101"; -- BLT → SLT
        when "101" => ALU_Op <= "101"; -- BGE → SLT
        when others => ALU_Op <= "000";
      end case;
    end if;

    -- ALU src2 selection
    case opcode is
      when OPCODE_R       => ALU_src2 <= "000"; -- rs2
      when OPCODE_I       => ALU_src2 <= "001"; -- imm_I
      when OPCODE_LOAD    => ALU_src2 <= "001"; -- imm_I
      when OPCODE_STORE   => ALU_src2 <= "010"; -- imm_S
      when OPCODE_BRANCH  => ALU_src2 <= "011"; -- imm_B
      when OPCODE_LUI     => ALU_src2 <= "100"; -- imm_U
      when OPCODE_AUIPC   => ALU_src2 <= "100"; -- imm_U
      when OPCODE_JAL     => ALU_src2 <= "101"; -- imm_J
      when OPCODE_JALR    => ALU_src2 <= "001"; -- imm_I
      when others         => ALU_src2 <= "000";
    end case;

    -- ALU src1 selection
    case opcode is
      when OPCODE_R | OPCODE_I | OPCODE_LOAD | OPCODE_STORE | OPCODE_JALR =>
        ALU_src1 <= '0'; -- rs1
      when OPCODE_BRANCH | OPCODE_JAL | OPCODE_AUIPC =>
        ALU_src1 <= '1'; -- PC
      when OPCODE_LUI =>
        ALU_src1 <= '0'; -- doesn't matter; immediate directly used
      when others =>
        ALU_src1 <= '0';
    end case;

    -- Memory access control
    if opcode = OPCODE_LOAD then
      MemRead  <= '1';
      MemToReg <= '1'; -- Load result comes from memory
    elsif opcode = OPCODE_STORE then
      MemWrite <= '1';
    end if;

  end process;
end Behavioral;
