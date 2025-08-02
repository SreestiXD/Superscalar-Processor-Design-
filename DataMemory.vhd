library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataMemory is
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
end entity;

architecture Behavioral of DataMemory is
  type memory_array is array (0 to 1023) of std_logic_vector(31 downto 0); -- 4KB = 1024 words
  signal memory : memory_array := (
    0 => (others => '0'),
    1 => (others => '0'),
    2 => (others => '0'),
    3 => (others => '0'),
    4 => (others => '0'),
    5 => x"DEADBEEF",
    others => (others => '0')
  );

  signal idx_0, idx_1 : integer range 0 to 1023;
begin

  idx_0 <= to_integer(unsigned(addr_0(31 downto 2)));
  idx_1 <= to_integer(unsigned(addr_1(31 downto 2)));

  -- Combinational read
  process(addr_0, MemRead_0, addr_1, MemRead_1)
  begin
    if MemRead_0 = '1' then
      Mem_Out_0 <= memory(idx_0);
    else
      Mem_Out_0 <= (others => '0');
    end if;

    if MemRead_1 = '1' and MemRead_0 = '0' and MemWrite_0 = '0' then
      Mem_Out_1 <= memory(idx_1);
    else
      Mem_Out_1 <= (others => '0');
    end if;
  end process;

  -- Synchronous write (only one at a time)
  process(clk)
  begin
    if rising_edge(clk) then
      if MemWrite_0 = '1' then
        memory(idx_0) <= write_data_0;
      elsif MemWrite_1 = '1' and MemRead_0 = '0' and MemWrite_0 = '0' then
        memory(idx_1) <= write_data_1;
      end if;
    end if;
  end process;

end architecture;



















