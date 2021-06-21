library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Controller is
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

    attribute dont_touch : string;    
    attribute dont_touch of Controller : entity is "true";

end Controller;

architecture Behavioral of Controller is
    type state_type is (IDLE, MUL0, MUL1);
	signal state : state_type := IDLE;
begin
    
    process(clock, Reset_to_idle)
    begin
        if Reset_to_idle = '1' then
            state <= IDLE;
        elsif rising_edge(clock) then   
            case state is
                when IDLE =>
                    Shift_dec   <= '0';
                    Load        <= '0';
                    Clear_C     <= '1';  -- C << 0
                    Initialize  <= '1';  -- A << 0, P << n-1, Q << multiplier
                    
                  --if Go = '1' then
                        state   <= MUL0;
                  --end if;
                when MUL0 =>
                    Initialize  <= '0';
                    Shift_dec   <= '0';
                    Clear_C     <= '0';
                    Load        <= '1';
                    
                    state       <= MUL1;
                when MUL1 =>
                    Shift_dec   <= '1';  -- C|A|Q << shr(C|A|Q), P << P-1
                    Clear_C     <= '0';
                    Initialize  <= '0';
                    Load        <= '0';
                    
                    if Z = '0' then
                        state   <= MUL0;
                    else
                        state   <= IDLE;
                    end if;
                when others =>
                    state       <= IDLE;
            end case;
        end if;
    end process;
    
end Behavioral;
