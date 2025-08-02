library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity WriteBackMux is
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
end WriteBackMux;
architecture Behavioral of WriteBackMux is
begin
  process(instr0_valid, instr0_regwrite, instr0_rd, instr0_data,
          instr1_valid, instr1_regwrite, instr1_rd, instr1_data)
  begin
    if instr0_valid = '1' and instr0_regwrite = '1' then
      write_enable <= '1';
      write_addr   <= instr0_rd;
      write_data   <= instr0_data;
    elsif instr1_valid = '1' and instr1_regwrite = '1' then
      write_enable <= '1';
      write_addr   <= instr1_rd;
      write_data   <= instr1_data;
    else
      write_enable <= '0';
      write_addr   <= (others => '0');
      write_data   <= (others => '0');
    end if;
  end process;
end Behavioral;
