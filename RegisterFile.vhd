library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RegisterFile is
  generic (
    REG_COUNT : integer := 32;
    REG_WIDTH : integer := 32
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    -- Read ports (2 per instruction)
    rs1_addr_1  : in  unsigned(4 downto 0);
    rs2_addr_1  : in  unsigned(4 downto 0);
    rs1_data_1  : out std_logic_vector(REG_WIDTH-1 downto 0);
    rs2_data_1  : out std_logic_vector(REG_WIDTH-1 downto 0);

    rs1_addr_2  : in  unsigned(4 downto 0);
    rs2_addr_2  : in  unsigned(4 downto 0);
    rs1_data_2  : out std_logic_vector(REG_WIDTH-1 downto 0);
    rs2_data_2  : out std_logic_vector(REG_WIDTH-1 downto 0);

    -- Write port (from WB stage)
    write_enable : in  std_logic;
    write_addr   : in  unsigned(4 downto 0);
    write_data   : in  std_logic_vector(REG_WIDTH-1 downto 0)
  );
end RegisterFile;

architecture Behavioral of RegisterFile is
	type reg_array is array(0 to REG_COUNT - 1) of std_logic_vector(REG_WIDTH-1 downto 0);

	signal regs : reg_array := (
	  0  => "00000000000000000000000000000000",
	  1  => "00000000000000000000000000000000",
	  2  => "00000000000000000000000000000000",
	  3  => "00000000000000000000000000000000",
	  4  => "00000000000000000000000000000000",
	  5  => "00000000000000000000000000000000",
	  6  => "00000000000000000000000000000000",
	  7  => "00000000000000000000000000000000",
	  8  => "00000000000000000000000000000000",
	  9  => "00000000000000000000000000000000",
	  10 => "00000000000000000000000000000000",
	  11 => "00000000000000000000000000000000",
	  12 => "00000000000000000000000000000000",
	  13 => "00000000000000000000000000000000",
	  14 => "00000000000000000000000000000000",
	  15 => "00000000000000000000000000000000",
	  16 => "00000000000000000000000000000000",
	  17 => "00000000000000000000000000000000",
	  18 => "00000000000000000000000000000000",
	  19 => "00000000000000000000000000000000",
	  20 => "00000000000000000000000000000000",
	  21 => "00000000000000000000000000000000",
	  22 => "00000000000000000000000000000000",
	  23 => "00000000000000000000000000000000",
	  24 => "00000000000000000000000000000000",
	  25 => "00000000000000000000000000000000",
	  26 => "00000000000000000000000000000000",
	  27 => "00000000000000000000000000000000",
	  28 => "00000000000000000000000000000000",
	  29 => "00000000000000000000000000000000",
	  30 => "00000000000000000000000000000000",
	  31 => "00000000000000000000000000000000"
	);

begin

  -- Combinational read
  rs1_data_1 <= regs(to_integer(rs1_addr_1));
  rs2_data_1 <= regs(to_integer(rs2_addr_1));
  rs1_data_2 <= regs(to_integer(rs1_addr_2));
  rs2_data_2 <= regs(to_integer(rs2_addr_2));

  -- Synchronous write (on clock edge)
  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        regs <= (others => (others => '0'));
      elsif write_enable = '1' and write_addr /= "00000" then
        regs(to_integer(write_addr)) <= write_data;
      end if;
    end if;
  end process;

end Behavioral;


























