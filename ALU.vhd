library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ALU operation codes
-- 0000: ADD    0001: SUB    0010: SLL   0011: SLT
-- 0100: SLTU   0101: XOR    0110: SRL   0111: SRA
-- 1000: OR     1001: AND

entity ALU is
  port(
    ALU1   : in  std_logic_vector(31 downto 0);
    ALU2   : in  std_logic_vector(31 downto 0);
    ALUop  : in  std_logic_vector(3 downto 0);
    Result : out std_logic_vector(31 downto 0);
    Zero   : out std_logic
  );
end entity;

architecture Behavioral of ALU is
  signal A, B : signed(31 downto 0);
  signal U1, U2 : unsigned(31 downto 0);
  signal tmp : signed(31 downto 0);
begin
  A  <= signed(ALU1);
  B  <= signed(ALU2);
  U1 <= unsigned(ALU1);
  U2 <= unsigned(ALU2);

  process(A, B, U1, U2, ALUop) is
  begin
    case ALUop is
      when "0000" =>  -- ADD
        tmp <= A + B;
      when "0001" =>  -- SUB
        tmp <= A - B;
      when "0010" =>  -- SLL (logical left)
        tmp <= signed( shift_left(U1, to_integer(U2(4 downto 0))) );
      when "0011" =>  -- SLT (signed less than)
        if A < B then
          tmp <= to_signed(1, 32);
        else
          tmp <= to_signed(0, 32);
        end if;
      when "0100" =>  -- SLTU (unsigned less than)
        if U1 < U2 then
          tmp <= to_signed(1, 32);
        else
          tmp <= to_signed(0, 32);
        end if;
      when "0101" =>  -- XOR
        tmp <= signed(ALU1 xor ALU2);
      when "0110" =>  -- SRL (logical right)
        tmp <= signed( shift_right(U1, to_integer(U2(4 downto 0))) );
      when "0111" =>  -- SRA (arithmetic right)
        tmp <= A / (2 ** to_integer(U2(4 downto 0)));
      when "1000" =>  -- OR
        tmp <= signed(ALU1 or ALU2);
      when "1001" =>  -- AND
        tmp <= signed(ALU1 and ALU2);
      when others =>
        tmp <= (others => '0');
    end case;

    Result <= std_logic_vector(tmp);
    if tmp = 0 then
		Zero <= '1';
	 else
		Zero <= '0';
  end if;
  end process;
end architecture;


















