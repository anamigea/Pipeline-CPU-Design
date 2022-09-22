----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/01/2022 03:01:52 PM
-- Design Name: 
-- Module Name: register_file - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register_file is
    port (
        clk : in std_logic;
        ra1 : in std_logic_vector (2 downto 0);
        ra2 : in std_logic_vector (2 downto 0);
        wa : in std_logic_vector (2 downto 0);
        wd : in std_logic_vector (15 downto 0);
        RegWrite : in std_logic;
        rd1 : out std_logic_vector (15 downto 0);
        rd2 : out std_logic_vector (15 downto 0)
);
end register_file;

architecture Behavioral of register_file is

    type reg_array is array (0 to 15) of std_logic_vector(15 downto 0);
    signal reg_file : reg_array :=(x"0001", x"0002", x"0003", x"0004", x"0005", x"0006", x"0007", x"0008", x"0009", others => x"0000");
begin

    process(clk)
    begin
        if falling_edge(clk) then
            if RegWrite = '1' then
                reg_file(conv_integer(wa)) <= wd;
            end if;
        end if;
    end process;
    
    rd1 <= reg_file(conv_integer(ra1));
    rd2 <= reg_file(conv_integer(ra2));
    
end Behavioral;