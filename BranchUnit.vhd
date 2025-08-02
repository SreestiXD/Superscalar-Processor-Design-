library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BranchUnit is
  port (
    funct3      : in  std_logic_vector(2 downto 0);
    Zero        : in  std_logic;    -- '1' if rs1 – rs2 = 0
    Sign        : in  std_logic;    -- MSB of (rs1 – rs2), '1' if rs1 < rs2 (signed)
    ULT         : in  std_logic;    -- '1' if unsigned rs1 < rs2
    BranchTaken : out std_logic
  );
end entity BranchUnit;

architecture Comb of BranchUnit is
begin
  -- Decode branch subtype and pick the right comparison
  with funct3 select
    BranchTaken <=
      Zero           when "000",  -- BEQ  : take if equal
      not Zero       when "001",  -- BNE  : take if not equal
      Sign           when "100",  -- BLT  : take if signed less than
      not Sign       when "101",  -- BGE  : take if signed ≥
      ULT            when "110",  -- BLTU : take if unsigned less than
      not ULT        when "111",  -- BGEU : take if unsigned ≥
      '0'            when others; -- default: no branch
end architecture Comb;
