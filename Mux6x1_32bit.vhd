library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Mux6x1_32bit is
  port (
    input0 : in  std_logic_vector(31 downto 0); -- rs2_value
    input1 : in  std_logic_vector(31 downto 0); -- imm_I
    input2 : in  std_logic_vector(31 downto 0); -- imm_S
    input3 : in  std_logic_vector(31 downto 0); -- imm_B
    input4 : in  std_logic_vector(31 downto 0); -- imm_U
    input5 : in  std_logic_vector(31 downto 0); -- imm_J
    sel    : in  std_logic_vector(2 downto 0);  -- 3-bit select
    output : out std_logic_vector(31 downto 0)
  );
end entity;

architecture Behavioral of Mux6x1_32bit is
begin
  process(input0, input1, input2, input3, input4, input5, sel)
  begin
    case sel is
      when "000" =>
        output <= input0;
      when "001" =>
        output <= input1;
      when "010" =>
        output <= input2;
      when "011" =>
        output <= input3;
      when "100" =>
        output <= input4;
      when "101" =>
        output <= input5;
      when others =>
        output <= (others => '0'); -- default case
    end case;
  end process;
end architecture;
