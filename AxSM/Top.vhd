library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Top is
    generic(DATA_WIDTH : integer := 32;
            TEST_TYPE  : string  := "IMPLEMENTATION";
            ARCH_TYPE  : string  := "APPROXIMATE" --"ACCURATE"
            );
            
    port(--Go          : in  std_logic;
         Reset_to_idle : in  std_logic;
         dummy_in      : in  std_logic;
         clock         : in  std_logic;
         --
         dummy_out     : out std_logic);

    attribute dont_touch        : string;
    attribute dont_touch of Top : entity is "true";

end Top;

architecture Behavioral of Top is
    component Wrapper is
        generic(DATA_WIDTH : integer;
                TEST_TYPE  : string;
                ARCH_TYPE  : string);
                  
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
    end component;

    signal reg_Multiplicand : std_logic_vector(DATA_WIDTH-1   downto 0);
    signal reg_Multiplier   : std_logic_vector(DATA_WIDTH-1   downto 0);
    --
    signal reg_Product      : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    signal Product          : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    signal temp_acc_Product : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    signal temp_app_Product : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    --
    signal done             : std_logic;
begin

    Multiplier : Wrapper
    generic map(DATA_WIDTH => DATA_WIDTH,
                TEST_TYPE  => TEST_TYPE,
                ARCH_TYPE  => ARCH_TYPE)
                        
    port map(--Go          => Go,
             Reset_to_idle => Reset_to_idle,
             Multiplicand  => reg_Multiplicand,
             Multiplier    => reg_Multiplier,
             clock         => clock,
             --
             done          => done,
             --
             ACC_Product   => temp_acc_Product,
             APP_Product   => temp_app_Product);
             --
           --Debug_reg_A   => open,
           --Debug_load    => open);

    -- INPUT SHIFT REGISTER
    process(clock, Reset_to_idle)
    begin
        if Reset_to_idle = '1' then
            reg_Multiplier   <= (others => '0');
            reg_Multiplicand <= (others => '0');
        elsif rising_edge(clock) then
            reg_Multiplicand <= reg_Multiplier(0) & reg_Multiplicand(DATA_WIDTH-1 downto 1);
            reg_Multiplier   <= dummy_in          & reg_Multiplier  (DATA_WIDTH-1 downto 1);
        end if;
    end process;
    
    -- OUTPUT SHIFT REGISTER
    process(clock, done, temp_acc_Product, temp_app_Product)
    begin
        if rising_edge(clock) then
            if done = '1' then
                case ARCH_TYPE is
                    when "ACCURATE"    => reg_Product <= temp_acc_Product;
                    when "APPROXIMATE" => reg_Product <= temp_app_Product;
                    when others => report "Guards! Guards!" severity failure;
                end case;
            else--if rising_edge(clock) then
                reg_Product <= reg_Product(0) & reg_Product(DATA_WIDTH*2-1 downto 1);
            end if;
        end if;
    end process;
     
    dummy_out <= reg_Product(0);
    
end Behavioral;
