library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package InstructionTypes is

  type InstructionBundle is record
    instr          : std_logic_vector(31 downto 0);  -- Raw instruction
    pc             : std_logic_vector(31 downto 0);
    opcode         : std_logic_vector(6 downto 0);
    funct3         : std_logic_vector(2 downto 0);
    funct7         : std_logic_vector(6 downto 0);
    rs1            : std_logic_vector(4 downto 0);
    rs2            : std_logic_vector(4 downto 0);
    rd             : std_logic_vector(4 downto 0);
    imm_I : std_logic_vector(31 downto 0);
    imm_S : std_logic_vector(31 downto 0);
    imm_B : std_logic_vector(31 downto 0);
    imm_U : std_logic_vector(31 downto 0);
    imm_J : std_logic_vector(31 downto 0);
    alu_op         : std_logic_vector(2 downto 0);   -- ALU control signal
    alu_src1       : std_logic;
    alu_src2       : std_logic_vector(2 downto 0);
    mem_read       : std_logic;
    mem_write      : std_logic;
    mem_to_reg     : std_logic;
    jump           : std_logic;
    jump_target    : std_logic_vector(31 downto 0);
    jump_select    : std_logic;
    reg_write      : std_logic;
    valid          : std_logic;
  end record;

end package;
