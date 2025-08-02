library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.InstructionTypes.all;

entity MEM_WB_Register is
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;

    -- Inputs from MEM stage (after MemToReg MUX)
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
end entity;

architecture Behavioral of MEM_WB_Register is
  signal reg_bundle_0, reg_bundle_1 : InstructionBundle;
  signal reg_data_0, reg_data_1     : std_logic_vector(31 downto 0);
begin
  process(clk, reset)
  begin
    if reset = '1' then
      reg_bundle_0.valid <= '0';
      reg_bundle_1.valid <= '0';
      reg_data_0         <= (others => '0');
      reg_data_1         <= (others => '0');
    elsif rising_edge(clk) then
      reg_bundle_0 <= instr_in_0;
      reg_bundle_1 <= instr_in_1;
      reg_data_0   <= wb_data_in_0;
      reg_data_1   <= wb_data_in_1;
    end if;
  end process;

  -- Output assignment
  instr_out_0   <= reg_bundle_0;
  instr_out_1   <= reg_bundle_1;
  wb_data_out_0 <= reg_data_0;
  wb_data_out_1 <= reg_data_1;

end architecture;




































