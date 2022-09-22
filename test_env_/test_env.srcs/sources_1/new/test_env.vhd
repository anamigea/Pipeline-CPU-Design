library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity test_env is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end test_env;

architecture Behavioral of test_env is

    component ssd is
        Port ( clk : in STD_LOGIC;
            an : out STD_LOGIC_VECTOR (3 downto 0);
            cat : out STD_LOGIC_VECTOR (6 downto 0);
             digit : in STD_LOGIC_VECTOR (15 downto 0));
    end component;

    component instruction_fetch is
    Port ( clk : in STD_LOGIC;
           branchAddr : in STD_LOGIC_VECTOR (15 downto 0);
           jumpAddr : in STD_LOGIC_VECTOR (15 downto 0);
           PCSrc : in STD_LOGIC;
           Jump : in STD_LOGIC;
           en : in STD_LOGIC;
           rst : in STD_LOGIC;
           instruction : out STD_LOGIC_VECTOR (15 downto 0);
           PCOut : out STD_LOGIC_VECTOR (15 downto 0));
    end component;
    
    component instruction_decode is
    Port ( clk : in STD_LOGIC;
           instruction : in STD_LOGIC_VECTOR (15 downto 0);
           WriteData : in STD_LOGIC_VECTOR (15 downto 0);
           WriteAddress : in STD_LOGIC_VECTOR (2 downto 0);
           RegWrite : in STD_LOGIC;
  
           ExtOp : in STD_LOGIC;
           RD1 : out STD_LOGIC_VECTOR (15 downto 0);
           RD2 : out STD_LOGIC_VECTOR (15 downto 0);
           Ext_Imm : out STD_LOGIC_VECTOR (15 downto 0);
           sa : out STD_LOGIC;
           funct : out STD_LOGIC_VECTOR (2 downto 0);
           RAW1 : out STD_LOGIC_VECTOR (2 downto 0);
           RAW2 : out STD_LOGIC_VECTOR (2 downto 0)); 
    end component;
    
    component control_unit is
    port (
        opcode : in std_logic_vector (2 downto 0);
        RegDst : out std_logic;
        ExtOp : out std_logic;
        ALUSrc : out std_logic;
        Branch : out std_logic;
        Jump : out std_logic;
        ALUOp : out std_logic_vector(2 downto 0);
        MemWrite : out std_logic;
        MemtoReg : out std_logic;
        RegWrite : out std_logic
    );
    end component;
    
    component mono_pulse_gen
        Port(clk    : in  STD_LOGIC;
             btn    : in  STD_LOGIC;
             enable : out STD_LOGIC);
    end component;
    
    component instruction_execute is
    Port (
        RD1 : in std_logic_vector (15 downto 0);
        RD2 : in std_logic_vector (15 downto 0);
        Ext_Imm : in std_logic_vector (15 downto 0);
        PCOut : in std_logic_vector (15 downto 0);
        funct : in std_logic_vector (2 downto 0);
        sa : in std_logic;
        ALUOp : in std_logic_VECTOR(2 downto 0);
        ALUSrc : in std_logic;
        RAW1 : in STD_LOGIC_VECTOR (2 downto 0);
        RAW2 : in STD_LOGIC_VECTOR (2 downto 0);
        RegDst : in STD_LOGIC;
        RAOut : out STD_LOGIC_VECTOR(2 downto 0);
        ALURes : out std_logic_vector(15 downto 0);
        BranchAddress : out std_logic_vector(15 downto 0);
        Zero : out std_logic
    );
    end component;
    
    component data_memory is
    Port ( 
        clk : in std_logic;
        MemWrite : in std_logic; --MemWrite signal should be validated with an output of the MPG component
        ALUResAddr : in std_logic_vector(15 downto 0);
        RD2_WriteData : in std_logic_vector(15 downto 0);
        MemData : out std_logic_vector(15 downto 0); --used only for load word instructions
        ALUResData : out std_logic_vector(15 downto 0)
    );
    end component;
    
    signal instruction : std_logic_vector(15 downto 0) :=(others=>'0');
    signal PCOut : std_logic_vector(15 downto 0) :=(others=>'0');
    signal s_enable : std_logic :='0';
    signal s_enable_reset : std_logic :='0';
    signal RegDst, RegWrite, RegWrite_enable, ExtOp, sa, Branch, Jump, MemWrite, MemWrite_enable, MemtoReg, ALUSrc : std_logic;
    signal RD1, RD2, Ext_Imm, ALURes, BranchAddress, chosen_output, MemData, jumpAddr, muxmem : std_logic_vector(15 downto 0) :=(others=>'0');
    signal funct, ALUOp : std_logic_vector(2 downto 0);
    signal Zero, BranchS : std_logic:='0';
    
    --pipeline
    signal RAOut,RAW1,RAW2 : std_logic_vector(2 downto 0);
    
    signal reg_IF_ID : std_logic_vector(31 downto 0):=(others => '0');
    signal reg_ID_EX : std_logic_vector(82 downto 0):=(others => '0');
    signal reg_EX_MEM : std_logic_vector(55 downto 0):=(others => '0');
    signal reg_MEM_WB : std_logic_vector(36 downto 0):=(others => '0');
begin
    pipe_IF_ID: process(clk)
    begin
        if rising_edge(clk) then
            reg_IF_ID(31 downto 16)<=PCOut;
            reg_IF_ID(15 downto 0)<=instruction;
        end if;
    end process;
    
    pipe_ID_EX: process(clk)
    begin
        if rising_edge(clk) then
            reg_ID_EX(82)<=sa;
            reg_ID_EX(81 downto 80)<=MemtoReg & RegWrite; --WB
            reg_ID_EX(79 downto 78)<=MemWrite & Branch; --M
            reg_ID_EX(77 downto 73)<= ALUOp & ALUSrc & RegDst; --EX
            reg_ID_EX(72 downto 57)<=reg_IF_ID(31 downto 16);
            reg_ID_EX(56 downto 41)<=RD1;
            reg_ID_EX(40 downto 25)<=RD2;
            reg_ID_EX(24 downto 9)<=Ext_Imm;
            reg_ID_EX(8 downto 6)<=funct;
            reg_ID_EX(5 downto 3)<=RAW1;
            reg_ID_EX(2 downto 0)<=RAW2;
        end if;
    end process;
    
    pipe_EX_MEM: process(clk)
    begin
        if rising_edge(clk) then
            reg_EX_MEM(55 downto 54)<=reg_ID_EX(81 downto 80);
            reg_EX_MEM(53 downto 52)<=reg_ID_EX(79 downto 78);
            reg_EX_MEM(51 downto 36)<=BranchAddress;
            reg_EX_MEM(35)<=Zero;
            reg_EX_MEM(34 downto 19)<=ALURes;
            reg_EX_MEM(18 downto 3)<=reg_ID_EX(40 downto 25);
            
            --RAOut
            if reg_ID_EX(73)='0'then
                reg_EX_MEM(2 downto 0)<=reg_ID_EX(5 downto 3);
            else
                reg_EX_MEM(2 downto 0)<=reg_ID_EX(2 downto 0);
            end if;
        end if;
    end process;
    
    pipe_MEM_WB: process(clk)
    begin
        if rising_edge(clk) then
            reg_MEM_WB(36 downto 35)<=reg_EX_MEM(55 downto 54);
            reg_MEM_WB(34 downto 19)<=MemData;
            reg_MEM_WB(18 downto 3)<=reg_EX_MEM(34 downto 19);
            reg_MEM_WB(2 downto 0)<=reg_EX_MEM(2 downto 0);
            
        end if;
    end process;
    
    instruction_fetch_ins: instruction_fetch
    port map(
            clk => clk,
            branchAddr => reg_EX_MEM(51 downto 36),
            jumpAddr => jumpAddr,
            PCSrc => BranchS,
            Jump => Jump,
            en => s_enable,
            rst => s_enable_reset,
            instruction => instruction,
            PCOut => PCOut
        ); 
        
     instruction_decode_ins: instruction_decode
     port map(
           clk => clk,
           instruction =>reg_IF_ID(15 downto 0),
           WriteData => muxmem,
           WriteAddress => reg_MEM_WB(2 downto 0), 
           RegWrite => RegWrite_enable,
           ExtOp => ExtOp,
           RD1 => RD1,
           RD2 => RD2,
           Ext_Imm => Ext_Imm,
           sa => sa,
           funct => funct,
           RAW1 => RAW1,
           RAW2 => RAW2
           );   
           
     instruction_execute_ins: instruction_execute
     port map(
            RD1 => reg_ID_EX(56 downto 41),
            RD2 => reg_ID_EX(40 downto 25),
            Ext_Imm => reg_ID_EX(24 downto 9),
            PCOut => reg_ID_EX(72 downto 57),
            funct => reg_ID_EX(8 downto 6),
            sa => reg_ID_EX(82),
            ALUOp => reg_ID_EX(77 downto 75),
            ALUSrc => reg_ID_EX(74),
            RAW1 => reg_ID_EX(5 downto 3),
            RAW2 => reg_ID_EX(2 downto 0),
            RegDst => reg_ID_EX(73),
            RAOut => RAOut,
            ALURes => ALURes,
            BranchAddress => BranchAddress,
            Zero => Zero
            );
     control_unit_ins: control_unit
     port map(
        opcode => reg_IF_ID(15 downto 13),
        RegDst => RegDst,
        ExtOp => ExtOp,
        ALUSrc => ALUSrc, --alu soauce
        Branch => Branch,
        Jump => Jump,
        ALUOp => ALUOp,
        MemWrite => MemWrite,
        MemtoReg => MemtoReg,
        RegWrite => RegWrite
    );
    
    data_memory_ins: data_memory
    port map(
        clk => clk,
        MemWrite => MemWrite_enable, --MemWrite signal should be validated with an output of the MPG component
        ALUResAddr => reg_EX_MEM(34 downto 19),
        RD2_WriteData => reg_EX_MEM(18 downto 3),
        MemData => MemData, --used only for load word instructions
        ALUResData => reg_EX_MEM(34 downto 19)
    );
        
    --RegWrite_enable <= RegWrite and s_enable;
    RegWrite_enable <= reg_MEM_WB(35) and s_enable;
    --MemWrite_enable <= MemWrite and s_enable;
    MemWrite_enable <= reg_EX_MEM(53) and s_enable;
    
    --jumpAddr <= PCOut(15 downto 13) & instruction(12 downto 0);
    jumpAddr <= reg_IF_ID(31 downto 29) & reg_IF_ID(12 downto 0);
    
    --muxmem <= ALURes when MemtoReg = '0' else MemData ;
    muxmem <= reg_MEM_WB(18 downto 3) when reg_MEM_WB(36) = '0' else reg_MEM_WB(34 downto 19) ;
    
    --BranchS <= Branch AND Zero;
    BranchS <= reg_EX_MEM(52) AND reg_EX_MEM(35);
    
    switch_process_data_path_signals: process(sw(7 downto 5),instruction,RD1,RD2,PCOut,Ext_Imm,ALURes)
    begin
        case(sw(7 downto 5)) is
            when "000" => chosen_output<=instruction; --instruction is from ROM
            when "001" => chosen_output<=PCOut;
            when "010" => chosen_output<=RD1;
            when "011" => chosen_output<=RD2;
            when "100" => chosen_output<=Ext_Imm;
            when "101" => chosen_output<=ALURes;
            when "110" => chosen_output<=MemData;
            when "111" => chosen_output<=muxmem;
            when others => chosen_output<=X"0000";
        end case;
    end process;
    
    switch_process_control_signals: process(sw(0),RegDst,ExtOp,ALUSrc, Branch, Jump,ALUOp,MemWrite, MemtoReg, RegWrite)
    begin
        if sw(0)='0' then
            led <= X"00" & RegDst & ExtOp & ALUSrc & Branch & Jump & MemWrite & MemtoReg & RegWrite;
        else
            led <= "0000000000000"  & ALUOp;
        end if;
            
    end process;
    
    ssdisplay: ssd
    port map(
        clk    => clk,
            an=>an,          
            cat=>cat,
            digit=>chosen_output 
        ); 
    
    mpg : mono_pulse_gen
        port map(
            clk    => clk,
            btn    => btn(0),         
            enable => s_enable
        );  
    mpg_reset_pc : mono_pulse_gen
        port map(
            clk    => clk,
            btn    => btn(1),         
            enable => s_enable_reset
        );

end Behavioral;