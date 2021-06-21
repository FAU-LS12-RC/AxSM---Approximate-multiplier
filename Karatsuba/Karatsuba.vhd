library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library xil_defaultlib;
use xil_defaultlib.FAU_adder_wo_carry;
use xil_defaultlib.FAU_adder_w_carry;

entity karatsuba_app is
    generic(DATA_WIDTH : INTEGER := 8);
    
    Port(In0 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
         In1 : in  std_logic_vector(DATA_WIDTH-1 downto 0);
         Mul : out unsigned(2*DATA_WIDTH-1 downto 0));
         
    attribute dont_touch : string;
--  attribute use_dsp48  : string;
    
    attribute dont_touch of karatsuba_app : entity is "true";
--  attribute use_dsp48  of karatsuba_app : entity is "no";
    
end karatsuba_app;

architecture Behavioral of karatsuba_app is
    component FAU_adder_wo_carry is
        generic(N : integer;
                M : integer;
                P : integer); 
              
        port(In0 : in  unsigned (N-1 downto 0);
             In1 : in  unsigned (N-1 downto 0);
             res : out unsigned (N-1 downto 0));
    end component;
    
    component FAU_adder_w_carry is
        generic(N : integer;
                M : integer;
                P : integer); 
              
        port(In0 : in  unsigned (N-1 downto 0);
             In1 : in  unsigned (N-1 downto 0);
             res : out unsigned (N   downto 0));
    end component;
    
    signal block_a  : unsigned(DATA_WIDTH/2-1 downto 0) := (others => '0');
    signal block_b  : unsigned(DATA_WIDTH/2-1 downto 0) := (others => '0');
    signal block_c  : unsigned(DATA_WIDTH/2-1 downto 0) := (others => '0');
    signal block_d  : unsigned(DATA_WIDTH/2-1 downto 0) := (others => '0');
   
    signal mul_a_c  : unsigned(DATA_WIDTH-1   downto 0) := (others => '0');
    signal mul_b_d  : unsigned(DATA_WIDTH-1   downto 0) := (others => '0');
   
    signal add_a_b  : unsigned(DATA_WIDTH/2   downto 0) := (others => '0');
    signal add_c_d  : unsigned(DATA_WIDTH/2   downto 0) := (others => '0');
   
    signal mul_add  : unsigned(DATA_WIDTH+1   downto 0) := (others => '0');
   
    signal sum_mul  : unsigned(DATA_WIDTH     downto 0) := (others => '0');
    signal subtra   : unsigned(DATA_WIDTH+1   downto 0) := (others => '0');

    signal temp_mul : unsigned(DATA_WIDTH+3   downto 0) := (others => '0');
    
    signal foo1     : std_logic_vector(DATA_WIDTH+3   downto 0) := (others => '0');
    signal foo2     : std_logic_vector(DATA_WIDTH-1   downto 0) := (others => '0');
    
begin

    block_a <= unsigned(In0(DATA_WIDTH-1 downto DATA_WIDTH/2));     block_b <= unsigned(In0(DATA_WIDTH/2-1 downto 0));
    block_c <= unsigned(In1(DATA_WIDTH-1 downto DATA_WIDTH/2));     block_d <= unsigned(In1(DATA_WIDTH/2-1 downto 0));
    
    mul_a_c <= block_a * block_c;
    
    mul_b_d <= block_b * block_d;

--    add_a_b <= unsigned'('0' & block_a) + unsigned'('0' & block_b);
    app_add1 : entity xil_defaultlib.FAU_adder_w_carry
        generic map(N => 4,
                    M => 2,
                    P => 1)
          
        port map(In0 => block_a,
                 In1 => block_b,
                 res => add_a_b);
           
--    add_c_d <= unsigned'('0' & block_c) + unsigned'('0' & block_d); 
    app_add2 : entity xil_defaultlib.FAU_adder_w_carry
        generic map(N => 4,
                    M => 2,
                    P => 1)
              
        port map(In0 => block_c,
                 In1 => block_d,
                 res => add_c_d);
                     
    mul_add <= add_a_b * add_c_d;

--    sum_mul <= unsigned'('0' & mul_a_c) + unsigned'('0' & mul_b_d);
    app_add3 : entity xil_defaultlib.FAU_adder_w_carry
        generic map(N => DATA_WIDTH,
                    M => DATA_WIDTH/2,
                    P => 2)
              
        port map(In0 => mul_a_c,
                 In1 => mul_b_d,
                 res => sum_mul);
    
    subtra <= mul_add(DATA_WIDTH+1 downto 0) - sum_mul when (mul_add(DATA_WIDTH+1 downto 0) > sum_mul) else (others => '0');
    
--    Mul <= unsigned'((unsigned'(mul_a_c & mul_b_d(DATA_WIDTH-1 downto 4)) + unsigned'("00" & subtra)) & mul_b_d(3 downto 0));
    app_add4 : entity xil_defaultlib.FAU_adder_wo_carry
        generic map(N => 12,
                    M =>  4,
                    P =>  3)
              
        port map(In0(11 downto  4) => mul_a_c,
                 In0( 3 downto  0) => mul_b_d(7 downto 4),
                 
                 In1(11 downto 10) => "00",
                 In1( 9 downto  0) => subtra,
                 
                 res => temp_mul);

    foo1 <= std_logic_vector(temp_mul);
    foo2 <= std_logic_vector(mul_b_d);
    
    Mul <= unsigned(foo1(11 downto 0) & foo2(3 downto 0));

 end Behavioral;