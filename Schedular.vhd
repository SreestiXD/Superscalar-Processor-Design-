library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.InstructionTypes.ALL;

entity Schedular is
  generic (
    NUM_REGS : integer := 32
  );
  port (
    clk             : in  std_logic;
    rst             : in  std_logic;

    -- From FIFO
    bundle_out1     : in  InstructionBundle;
    valid_out1      : in  std_logic;
    bundle_out2     : in  InstructionBundle;
    valid_out2      : in  std_logic;

    -- Scoreboard
    RegAvail        : in  std_logic_vector(NUM_REGS-1 downto 0);
    Scoreboard_Mark : out std_logic_vector(NUM_REGS-1 downto 0);

    -- Backpressure control
    Schedular_Full  : out std_logic;
    One_Empty       : out std_logic;
    Two_Empty       : out std_logic;

    -- Flush or misprediction
    Flush           : in  std_logic;

    -- Output to EX stage
    Issue_Instr1    : out InstructionBundle;
    Issue_Valid1    : out std_logic;
    Issue_Instr2    : out InstructionBundle;
    Issue_Valid2    : out std_logic
  );
end Schedular;

architecture Behavioral of Schedular is

  signal i1, i2     : InstructionBundle;
  signal v1, v2     : std_logic := '0';
  signal raw_stall_count : integer range 0 to 3 := 0;
  signal issue_valid1_internal, Issue_Valid2_internal: std_logic;

  -- Helper functions
  function uses_rs1(inst: InstructionBundle) return boolean is
  begin
    case inst.opcode is
      when "0110111" | "0010111" | "1101111" =>  -- LUI, AUIPC, JAL
        return false;
      when others =>
        return true;
    end case;
  end function;

  function uses_rs2(inst: InstructionBundle) return boolean is
  begin
    case inst.opcode is
      when "0110011" | "0100011" | "1100011" =>  -- R-type, S-type, B-type
        return true;
      when others =>
        return false;
    end case;
  end function;

begin

  process(clk)
    variable next_i1, next_i2 : InstructionBundle;
    variable next_v1, next_v2 : std_logic;
    variable deq_cnt          : integer range 0 to 2 := 0;
    variable next_mark        : std_logic_vector(NUM_REGS-1 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' or Flush = '1' then
        v1 <= '0';
        v2 <= '0';
        raw_stall_count <= 0;
        Issue_Valid1_internal <= '0';
        Issue_Valid2_internal <= '0';
        deq_cnt := 0;

      elsif raw_stall_count > 0 then
        raw_stall_count <= raw_stall_count - 1;
        if v1 = '1' then
          Issue_Instr1 <= i1;
          Issue_Valid1_internal <= '1';
          Issue_Valid2_internal <= '0';
          deq_cnt := 1;
        else
          Issue_Valid1_internal <= '0';
          Issue_Valid2_internal <= '0';
          deq_cnt := 0;
        end if;

      else
        -- Step 1: Fetch instructions
        if deq_cnt = 2 then
          if valid_out1 = '1' then
            next_i1 := bundle_out1;
            next_v1 := '1';
          else
            next_v1 := '0';
          end if;

          if valid_out2 = '1' then
            next_i2 := bundle_out2;
            next_v2 := '1';
          else
            next_v2 := '0';
          end if;

        elsif deq_cnt = 1 then
          next_i1 := i2;
          next_v1 := v2;

          if valid_out1 = '1' then
            next_i2 := bundle_out1;
            next_v2 := '1';
          else
            next_v2 := '0';
          end if;

        else
          next_i1 := i1;
          next_i2 := i2;
          next_v1 := v1;
          next_v2 := v2;
        end if;

        -- Step 2: Check i1 dependencies
        if next_v1 = '1' and (
             (uses_rs1(next_i1) and RegAvail(to_integer(unsigned(next_i1.rs1))) = '0') or
             (uses_rs2(next_i1) and RegAvail(to_integer(unsigned(next_i1.rs2))) = '0')
           ) then
          Issue_Valid1_internal <= '0';
          Issue_Valid2_internal <= '0';
          deq_cnt := 0;

        -- Step 3: Check i2
        elsif next_v2 = '1' and (
             (uses_rs1(next_i2) and RegAvail(to_integer(unsigned(next_i2.rs1))) = '0') or
             (uses_rs2(next_i2) and RegAvail(to_integer(unsigned(next_i2.rs2))) = '0')
           ) then
          Issue_Instr1 <= next_i1;
          Issue_Valid1_internal <= '1';
          Issue_Valid2_internal <= '0';
          deq_cnt := 1;

        elsif next_v2 = '1' and
              next_v1 = '1' and next_i1.reg_write = '1' and (
                (uses_rs1(next_i2) and next_i2.rs1 = next_i1.rd) or
                (uses_rs2(next_i2) and next_i2.rs2 = next_i1.rd)
              ) then
          Issue_Instr1 <= next_i1;
          Issue_Valid1_internal <= '1';
          Issue_Valid2_internal <= '0';
          raw_stall_count <= 3;
          deq_cnt := 1;

        -- Step 4: Safe to issue both
        else
          deq_cnt := 0;
          if next_v1 = '1' then
            Issue_Instr1 <= next_i1;
            Issue_Valid1_internal <= '1';
            deq_cnt := deq_cnt + 1;
          else
            Issue_Valid1_internal <= '0';
          end if;

          if next_v2 = '1' then
            Issue_Instr2 <= next_i2;
            Issue_Valid2_internal <= '1';
            deq_cnt := deq_cnt + 1;
          else
            Issue_Valid2_internal <= '0';
          end if;
        end if;

        -- Update latched instructions for next cycle
        if deq_cnt = 2 then
          if valid_out1 = '1' then i1 <= bundle_out1; v1 <= '1'; else v1 <= '0'; end if;
          if valid_out2 = '1' then i2 <= bundle_out2; v2 <= '1'; else v2 <= '0'; end if;
        elsif deq_cnt = 1 then
          i1 <= i2;
          v1 <= v2;
          if valid_out1 = '1' then i2 <= bundle_out1; v2 <= '1'; else v2 <= '0'; end if;
        end if;

      end if;

      -- Backpressure control
      if deq_cnt = 0 then
        Schedular_Full <= '1';
        One_Empty <= '0';
        Two_Empty <= '0';
      elsif deq_cnt = 1 then
        Schedular_Full <= '0';
        One_Empty <= '1';
        Two_Empty <= '0';
      elsif deq_cnt = 2 then
        Schedular_Full <= '0';
        One_Empty <= '0';
        Two_Empty <= '1';
      end if;

      -- Scoreboard marking
      next_mark := (others => '0');
      if Issue_Valid1_internal = '1' and next_i1.reg_write = '1' then
        next_mark(to_integer(unsigned(next_i1.rd))) := '1';
      end if;
      if Issue_Valid2_internal = '1' and next_i2.reg_write = '1' then
        next_mark(to_integer(unsigned(next_i2.rd))) := '1';
      end if;
      Scoreboard_Mark <= next_mark;
		Issue_Valid1 <= issue_valid1_internal;

    end if;
  end process;

end Behavioral;
