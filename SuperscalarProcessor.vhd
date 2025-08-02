library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.InstructionTypes.all;  -- For InstructionBundle

entity SuperscalarProcessor is
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;

    -- Final output from MEM/WB pipeline register (Issue 0)
    rd_0         : out std_logic_vector(4 downto 0);
    reg_write_0  : out std_logic;
    wb_data_0    : out std_logic_vector(31 downto 0);

    -- Final output from MEM/WB pipeline register (Issue 1)
    rd_1         : out std_logic_vector(4 downto 0);
    reg_write_1  : out std_logic;
    wb_data_1    : out std_logic_vector(31 downto 0)
  );
end entity SuperscalarProcessor;

architecture Structural of SuperscalarProcessor is

  -- === Instruction Fetch Signals ===
  signal PC              : std_logic_vector(31 downto 0);
  signal BranchTaken     : std_logic := '0';
  signal BranchTarget    : std_logic_vector(31 downto 0) := (others => '0');
  signal Jump            : std_logic := '0';
  signal Jump_Target     : std_logic_vector(31 downto 0) := (others => '0');
  signal Stall           : std_logic := '0';
  signal Flush           : std_logic := '0';

  signal Instr1          : std_logic_vector(31 downto 0);
  signal Instr2          : std_logic_vector(31 downto 0);
  signal PC_plus4        : std_logic_vector(31 downto 0);
  signal PC_plus8        : std_logic_vector(31 downto 0);
  signal Fetch_Valid     : std_logic;
  signal PC_out_IF       : std_logic_vector(31 downto 0);
  
    -- === IF/ID Pipeline Signals ===
  signal Instr1_ID, Instr2_ID     : std_logic_vector(31 downto 0);
  signal PC_ID, PC_plus4_ID       : std_logic_vector(31 downto 0);
  signal Fetch_Valid_ID           : std_logic;
  
    -- === ID Stage Signals for Issue 0 ===
  signal opcode_0, funct3_0     : std_logic_vector(6 downto 0);
  signal rd_0_s, rs1_0, rs2_0     : std_logic_vector(4 downto 0);
  signal funct7_0               : std_logic_vector(6 downto 0);
  signal imm_I_0, imm_S_0       : std_logic_vector(31 downto 0);
  signal imm_B_0, imm_U_0       : std_logic_vector(31 downto 0);
  signal imm_J_0                : std_logic_vector(31 downto 0);
  signal shamt_0                : std_logic_vector(4 downto 0);
  signal valid_0                : std_logic;
  signal PC_out_0               : std_logic_vector(31 downto 0);

  -- === ID Stage Signals for Issue 1 ===
  signal opcode_1, funct3_1     : std_logic_vector(6 downto 0);
  signal rd_1_s, rs1_1, rs2_1     : std_logic_vector(4 downto 0);
  signal funct7_1               : std_logic_vector(6 downto 0);
  signal imm_I_1, imm_S_1       : std_logic_vector(31 downto 0);
  signal imm_B_1, imm_U_1       : std_logic_vector(31 downto 0);
  signal imm_J_1                : std_logic_vector(31 downto 0);
  signal shamt_1                : std_logic_vector(4 downto 0);
  signal valid_1                : std_logic;
  signal PC_out_1               : std_logic_vector(31 downto 0);
  
  -- Control signals for instruction 0
	signal jump_0         : std_logic;
	signal jump_target_0  : std_logic_vector(31 downto 0);
	signal jump_select_0  : std_logic;
	signal ALU_Op_0       : std_logic_vector(2 downto 0);
	signal ALU_src1_0     : std_logic;
	signal ALU_src2_0     : std_logic_vector(2 downto 0);
	signal MemWrite_0     : std_logic;
	signal MemRead_0      : std_logic;
	signal MemToReg_0     : std_logic;

	-- Control signals for instruction 1
	signal jump_1         : std_logic;
	signal jump_target_1  : std_logic_vector(31 downto 0);
	signal jump_select_1  : std_logic;
	signal ALU_Op_1       : std_logic_vector(2 downto 0);
	signal ALU_src1_1     : std_logic;
	signal ALU_src2_1     : std_logic_vector(2 downto 0);
	signal MemWrite_1     : std_logic;
	signal MemRead_1      : std_logic;
	signal MemToReg_1     : std_logic;

	signal bundle_0, bundle_1 : InstructionBundle;

  -- Output of FIFO to scheduler
  signal fifo_bundle1, fifo_bundle2 : InstructionBundle;
  signal fifo_valid1, fifo_valid2   : std_logic;
  signal fifo_full_signal           : std_logic;

  -- Scheduler control signals (can be driven later)
  signal scheduler_full  : std_logic := '0';
  signal one_empty       : std_logic := '1'; -- assuming space for 1
  signal two_empty       : std_logic := '1'; -- assuming space for 2
  
  -- Scheduler outputs to EX stage
  signal sched_bundle1, sched_bundle2 : InstructionBundle;
  signal sched_valid1, sched_valid2   : std_logic;

  -- Scoreboard interface
  signal reg_avail         : std_logic_vector(31 downto 0) := (others => '1');
  signal scoreboard_mark   : std_logic_vector(31 downto 0);

  -- From WB stage (to clear bit in scoreboard)
  signal regwrite_valid_wb     : std_logic;
  signal regwrite_addr_wb      : unsigned(4 downto 0);
  
  -- Read values for instruction 0
  signal rs1_val_0, rs2_val_0 : std_logic_vector(31 downto 0);
  -- Read values for instruction 1
  signal rs1_val_1, rs2_val_1 : std_logic_vector(31 downto 0);

  -- Write-back control (from MEM/WB)
  signal wb_write_enable      : std_logic;
  signal wb_write_addr        : unsigned(4 downto 0);
  signal wb_write_data        : std_logic_vector(31 downto 0);

  -- ALU operand 1 after mux
  signal alu1_op_0, alu1_op_1 : std_logic_vector(31 downto 0);
  
  -- ALU operand 2 after mux
  signal alu2_op_0, alu2_op_1 : std_logic_vector(31 downto 0);
  
  signal alu_result_0, alu_result_1 : std_logic_vector(31 downto 0);
  signal alu_zero_0, alu_zero_1     : std_logic;
  
  signal exmem_bundle_0, exmem_bundle_1 : InstructionBundle;
  signal exmem_alu_0, exmem_alu_1       : std_logic_vector(31 downto 0);
    
  signal mem_data_out_0, mem_data_out_1 : std_logic_vector(31 downto 0);
  
  signal wb_data_0_s, wb_data_1_s : std_logic_vector(31 downto 0);
  
  signal memwb_bundle_0, memwb_bundle_1 : InstructionBundle;
  signal wb_data_out_0, wb_data_out_1   : std_logic_vector(31 downto 0);

  -- === IF Component Declaration ===
  component InstructionFetch is
    generic (
      MEM_DEPTH : integer := 32
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
  end component;
  
  component IF_ID_pipeline_reg is
    port (
      clk           : in  std_logic;
      Stall         : in  std_logic;
      Flush         : in  std_logic;
      Jump          : in  std_logic;
      Instr1_in     : in  std_logic_vector(31 downto 0);
      Instr2_in     : in  std_logic_vector(31 downto 0);
      PC_in         : in  std_logic_vector(31 downto 0);
      PC_plus4_in   : in  std_logic_vector(31 downto 0);
      Valid_in      : in  std_logic;
      Instr1_out    : out std_logic_vector(31 downto 0);
      Instr2_out    : out std_logic_vector(31 downto 0);
      PC_out        : out std_logic_vector(31 downto 0);
      PC_plus4_out  : out std_logic_vector(31 downto 0);
      Valid_out     : out std_logic
    );
  end component;
  
  component InstructionDecoder is
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

      imm_I       : out std_logic_vector(31 downto 0);
      imm_S       : out std_logic_vector(31 downto 0);
      imm_B       : out std_logic_vector(31 downto 0);
      imm_U       : out std_logic_vector(31 downto 0);
      imm_J       : out std_logic_vector(31 downto 0);
      shamt       : out std_logic_vector(4 downto 0)
    );
  end component;

  component ControlUnit is
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
  end component;
  
    component InstructionBundler is
    port (
      valid_in      : in  std_logic;
      instr         : in  std_logic_vector(31 downto 0);
      pc            : in  std_logic_vector(31 downto 0);

      opcode        : in  std_logic_vector(6 downto 0);
      funct3        : in  std_logic_vector(2 downto 0);
      funct7        : in  std_logic_vector(6 downto 0);
      rs1           : in  std_logic_vector(4 downto 0);
      rs2           : in  std_logic_vector(4 downto 0);
      rd            : in  std_logic_vector(4 downto 0);
      imm           : in  std_logic_vector(31 downto 0);

      alu_op        : in  std_logic_vector(2 downto 0);
      alu_src1      : in  std_logic;
      alu_src2      : in  std_logic_vector(2 downto 0);

      mem_read      : in  std_logic;
      mem_write     : in  std_logic;
      mem_to_reg    : in  std_logic;

      jump          : in  std_logic;
      jump_target   : in  std_logic_vector(31 downto 0);
      jump_select   : in  std_logic;

      pc_out        : out std_logic_vector(31 downto 0);
      bundle_out    : out InstructionBundle
    );
  end component;
  
  component FIFOqueue is
    generic (
      DEPTH_POW2 : integer := 4  -- => 2⁴ = 16 entries
    );
    port (
      clk            : in  std_logic;
      rst            : in  std_logic;

      bundle_in1     : in  InstructionBundle;
      bundle_in2     : in  InstructionBundle;

      scheduler_full : in  std_logic;
      one_empty      : in  std_logic;
      two_empty      : in  std_logic;

      bundle_out1    : out InstructionBundle;
      valid_out1     : out std_logic;
      bundle_out2    : out InstructionBundle;
      valid_out2     : out std_logic;

      fifo_full      : out std_logic
    );
  end component;
  
  component Schedular is
    generic (
      NUM_REGS : integer := 32
    );
    port (
      clk             : in  std_logic;
      rst             : in  std_logic;

      bundle_out1     : in  InstructionBundle;
      valid_out1      : in  std_logic;
      bundle_out2     : in  InstructionBundle;
      valid_out2      : in  std_logic;

      RegAvail        : in  std_logic_vector(NUM_REGS-1 downto 0);
      Scoreboard_Mark : out std_logic_vector(NUM_REGS-1 downto 0);

      Schedular_Full  : out std_logic;
      One_Empty       : out std_logic;
      Two_Empty       : out std_logic;

      Flush           : in  std_logic;

      Issue_Instr1    : out InstructionBundle;
      Issue_Valid1    : out std_logic;
      Issue_Instr2    : out InstructionBundle;
      Issue_Valid2    : out std_logic
    );
  end component;
  
  component Scoreboard is
    generic (
      NUM_REGS : integer := 32
    );
    port (
      clk                 : in  std_logic;
      rst                 : in  std_logic;

      Scoreboard_Mark     : in  std_logic_vector(NUM_REGS-1 downto 0);
      RegWriteback_Valid  : in  std_logic;
      RegWriteback_Addr   : in  unsigned(4 downto 0);

      RegAvail            : out std_logic_vector(NUM_REGS-1 downto 0)
    );
  end component;
  
  component RegisterFile is
    generic (
      REG_COUNT : integer := 32;
      REG_WIDTH : integer := 32
    );
    port (
      clk          : in  std_logic;
      rst          : in  std_logic;

      -- Read ports
      rs1_addr_1   : in  unsigned(4 downto 0);
      rs2_addr_1   : in  unsigned(4 downto 0);
      rs1_data_1   : out std_logic_vector(REG_WIDTH-1 downto 0);
      rs2_data_1   : out std_logic_vector(REG_WIDTH-1 downto 0);

      rs1_addr_2   : in  unsigned(4 downto 0);
      rs2_addr_2   : in  unsigned(4 downto 0);
      rs1_data_2   : out std_logic_vector(REG_WIDTH-1 downto 0);
      rs2_data_2   : out std_logic_vector(REG_WIDTH-1 downto 0);

      -- Write port (from WB stage)
      write_enable : in  std_logic;
      write_addr   : in  unsigned(4 downto 0);
      write_data   : in  std_logic_vector(REG_WIDTH-1 downto 0)
    );
  end component;

  component Mux2x1_32bit is
    port (
      A     : in  std_logic_vector(31 downto 0);
      B     : in  std_logic_vector(31 downto 0);
      Sel   : in  std_logic;
      OutY  : out std_logic_vector(31 downto 0)
    );
  end component;

  component Mux6x1_32bit is
    port (
      input0 : in  std_logic_vector(31 downto 0); -- rs2_value
      input1 : in  std_logic_vector(31 downto 0); -- imm_I
      input2 : in  std_logic_vector(31 downto 0); -- imm_S
      input3 : in  std_logic_vector(31 downto 0); -- imm_B
      input4 : in  std_logic_vector(31 downto 0); -- imm_U
      input5 : in  std_logic_vector(31 downto 0); -- imm_J
      sel    : in  std_logic_vector(2 downto 0);  -- selector
      output : out std_logic_vector(31 downto 0)
    );
  end component;
  
  component ALU is
    port(
      ALU1   : in  std_logic_vector(31 downto 0);
      ALU2   : in  std_logic_vector(31 downto 0);
      ALUop  : in  std_logic_vector(3 downto 0);
      Result : out std_logic_vector(31 downto 0);
      Zero   : out std_logic
    );
  end component;

  component EX_MEM_Register is
    port (
      clk         : in  std_logic;
      reset       : in  std_logic;

      -- Input bundles from Execute stage
      instr_in_0   : in  InstructionBundle;
      instr_in_1   : in  InstructionBundle;

      -- ALU results
      ALU_out_0    : in  std_logic_vector(31 downto 0);
      ALU_out_1    : in  std_logic_vector(31 downto 0);

      -- Output bundles to MEM stage
      instr_out_0  : out InstructionBundle;
      instr_out_1  : out InstructionBundle;

      -- Forwarded ALU outputs
      ALU_fwd_0    : out std_logic_vector(31 downto 0);
      ALU_fwd_1    : out std_logic_vector(31 downto 0)
    );
  end component;
  
  component DataMemory is
    port (
      clk            : in  std_logic;
      reset          : in  std_logic;

      -- Instruction 0
      addr_0         : in  std_logic_vector(31 downto 0);
      write_data_0   : in  std_logic_vector(31 downto 0);
      MemRead_0      : in  std_logic;
      MemWrite_0     : in  std_logic;
      Mem_Out_0      : out std_logic_vector(31 downto 0);

      -- Instruction 1
      addr_1         : in  std_logic_vector(31 downto 0);
      write_data_1   : in  std_logic_vector(31 downto 0);
      MemRead_1      : in  std_logic;
      MemWrite_1     : in  std_logic;
      Mem_Out_1      : out std_logic_vector(31 downto 0)
    );
  end component;
  
  component MEM_WB_Register is
    port (
      clk            : in  std_logic;
      reset          : in  std_logic;

      -- Inputs from MEM stage
      instr_in_0     : in  InstructionBundle;
      instr_in_1     : in  InstructionBundle;
      wb_data_in_0   : in  std_logic_vector(31 downto 0);
      wb_data_in_1   : in  std_logic_vector(31 downto 0);

      -- Outputs to WB stage
      instr_out_0    : out InstructionBundle;
      instr_out_1    : out InstructionBundle;
      wb_data_out_0  : out std_logic_vector(31 downto 0);
      wb_data_out_1  : out std_logic_vector(31 downto 0)
    );
  end component;

	component WriteBackMux is
	  port (
		 instr0_valid    : in  std_logic;
		 instr0_regwrite : in  std_logic;
		 instr0_rd       : in  std_logic_vector(4 downto 0);
		 instr0_data     : in  std_logic_vector(31 downto 0);

		 instr1_valid    : in  std_logic;
		 instr1_regwrite : in  std_logic;
		 instr1_rd       : in  std_logic_vector(4 downto 0);
		 instr1_data     : in  std_logic_vector(31 downto 0);

		 write_enable    : out std_logic;
		 write_addr      : out std_logic_vector(4 downto 0);
		 write_data      : out std_logic_vector(31 downto 0)
	  );
	end component;
begin

	-- Instruction 0 final write-back values
	rd_0        <= memwb_bundle_0.rd;
	reg_write_0 <= memwb_bundle_0.reg_write;
	wb_data_0   <= wb_data_out_0;

	-- Instruction 1 final write-back values
	rd_1        <= memwb_bundle_1.rd;
	reg_write_1 <= memwb_bundle_1.reg_write;
	wb_data_1   <= wb_data_out_1;

  -- === Instruction Fetch Instantiation ===
  Fetch_Stage : InstructionFetch
    generic map (
      MEM_DEPTH => 32
    )
    port map (
      clk          => clk,
      PC           => PC,
      BranchTaken  => BranchTaken,
      BranchTarget => BranchTarget,
      Stall        => Stall,
      Flush        => Flush,
      Jump         => Jump,
      Jump_Target  => Jump_Target,
      Instr1       => Instr1,
      Instr2       => Instr2,
      PC_plus4     => PC_plus4,
      PC_plus8     => PC_plus8,
      Fetch_Valid  => Fetch_Valid,
      PC_out       => PC_out_IF
    );

  -- PC initialization
  PC <= PC_out_IF;
  
    IF_ID_Reg : IF_ID_pipeline_reg
    port map (
      clk           => clk,
      Stall         => Stall,
      Flush         => Flush,
      Jump          => Jump,
      Instr1_in     => Instr1,
      Instr2_in     => Instr2,
      PC_in         => PC_out_IF,
      PC_plus4_in   => PC_plus4,
      Valid_in      => Fetch_Valid,
      Instr1_out    => Instr1_ID,
      Instr2_out    => Instr2_ID,
      PC_out        => PC_ID,
      PC_plus4_out  => PC_plus4_ID,
      Valid_out     => Fetch_Valid_ID
    );

	  -- === Instruction Decoder for Issue 0 ===
  Decoder0 : InstructionDecoder
    port map (
      instruction => Instr1_ID,
      PC_in       => PC_ID,
      valid_in    => Fetch_Valid_ID,

      opcode      => opcode_0,
      rd          => rd_0_s,
      funct3      => funct3_0,
      rs1         => rs1_0,
      rs2         => rs2_0,
      funct7      => funct7_0,
      PC_out      => PC_out_0,
      valid_out   => valid_0,

      imm_I       => imm_I_0,
      imm_S       => imm_S_0,
      imm_B       => imm_B_0,
      imm_U       => imm_U_0,
      imm_J       => imm_J_0,
      shamt       => shamt_0
    );

  -- === Instruction Decoder for Issue 1 ===
  Decoder1 : InstructionDecoder
    port map (
      instruction => Instr2_ID,
      PC_in       => PC_plus4_ID,
      valid_in    => Fetch_Valid_ID,

      opcode      => opcode_1,
      rd          => rd_1_s,
      funct3      => funct3_1,
      rs1         => rs1_1,
      rs2         => rs2_1,
      funct7      => funct7_1,
      PC_out      => PC_out_1,
      valid_out   => valid_1,

      imm_I       => imm_I_1,
      imm_S       => imm_S_1,
      imm_B       => imm_B_1,
      imm_U       => imm_U_1,
      imm_J       => imm_J_1,
      shamt       => shamt_1
    );
	 
	 -- Control Unit for Issue 0
	CU0 : ControlUnit
	  port map (
		 opcode       => opcode_0,
		 imm_J        => imm_J_0,
		 PC_in        => PC_out_0,
		 funct3       => funct3_0(2 downto 0),
		 funct7       => funct7_0,
		 valid_in     => valid_0,

		 jump         => jump_0,
		 jump_target  => jump_target_0,
		 jump_select  => jump_select_0,
		 ALU_Op       => ALU_Op_0,
		 ALU_src1     => ALU_src1_0,
		 ALU_src2     => ALU_src2_0,
		 MemWrite     => MemWrite_0,
		 MemRead      => MemRead_0,
		 MemToReg     => MemToReg_0
	  );

	-- Control Unit for Issue 1
	CU1 : ControlUnit
	  port map (
		 opcode       => opcode_1,
		 imm_J        => imm_J_1,
		 PC_in        => PC_out_1,
		 funct3       => funct3_1(2 downto 0),
		 funct7       => funct7_1,
		 valid_in     => valid_1,

		 jump         => jump_1,
		 jump_target  => jump_target_1,
		 jump_select  => jump_select_1,
		 ALU_Op       => ALU_Op_1,
		 ALU_src1     => ALU_src1_1,
		 ALU_src2     => ALU_src2_1,
		 MemWrite     => MemWrite_1,
		 MemRead      => MemRead_1,
		 MemToReg     => MemToReg_1
	  );

  -- === Instruction Bundler for Issue 0 ===
  Bundler0 : InstructionBundler
    port map (
      valid_in     => valid_0,
      instr        => Instr1_ID,
      pc           => PC_out_0,

      opcode       => opcode_0,
      funct3       => funct3_0,
      funct7       => funct7_0,
      rs1          => rs1_0,
      rs2          => rs2_0,
      rd           => rd_0_s,
      imm          => imm_I_0,  -- unified imm for simplicity

      alu_op       => ALU_Op_0,
      alu_src1     => ALU_src1_0,
      alu_src2     => ALU_src2_0,

      mem_read     => MemRead_0,
      mem_write    => MemWrite_0,
      mem_to_reg   => MemToReg_0,

      jump         => jump_0,
      jump_target  => jump_target_0,
      jump_select  => jump_select_0,

      pc_out       => open,         -- used only if needed
      bundle_out   => bundle_0
    );

  -- === Instruction Bundler for Issue 1 ===
  Bundler1 : InstructionBundler
    port map (
      valid_in     => valid_1,
      instr        => Instr2_ID,
      pc           => PC_out_1,

      opcode       => opcode_1,
      funct3       => funct3_1,
      funct7       => funct7_1,
      rs1          => rs1_1,
      rs2          => rs2_1,
      rd           => rd_1_s,
      imm          => imm_I_1,

      alu_op       => ALU_Op_1,
      alu_src1     => ALU_src1_1,
      alu_src2     => ALU_src2_1,

      mem_read     => MemRead_1,
      mem_write    => MemWrite_1,
      mem_to_reg   => MemToReg_1,

      jump         => jump_1,
      jump_target  => jump_target_1,
      jump_select  => jump_select_1,

      pc_out       => open,
      bundle_out   => bundle_1
    );
	 
  InstructionFIFO : FIFOqueue
    generic map (
      DEPTH_POW2 => 4  -- 16-entry FIFO
    )
    port map (
      clk            => clk,
      rst            => reset,

      bundle_in1     => bundle_0,
      bundle_in2     => bundle_1,

      scheduler_full => scheduler_full,
      one_empty      => one_empty,
      two_empty      => two_empty,

      bundle_out1    => fifo_bundle1,
      valid_out1     => fifo_valid1,
      bundle_out2    => fifo_bundle2,
      valid_out2     => fifo_valid2,

      fifo_full      => fifo_full_signal
    );
	 
  Scheduler_Unit : Schedular
    generic map (
      NUM_REGS => 32
    )
    port map (
      clk             => clk,
      rst             => reset,

      bundle_out1     => fifo_bundle1,
      valid_out1      => fifo_valid1,
      bundle_out2     => fifo_bundle2,
      valid_out2      => fifo_valid2,

      RegAvail        => reg_avail,
      Scoreboard_Mark => scoreboard_mark,

      Schedular_Full  => scheduler_full,
      One_Empty       => one_empty,
      Two_Empty       => two_empty,

      Flush           => Flush,

      Issue_Instr1    => sched_bundle1,
      Issue_Valid1    => sched_valid1,
      Issue_Instr2    => sched_bundle2,
      Issue_Valid2    => sched_valid2
    );
	 
  Scoreboard_Unit : Scoreboard
    generic map (
      NUM_REGS => 32
    )
    port map (
      clk                => clk,
      rst                => reset,

      Scoreboard_Mark    => scoreboard_mark,
      RegWriteback_Valid => regwrite_valid_wb,
      RegWriteback_Addr  => regwrite_addr_wb,

      RegAvail           => reg_avail
    );

  RegFile : RegisterFile
    generic map (
      REG_COUNT => 32,
      REG_WIDTH => 32
    )
    port map (
      clk          => clk,
      rst          => reset,

      rs1_addr_1   => unsigned(rs1_0),
      rs2_addr_1   => unsigned(rs2_0),
      rs1_data_1   => rs1_val_0,
      rs2_data_1   => rs2_val_0,

      rs1_addr_2   => unsigned(rs1_1),
      rs2_addr_2   => unsigned(rs2_1),
      rs1_data_2   => rs1_val_1,
      rs2_data_2   => rs2_val_1,

      write_enable => wb_write_enable,
      write_addr   => wb_write_addr,
      write_data   => wb_write_data
    );
	 
  ALU1Mux_0 : Mux2x1_32bit
    port map (
      A    => rs1_val_0,
      B    => sched_bundle1.pc,
      Sel  => sched_bundle1.alu_src1,
      OutY => alu1_op_0
    );

  ALU1Mux_1 : Mux2x1_32bit
    port map (
      A    => rs1_val_1,
      B    => sched_bundle2.pc,
      Sel  => sched_bundle2.alu_src1,
      OutY => alu1_op_1
    );

	ALU2Mux_0 : Mux6x1_32bit
	  port map (
		 input0 => rs2_val_0,
		 input1 => sched_bundle1.imm_I,
		 input2 => sched_bundle1.imm_S,
		 input3 => sched_bundle1.imm_B,
		 input4 => sched_bundle1.imm_U,
		 input5 => sched_bundle1.imm_J,
		 sel    => sched_bundle1.alu_src2,
		 output => alu2_op_0
	);

	ALU2Mux_1 : Mux6x1_32bit
	  port map (
		 input0 => rs2_val_1,
		 input1 => sched_bundle2.imm_I,
		 input2 => sched_bundle2.imm_S,
		 input3 => sched_bundle2.imm_B,
		 input4 => sched_bundle2.imm_U,
		 input5 => sched_bundle2.imm_J,
		 sel    => sched_bundle2.alu_src2,
		 output => alu2_op_1
	);
	
  ALU_0 : ALU
    port map (
      ALU1   => alu1_op_0,
      ALU2   => alu2_op_0,
      ALUop  => sched_bundle1.alu_op,
      Result => alu_result_0,
      Zero   => alu_zero_0
    );

  ALU_1 : ALU
    port map (
      ALU1   => alu1_op_1,
      ALU2   => alu2_op_1,
      ALUop  => sched_bundle2.alu_op,
      Result => alu_result_1,
      Zero   => alu_zero_1
    );

  EX_MEM_Stage : EX_MEM_Register
    port map (
      clk         => clk,
      reset       => reset,

      instr_in_0  => sched_bundle1,
      instr_in_1  => sched_bundle2,

      ALU_out_0   => alu_result_0,
      ALU_out_1   => alu_result_1,

      instr_out_0 => exmem_bundle_0,
      instr_out_1 => exmem_bundle_1,

      ALU_fwd_0   => exmem_alu_0,
      ALU_fwd_1   => exmem_alu_1
    );

  SharedDMEM : DataMemory
    port map (
      clk           => clk,
      reset         => reset,

      -- Instruction 0
      addr_0        => exmem_alu_0,
      write_data_0  => rs2_val_0,
      MemRead_0     => exmem_bundle_0.mem_read,
      MemWrite_0    => exmem_bundle_0.mem_write,
      Mem_Out_0     => mem_data_out_0,

      -- Instruction 1
      addr_1        => exmem_alu_1,
      write_data_1  => rs2_val_1,
      MemRead_1     => exmem_bundle_1.mem_read,
      MemWrite_1    => exmem_bundle_1.mem_write,
      Mem_Out_1     => mem_data_out_1
    );
	 
  WB_MUX_0 : Mux2x1_32bit
    port map (
      A    => exmem_alu_0,             -- ALU result
      B    => mem_data_out_0,          -- DMEM result
      Sel  => exmem_bundle_0.mem_to_reg,
      OutY => wb_data_0_s
    );

  WB_MUX_1 : Mux2x1_32bit
    port map (
      A    => exmem_alu_1,
      B    => mem_data_out_1,
      Sel  => exmem_bundle_1.mem_to_reg,
      OutY => wb_data_1_s
    );

  MEMWB_Reg : MEM_WB_Register
    port map (
      clk            => clk,
      reset          => reset,

      instr_in_0     => exmem_bundle_0,
      instr_in_1     => exmem_bundle_1,
      wb_data_in_0   => wb_data_0_s,
      wb_data_in_1   => wb_data_1_s,

      instr_out_0    => memwb_bundle_0,
      instr_out_1    => memwb_bundle_1,
      wb_data_out_0  => wb_data_out_0,
      wb_data_out_1  => wb_data_out_1
    );

	WriteBackSelect : WriteBackMux
	  port map (
		 instr0_valid    => memwb_bundle_0.valid,
		 instr0_regwrite => memwb_bundle_0.reg_write,
		 instr0_rd       => memwb_bundle_0.rd,
		 instr0_data     => wb_data_out_0,

		 instr1_valid    => memwb_bundle_1.valid,
		 instr1_regwrite => memwb_bundle_1.reg_write,
		 instr1_rd       => memwb_bundle_1.rd,
		 instr1_data     => wb_data_out_1,

		 write_enable    => wb_write_enable,
		 write_addr      => wb_write_addr,
		 write_data      => wb_write_data
	  );

end architecture;
	
					









































