library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library xil_defaultlib;
use xil_defaultlib.Datapath;

entity Wrapper is
    generic(DATA_WIDTH : integer;
            TEST_TYPE  : string := "";
            ARCH_TYPE  : string := "";
            CIRC_TYPE  : string := "");

    port(--Go          : in  std_logic;
         Reset_to_idle : in  std_logic;
         Multiplicand  : in  std_logic_vector(DATA_WIDTH-1   downto 0);
         Multiplier    : in  std_logic_vector(DATA_WIDTH-1   downto 0);
         clock         : in  std_logic;
         --
         done          : out std_logic;
         ACC_Product   : out std_logic_vector(DATA_WIDTH*2-1 downto 0);
         APP_Product   : out std_logic_vector(DATA_WIDTH*2-1 downto 0));
         --
       --Debug_reg_A   : out std_logic_vector(DATA_WIDTH     downto 0);
       --Debug_load    : out std_logic);

    attribute dont_touch : string;
    attribute dont_touch of Wrapper : entity is "true";

    attribute use_dsp48  : string;
    attribute use_dsp48  of Wrapper : entity is "no";

end Wrapper;

architecture Behavioral of Wrapper is
    component Controller is
        generic(DATA_WIDTH : integer);
        
        port(--Go          : in  std_logic;
             Reset_to_idle : in  std_logic;
             --
             Z             : in  std_logic;
             --
             clock         : in  std_logic;
             --
             Clear_C       : out std_logic;
             Load          : out std_logic;
             Initialize    : out std_logic;
             Shift_dec     : out std_logic);
    end component;

    component Datapath is
        generic(DATA_WIDTH : integer);
                  
        port(Multiplicand : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             Multiplier   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             --
             Clear_C      : in  std_logic;
             Load         : in  std_logic;
             Initialize   : in  std_logic;
             Shift_dec    : in  std_logic;
             --
             clock        : in  std_logic;
             --
             Z            : out std_logic;
             Q0           : out std_logic;
             --
             Product      : out std_logic_vector(DATA_WIDTH*2-1 downto 0));
           --Debug_reg_A  : out std_logic_vector(DATA_WIDTH     downto 0));
    end component;
    
    signal Z_acc             : std_logic;
    signal Z_app             : std_logic;
    --
    signal Z_and             : std_logic;
    signal Z_or              : std_logic;
    --
    signal Q0_acc            : std_logic;
    signal Q0_app            : std_logic;
    signal Clear_C           : std_logic;
    signal Load              : std_logic;
    signal Initialize        : std_logic;
    signal Shift_dec         : std_logic;
    --
    signal temp_acc          : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    signal temp_app          : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    --
    signal temp_Multiplicand : std_logic_vector(DATA_WIDTH-1   downto 0);
    --
  --signal temp_debug_reg_A  : std_logic_vector(DATA_WIDTH     downto 0);
begin
    
    Control : Controller
        generic map(DATA_WIDTH => DATA_WIDTH)
        
        port map(--Go          => Go,
                 Reset_to_idle => Reset_to_idle,
                 --
                 Z             => Z_and,
                 --
                 clock         => clock,
                 --
                 Clear_C       => Clear_C,
                 Load          => Load,
                 Initialize    => Initialize,
                 Shift_dec     => Shift_dec);
    
    temp_Multiplicand <= Multiplicand and (DATA_WIDTH-1 downto 0 => (Q0_acc and Q0_acc)) when TEST_TYPE = "SIMULATION" else 
                         Multiplicand and (DATA_WIDTH-1 downto 0 => Q0_acc)              when ARCH_TYPE = "ACCURATE"   else
                         Multiplicand and (DATA_WIDTH-1 downto 0 => Q0_app)              when ARCH_TYPE = "APPROXIMATE";
    
    ACC : if TEST_TYPE = "SIMULATION" or ARCH_TYPE = "ACCURATE" generate
        Accurate : entity xil_defaultlib.Datapath(Accurate_Behavioral)
            generic map(DATA_WIDTH => DATA_WIDTH)
            
            port map(Multiplicand  => temp_Multiplicand,
                     Multiplier    => Multiplier,
                     --
                     Clear_C       => Clear_C,
                     Load          => Load,
                     Initialize    => Initialize,
                     Shift_dec     => Shift_dec,
                     --
                     clock         => clock,
                     --
                     Z             => Z_acc,
                     Q0            => Q0_acc,
                     --
                     Product       => temp_acc);
                     --
                   --Debug_reg_A   => temp_debug_reg_A);
    end generate;

  --Debug_reg_A <= temp_debug_reg_A;

    APP : if TEST_TYPE = "SIMULATION" or ARCH_TYPE = "APPROXIMATE" generate
        Approximate : entity xil_defaultlib.Datapath(Approximate_Behavioral)
            generic map(DATA_WIDTH => DATA_WIDTH)
        
            port map(Multiplicand  => temp_Multiplicand,
                     Multiplier    => Multiplier,
                     --
                     Clear_C       => Clear_C,
                     Load          => Load,
                     Initialize    => Initialize,
                     Shift_dec     => Shift_dec,
                     --
                     clock         => clock,
                     --
                     Z             => Z_app,
                     Q0            => Q0_app,
                     --
                     Product       => temp_app);
                     --
                   --Debug_reg_A   => open);
    end generate;

    Z_and <= Z_acc and Z_app when TEST_TYPE = "SIMULATION" else 
             Z_acc           when ARCH_TYPE = "ACCURATE"   else
             Z_app           when ARCH_TYPE = "APPROXIMATE";
    
    Z_or  <= Z_acc or  Z_app when TEST_TYPE = "SIMULATION" else
             Z_acc           when ARCH_TYPE = "ACCURATE"   else
             Z_app           when ARCH_TYPE = "APPROXIMATE";

    process(clock, Z_or)
    begin
        if rising_edge(clock) then
            if Z_or = '0' then
                if TEST_TYPE = "SIMULATION" or ARCH_TYPE = "ACCURATE" then
                    ACC_Product <= temp_acc;
                end if;
                
                if TEST_TYPE = "SIMULATION" or ARCH_TYPE = "APPROXIMATE" then
                    APP_Product <= temp_app;
                end if;
            end if;
        end if;
    end process;
    
    done       <= not(Z_and);
  --Debug_load <= Load;

end Behavioral;
