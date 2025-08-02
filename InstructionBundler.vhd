library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.InstructionTypes.all;

entity InstructionBundler is
  port (
    valid_in      : in  std_logic;
    instr         : in  std_logic_vector(31 downto 0);
    pc            : in  std_logic_vector(31 downto 0);

    -- From Decoder and Control Unit
    opcode        : in  std_logic_vector(6 downto 0);
    funct3        : in  std_logic_vector(2 downto 0);
    funct7        : in  std_logic_vector(6 downto 0);
    rs1           : in  std_logic_vector(4 downto 0);
    rs2           : in  std_logic_vector(4 downto 0);
    rd            : in  std_logic_vector(4 downto 0);
    imm_I 			: in  std_logic_vector(31 downto 0);
    imm_S 			: in  std_logic_vector(31 downto 0);
    imm_B 			: in  std_logic_vector(31 downto 0);
    imm_U 			: in  std_logic_vector(31 downto 0);
    imm_J 			: in  std_logic_vector(31 downto 0);


    alu_op        : in  std_logic_vector(2 downto 0);
    alu_src1      : in  std_logic;
    alu_src2      : in  std_logic_vector(2 downto 0);

    mem_read      : in  std_logic;
    mem_write     : in  std_logic;
    mem_to_reg    : in  std_logic;

    jump          : in  std_logic;
    jump_target   : in  std_logic_vector(31 downto 0);
    jump_select   : in  std_logic;

    -- Output bundled instruction
    pc_out        : out std_logic_vector(31 downto 0);
    bundle_out    : out InstructionBundle
  );
end InstructionBundler;

architecture Combinational of InstructionBundler is
begin
  -- Combinational assignments to InstructionBundle record
  bundle_out.instr        <= instr;
  bundle_out.pc           <= pc;
  bundle_out.opcode       <= opcode;
  bundle_out.funct3       <= funct3;
  bundle_out.funct7       <= funct7;
  bundle_out.rs1          <= rs1;
  bundle_out.rs2          <= rs2;
  bundle_out.rd           <= rd;
  bundle_out.imm_I 		  <= imm_I;
  bundle_out.imm_S 		  <= imm_S;
  bundle_out.imm_B 	     <= imm_B;
  bundle_out.imm_U 		  <= imm_U;
  bundle_out.imm_J 		  <= imm_J;
  bundle_out.alu_op       <= alu_op;
  bundle_out.alu_src1     <= alu_src1;
  bundle_out.alu_src2     <= alu_src2;
  bundle_out.mem_read     <= mem_read;
  bundle_out.mem_write    <= mem_write;
  bundle_out.mem_to_reg   <= mem_to_reg;
  bundle_out.jump         <= jump;
  bundle_out.jump_target  <= jump_target;
  bundle_out.jump_select  <= jump_select;
  bundle_out.valid         <= valid_in;

  pc_out <= pc; -- Forward PC if needed separately

end Combinational;



















