library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FAU is
    generic(N : integer;
            M : integer;
            P : integer);
            
    port(In0 : in  std_logic_vector(N-1 downto 0);
         In1 : in  std_logic_vector(N-1 downto 0);
         Cin : in  std_logic;
         
         res : out std_logic_vector(N   downto 0));
   
    attribute dont_touch : string;
    attribute dont_touch of FAU : entity is "true";
    
end FAU;

architecture Behavioral of FAU is
begin
    
--  res <= ('0' & In0) + ('0' & In1) + Cin;
    
    process (In0, In1, Cin) 
        variable MSP : std_logic_vector(N-M downto 0) := (others => '0');
        variable LSP : std_logic_vector(M   downto 0) := (others => '0');
        variable sha : std_logic_vector(P   downto 0) := (others => '0');
    begin
        
        MSP := ('0' & In0(N-1 downto M  )) + ('0' & In1(N-1 downto M  ));
        LSP := ('0' & In0(M-1 downto 0  )) + ('0' & In1(M-1 downto 0  )) + Cin;
        sha := ('0' & In0(M-1 downto M-P)) + ('0' & In1(M-1 downto M-P));
        
        if(sha(P) = '1') then           -- Carry prediction
            MSP := MSP + 1;
        elsif(LSP(M) = '1') then        -- Error magnitude reduction
            LSP := (others => '1');
        end if;
        
        res(N   downto M) <= MSP(N-M downto 0);
        res(M-1 downto 0) <= LSP(M-1 downto 0);
        
    end process;
    
end Behavioral;
