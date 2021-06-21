library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

library xil_defaultlib;
use xil_defaultlib.ADDERS;

entity Datapath is
    generic(DATA_WIDTH : integer := 0);
    
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
         --
       --Debug_reg_A  : out std_logic_vector(DATA_WIDTH     downto 0));
    
    attribute dont_touch : string;
    attribute dont_touch of Datapath : entity is "true";
         
end Datapath;

architecture Accurate_Behavioral of Datapath is
    component ADDERS is
        generic(DATA_WIDTH : integer);
                  
        port(A    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             B    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             Cin  : in  std_logic;
             --
             SUM  : out std_logic_vector(DATA_WIDTH-1 downto 0);
             Cout : out std_logic);
    end component;
    
    signal output_ADD : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal CoutSUM    : std_logic;
    --
    signal carry_ADD  : std_logic := '0';
    --
    signal Register_A : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal Register_Q : std_logic_vector(DATA_WIDTH-1 downto 0);
    --
    signal P          : unsigned(integer(ceil(log2(real(DATA_WIDTH))))-1 downto 0);
begin

    -- ACCURATE ADDER
    ACC_ADDER : entity xil_defaultlib.ADDERS(ACC)
        generic map(DATA_WIDTH => DATA_WIDTH)
                         
        port map(A    => Register_A,
                 B    => Multiplicand,
                 Cin  => '0',
                 --
                 SUM  => output_ADD,
                 Cout => CoutSUM);

    -- FLIPFLOP
    Flipflop_cout_ADD : process(clock, Clear_C)
    begin
       
       if rising_edge(clock) then
           if Clear_C = '1' then
                 carry_ADD <= '0';
           else
               if Load = '0' then
                   carry_ADD <= CoutSUM;
               end if; 
           end if;       
       end if;       
    end process;
    
    -- SHIFT REGISTERS
    process(clock, Initialize, Shift_dec, Load)
    begin
        if rising_edge(clock) then
            if Initialize = '1' then
                Register_A <= (others => '0');
                Register_Q <= Multiplier;
                P          <= to_unsigned(DATA_WIDTH-1, integer(ceil(log2(real(DATA_WIDTH)))));
            end if;
                    
            if Shift_dec = '1' then
                P          <= P - 1;
                Register_Q <= Register_A(0) & Register_Q(DATA_WIDTH-1 downto 1);
                Register_A <= carry_ADD     & Register_A(DATA_WIDTH-1 downto 1);
            end if;
            
            if Load = '1' then
                Register_A <= output_ADD;
            end if;
        end if;
    end process;
    
    Z           <= '0' when P > 0 else '1';
    --
    Product     <= Register_A & Register_Q;
    Q0          <= Register_Q(0);
    --
  --Debug_reg_A <= carry_ADD & Register_A;
    
end Accurate_Behavioral;

architecture Approximate_Behavioral of Datapath is
    component ADD is
        generic(DATA_WIDTH : integer);
                  
        port(A    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             B    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
             Cin  : in  std_logic;
             --
             SUM  : out std_logic_vector(DATA_WIDTH-1 downto 0);
             Cout : out std_logic);
    end component;
    
    signal output_MSP_ADD : std_logic_vector(DATA_WIDTH/2-1 downto 0);
    signal output_LSP_ADD : std_logic_vector(DATA_WIDTH/2-1 downto 0);
    --
    signal Cout_MSP_SUM   : std_logic;
    signal Cout_LSP_SUM   : std_logic;
    --
    signal carry_MSP_ADD  : std_logic := '0';
    signal carry_LSP_ADD  : std_logic := '0';
    --
    signal Register_LSP_A : std_logic_vector(DATA_WIDTH/2-1 downto 0);
    signal Register_MSP_A : std_logic_vector(DATA_WIDTH/2-1 downto 0);
    signal Register_Q     : std_logic_vector(DATA_WIDTH-1   downto 0);
    --
    signal P              : unsigned(integer(ceil(log2(real(DATA_WIDTH))))-1 downto 0);
    
    attribute xc_nodelay  : boolean;
    
    attribute xc_nodelay of carry_MSP_ADD : signal is true;
    attribute xc_nodelay of carry_LSP_ADD : signal is true;

begin

    -- APPROXIMATE ADDERS
    MSP_ADDER : entity xil_defaultlib.ADDERS(APP_MSP)
        generic map(DATA_WIDTH => DATA_WIDTH/2)
                         
        port map(A    => Register_MSP_A,
                 B    => Multiplicand(DATA_WIDTH-1 downto DATA_WIDTH/2),
                 Cin  => carry_LSP_ADD,
                 --
                 SUM  => output_MSP_ADD,
                 Cout => Cout_MSP_SUM);

    LSP_ADDER : entity xil_defaultlib.ADDERS(APP_LSP)
        generic map(DATA_WIDTH => DATA_WIDTH/2)
                         
        port map(A    => Register_LSP_A,
                 B    => Multiplicand(DATA_WIDTH/2-1 downto 0),
                 Cin  => '0', --carry_LSP_ADD,
                 --
                 SUM  => output_LSP_ADD,
                 Cout => Cout_LSP_SUM);

    -- FLIPFLOPS
    Flipflops_cout_ADD : process(clock, Clear_C)
    begin
       if Clear_C = '1' then
          carry_MSP_ADD <= '0';
          carry_LSP_ADD <= '0';
       elsif rising_edge(clock) then
            if Load = '0' then
                carry_MSP_ADD <= Cout_MSP_SUM;
                carry_LSP_ADD <= Cout_LSP_SUM;
            end if; 
        end if;       
    end process;
    
    -- SHIFT REGISTERS
    process(clock, Initialize, Shift_dec, Load)
    begin
        if rising_edge(clock) then
            if Initialize = '1' then
                Register_MSP_A <= (others => '0');
                Register_LSP_A <= (others => '0');
                Register_Q     <= Multiplier;
                P              <= to_unsigned(DATA_WIDTH-1, integer(ceil(log2(real(DATA_WIDTH)))));
            end if;
            
            if Shift_dec = '1' then
                P              <= P - 1;
                Register_Q     <= Register_LSP_A(0) & Register_Q    (DATA_WIDTH-1   downto 1);
                Register_LSP_A <= Register_MSP_A(0) & Register_LSP_A(DATA_WIDTH/2-1 downto 1);
                Register_MSP_A <= carry_MSP_ADD     & Register_MSP_A(DATA_WIDTH/2-1 downto 1);
            end if;
            
            if Load = '1' then
                Register_MSP_A <= output_MSP_ADD;
              --Register_LSP_A <= output_LSP_ADD;
              --Register_Q     <= Register_Q;
                
                if P > 0 then
                    Register_LSP_A <= output_LSP_ADD;
                else
                    Register_LSP_A <= output_LSP_ADD or (DATA_WIDTH/2-1 downto 0 => carry_LSP_ADD);
                    Register_Q     <= Register_Q     or (DATA_WIDTH-1   downto 0 => carry_LSP_ADD);
                end if;
            end if;
        end if;
    end process;
    
    Z           <= '0' when P > 0 else '1';
    --
    Product     <= Register_MSP_A & Register_LSP_A & Register_Q;
    Q0          <= Register_Q(0);
    --
  --Debug_reg_A <= (others => '0');
    
end Approximate_Behavioral;
