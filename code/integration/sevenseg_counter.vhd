library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_counter is
    Port (
        clk     : in  STD_LOGIC;                    -- horloge 50 MHz
        rst   : in  STD_LOGIC;                    -- reset actif à 1
        count_in: in  UNSIGNED(6 downto 0);         -- valeur 0-99
        cathode : out STD_LOGIC_VECTOR(3 downto 0); -- cathodes (actif à 1)
        seg     : out STD_LOGIC_VECTOR(6 downto 0)  -- segments (actif à 1)
    );
end sevenseg_counter;

architecture rtl of sevenseg_counter is
    -- Signaux pour le multiplexage des afficheurs
    signal refresh_cnt : UNSIGNED(15 downto 0) := (others => '0');
    signal digit_sel   : STD_LOGIC;  -- Un seul bit suffit pour 2 digits
    
    -- Digits BCD
    signal d_units     : STD_LOGIC_VECTOR(3 downto 0);
    signal d_tens      : STD_LOGIC_VECTOR(3 downto 0);
    signal current_bcd : STD_LOGIC_VECTOR(3 downto 0);
    
begin
    --------------------------------------------------------------------
    -- 1) Compteur pour le multiplexage (rafraîchissement des digits)
    --------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            refresh_cnt <= (others => '0');
        elsif rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;
    
    digit_sel <= refresh_cnt(15);  -- Un seul bit pour alterner entre 2 digits
    
    --------------------------------------------------------------------
    -- 2) Conversion binaire vers chiffres BCD
    --------------------------------------------------------------------
    process(count_in)
        variable v : integer range 0 to 99;
        variable u, t : integer range 0 to 9;
    begin
        v := to_integer(count_in);
        
        -- Limitation à 99 (sécurité)
        if v > 99 then 
            v := 99;
        end if;
        
        u := v mod 10;
        t := (v / 10) mod 10;
        
        d_units <= STD_LOGIC_VECTOR(to_unsigned(u, 4));
        d_tens  <= STD_LOGIC_VECTOR(to_unsigned(t, 4));
    end process;
    
    --------------------------------------------------------------------
    -- 3) Sélection du digit + masquage du zéro en tête
    --------------------------------------------------------------------
    process(digit_sel, d_units, d_tens, count_in)
        variable v_int : integer range 0 to 99;
    begin
        v_int := to_integer(count_in);
        
        if digit_sel = '0' then
            -- Unités (toujours affiché)
            cathode <= "0001";
            current_bcd <= d_units;
        else
            -- Dizaines (masqué si < 10)
            cathode <= "0010";
            if v_int < 10 then
                current_bcd <= "1111"; -- éteint
            else
                current_bcd <= d_tens;
            end if;
        end if;
        
        -- Digits 3 et 4 toujours éteints
        -- (pas besoin de les multiplexer)
    end process;
    
    --------------------------------------------------------------------
    -- 4) Décodage BCD vers 7 segments (actif à 1)
    --------------------------------------------------------------------
    process(current_bcd)
    begin
        case current_bcd is
            when "0000" => seg <= "1111110"; -- 0
            when "0001" => seg <= "0110000"; -- 1
            when "0010" => seg <= "1101101"; -- 2
            when "0011" => seg <= "1111001"; -- 3
            when "0100" => seg <= "0110011"; -- 4
            when "0101" => seg <= "1011011"; -- 5
            when "0110" => seg <= "1011111"; -- 6
            when "0111" => seg <= "1110000"; -- 7
            when "1000" => seg <= "1111111"; -- 8
            when "1001" => seg <= "1111011"; -- 9
            when others => seg <= "0000000"; -- éteint
        end case;
    end process;
    
end rtl;