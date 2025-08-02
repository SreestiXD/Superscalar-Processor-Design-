library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.InstructionTypes.all;

entity EX_MEM_Register is
  port (
    clk       : in  std_logic;
    reset     : in  std_logic;

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
end entity;

architecture Behavioral of EX_MEM_Register is
  signal temp_bundle0, temp_bundle1 : InstructionBundle;
begin
  process(clk, reset)
  begin
    if reset = '1' then
      temp_bundle0.valid <= '0';
      temp_bundle1.valid <= '0';
      ALU_fwd_0 <= (others => '0');
      ALU_fwd_1 <= (others => '0');
    elsif rising_edge(clk) then
      temp_bundle0   <= instr_in_0;
      temp_bundle1   <= instr_in_1;
      ALU_fwd_0      <= ALU_out_0;
      ALU_fwd_1      <= ALU_out_1;
    end if;
  end process;

  -- Continuous outputs
  instr_out_0 <= temp_bundle0;
  instr_out_1 <= temp_bundle1;

end architecture;
