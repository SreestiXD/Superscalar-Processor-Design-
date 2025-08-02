library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.InstructionTypes.ALL;  
entity FIFOqueue is
  generic (
    DEPTH_POW2 : integer := 4  -- => DEPTH = 16 entries
  );
  port (
    clk            : in  std_logic;
    rst            : in  std_logic;

    -- Two incoming instruction bundles
    bundle_in1     : in  InstructionBundle;
    bundle_in2     : in  InstructionBundle;

    -- Scheduler status
    scheduler_full : in  std_logic;
    one_empty      : in  std_logic;
    two_empty      : in  std_logic;

    -- Outputs to scheduler
    bundle_out1    : out InstructionBundle;
    valid_out1     : out std_logic;
    bundle_out2    : out InstructionBundle;
    valid_out2     : out std_logic;

    -- FIFO full signal for upstream stages 
    fifo_full      : out std_logic -- stall upstream stages if 1
  );
end FIFOqueue;

architecture Behavioral of FIFOqueue is
  constant DEPTH : integer := 2 ** DEPTH_POW2;

  -- FIFO memory
  type fifo_mem_t is array(0 to DEPTH - 1) of InstructionBundle;
  signal fifo_mem : fifo_mem_t;

  -- FIFO pointers and counter
  signal head_ptr : unsigned(DEPTH_POW2 - 1 downto 0) := (others => '0');
  signal tail_ptr : unsigned(DEPTH_POW2 - 1 downto 0) := (others => '0');
  signal count    : unsigned(DEPTH_POW2 downto 0)     := (others => '0');

begin

  -- FIFO full flag
  fifo_full <= '1' when count = to_unsigned(DEPTH, count'length) else '0';

  process(clk)
    variable push_cnt   : integer range 0 to 2;
    variable pop_cnt    : integer range 0 to 2;
    variable first_bund : InstructionBundle;
    variable second_bund: InstructionBundle;
    variable head_idx   : integer;
    variable tail_idx   : integer;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        head_ptr   <= (others => '0');
        tail_ptr   <= (others => '0');
        count      <= (others => '0');
        valid_out1 <= '0';
        valid_out2 <= '0';
      else
        ----------------------------
        -- 1) PACK & ORDER INPUTS --
        ----------------------------
        push_cnt := 0;
        if bundle_in1.valid = '1' then push_cnt := push_cnt + 1; end if;
        if bundle_in2.valid = '1' then push_cnt := push_cnt + 1; end if;

        if push_cnt = 2 then
          if unsigned(bundle_in1.pc) <= unsigned(bundle_in2.pc) then
            first_bund  := bundle_in1;
            second_bund := bundle_in2;
          else
            first_bund  := bundle_in2;
            second_bund := bundle_in1;
          end if;
        elsif push_cnt = 1 then
          if bundle_in1.valid = '1' then
            first_bund := bundle_in1;
          else
            first_bund := bundle_in2;
          end if;
        end if;

        -------------------------
        -- 2) ENQUEUE INTO FIFO
        -------------------------
        if (push_cnt > 0) and (count + push_cnt <= to_unsigned(DEPTH, count'length)) then
          tail_idx := to_integer(tail_ptr);
          fifo_mem(tail_idx) <= first_bund;
          if push_cnt = 2 then
            fifo_mem((tail_idx + 1) mod DEPTH) <= second_bund;
          end if;
          tail_ptr <= tail_ptr + to_unsigned(push_cnt, tail_ptr'length);
          count    <= count + to_unsigned(push_cnt, count'length);
        end if;

        --------------------------
        -- 3) DECIDE ISSUE COUNT
        --------------------------
        if scheduler_full = '1' then
          pop_cnt := 0;
        elsif two_empty = '1' then
          pop_cnt := 2;
        elsif one_empty = '1' then
          pop_cnt := 1;
        else
          pop_cnt := 0;
        end if;

        ------------------------------
        -- 4) DEQUEUE TO SCHEDULER --
        ------------------------------
        valid_out1 <= '0';
        valid_out2 <= '0';

        if (pop_cnt > 0) and (count > 0) then
          head_idx := to_integer(head_ptr);
          bundle_out1 <= fifo_mem(head_idx);
          valid_out1  <= '1';

          if (pop_cnt = 2) and (count > 1) then
            bundle_out2 <= fifo_mem((head_idx + 1) mod DEPTH);
            valid_out2  <= '1';
          end if;

          head_ptr <= head_ptr + to_unsigned(pop_cnt, head_ptr'length);
          count    <= count - to_unsigned(pop_cnt, count'length);
        end if;
      end if;
    end if;
  end process;

end Behavioral;
