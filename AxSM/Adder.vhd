library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;

entity ADDERS is
    generic(DATA_WIDTH : integer);
            
    port(A    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
         B    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
         Cin  : in  std_logic;
         --
         SUM  : out std_logic_vector(DATA_WIDTH-1 downto 0);
         Cout : out std_logic);
   
--    attribute dont_touch : string;
--    attribute dont_touch of ADDERS : entity is "true";
    
end ADDERS;

architecture ACC of ADDERS is
    signal full_sum : std_logic_vector(DATA_WIDTH downto 0);
begin
    
    full_sum <= std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
    
    SUM      <= full_sum(DATA_WIDTH-1 downto 0); 
    Cout     <= full_sum(DATA_WIDTH);
    
end ACC;

architecture APP_MSP of ADDERS is
    signal full_sum : std_logic_vector(DATA_WIDTH downto 0);
begin
    
    full_sum <= std_logic_vector(unsigned('0' & A) + unsigned('0' & B) + unsigned((A and (DATA_WIDTH-1 downto 0 => '0')) & Cin));
  --full_sum <= std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
    
    SUM      <= full_sum(DATA_WIDTH-1 downto 0);
    Cout     <= full_sum(DATA_WIDTH);
    
end APP_MSP;

architecture APP_LSP of ADDERS is
    signal full_sum : std_logic_vector(DATA_WIDTH   downto 0);
  --signal fixed_A  : std_logic_vector(DATA_WIDTH-1 downto 0);
begin

  --fixed_A  <= (A(DATA_WIDTH-1) xor Cin) & A(DATA_WIDTH-2 downto 0);
  --full_sum <= std_logic_vector(unsigned('0' & fixed_A) + unsigned('0' & B));
    full_sum <= std_logic_vector(unsigned('0' & A) + unsigned('0' & B));
    
    SUM      <= full_sum(DATA_WIDTH-1 downto 0);
    Cout     <= full_sum(DATA_WIDTH);
  
  --SUM      <= full_sum(DATA_WIDTH-1 downto 0) or (DATA_WIDTH-1 downto 0 => full_sum(DATA_WIDTH));
  --Cout     <= '0';
    
end APP_LSP;