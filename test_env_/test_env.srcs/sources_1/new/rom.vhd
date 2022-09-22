
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rom is
    Port ( addr : in STD_LOGIC_VECTOR (15 downto 0);
           data : out STD_LOGIC_VECTOR (15 downto 0));
end rom;

architecture Behavioral of rom is

type ROM_type is array (0 to 255) of std_logic_vector (15 downto 0);
signal ROM :  ROM_type :=(
    B"000_001_010_011_0_000",  --RF[3] <- RF[1] + RF[2]     ;   add;    FPGA: X"0530"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_011_010_100_0_001",  --RF[4] <- RF[3] - RF[2]     ;   sub;    FPGA: X"0D41"
    B"000_011_100_101_1_010",  --RF[5] <- RF[3] << 1        ;   sll;    FPGA: X"0E5A"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_100_101_110_1_011",  --RF[6] <- RF[4] >> 1        ;   srl;    FPGA: X"12EB"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_101_110_111_0_100",  --RF[7] <- RF[5] & RF[6]     ;   and;    FPGA: X"1774"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_110_111_000_0_101",  --RF[0] <- RF[6] | RF[7]     ;   or;     FPGA: X"1B85"
    B"000_111_000_001_0_110",  --RF[1] <- RF[7] ^ RF[0]     ;   xor;    FPGA: X"1C16"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_001_010_0_111",  --RF[2] <- 1-(RF[0] & RF[1]) ;   nand;   FPGA: X"00A7"
    
    --I type
    B"001_001_010_0000001",    --RF[2] <- RF[1] + Z_Ext(0000001)        ;   addi;   FPGA: X"2501"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"010_010_011_0000001",    --RF[3] <- M[RF[2] + S_Ext(0000001)]     ;   lw;     FPGA: X"4981"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"011_011_100_0000001",    --M[RF[3] + S_Ext(0000001)] <- RF[4]     ;   sw;     FPGA: X"6E01"
    B"100_100_101_0000001",    --if(RF[4]==RF[5] -> PC <- PC + 4 + S_Ext(0000001) << 2
                                             --else PC <- PC + 4        ;   beq;    FPGA: X"9281"
    B"101_101_110_0000001",    --RF[6] <- RF[5]-Z_Ext(0000001)          ;   subi;   FPGA: X"B701"
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"000_000_000_000_0_010",  --sll with 0    ;   NoOp
    B"110_110_111_0000001",    --RF[7] <- RF[6] || "0000000"            ;   lui;    FPGA: X"DB81"
    
    --J type
    B"111_0010100110000",       --PC <- PC & 0xf0000000 | (0010100110000 << 2)   ;   jump;   FPGA: X"E530"
    others => x"0000");

begin

    data <= ROM(conv_integer(addr));

end Behavioral;
