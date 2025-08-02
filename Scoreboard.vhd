library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Scoreboard is
  generic (
    NUM_REGS : integer := 32
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    -- From Scheduler (set bits to mark registers as busy)
    Scoreboard_Mark : in  std_logic_vector(NUM_REGS-1 downto 0);

    -- From Writeback (clear one register as available)
    RegWriteback_Valid : in  std_logic;
    RegWriteback_Addr  : in  unsigned(4 downto 0);  -- Address of destination register

    -- To Scheduler 
    RegAvail : out std_logic_vector(NUM_REGS-1 downto 0)
  );
end Scoreboard;

architecture Behavioral of Scoreboard is

  -- (1 = available, 0 = busy)
  signal reg_ready : std_logic_vector(NUM_REGS-1 downto 0);

begin

  RegAvail <= reg_ready;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        reg_ready <= (others => '1');  -- All registers available at reset

      else
        -- Mark registers as busy if set in Scoreboard_Mark
        for i in 0 to NUM_REGS - 1 loop
          if Scoreboard_Mark(i) = '1' then
            reg_ready(i) <= '0';
          end if;
        end loop;

        -- Release one register (on writeback)
        if RegWriteback_Valid = '1' then
          reg_ready(to_integer(RegWriteback_Addr)) <= '1';
        end if;

      end if;
    end if;
  end process;

end Behavioral;
