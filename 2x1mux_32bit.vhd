library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux2x1_32bit is
  port (
    A     : in  std_logic_vector(31 downto 0);
    B     : in  std_logic_vector(31 downto 0);
    Sel   : in  std_logic;
    OutY  : out std_logic_vector(31 downto 0)
  );
end Mux2x1_32bit;
architecture Behavioral of Mux2x1_32bit is
begin
  OutY <= A when Sel = '0' else B;
end Behavioral;
