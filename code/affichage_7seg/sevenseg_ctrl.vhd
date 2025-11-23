library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevenseg_ctrl is
    Port (
        clk      : in  STD_LOGIC;             -- horloge 50 MHz
        reset_n  : in  STD_LOGIC;             -- reset actif à 0
        count_in : in  UNSIGNED(13 downto 0); -- valeur à afficher (0..9999)
        an       : out STD_LOGIC_VECTOR(3 downto 0); -- anodes (actif à 0)
        seg      : out STD_LOGIC_VECTOR(6 downto 0)   -- segments (actif à 0)
    );
end sevenseg_ctrl;

architecture rtl of sevenseg_ctrl is

    signal refresh_cnt : UNSIGNED(15 downto 0) := (others => '0');
    signal digit_sel   : STD_LOGIC_VECTOR(1 downto 0);

    signal d_units     : STD_LOGIC_VECTOR(3 downto 0);
    signal d_tens      : STD_LOGIC_VECTOR(3 downto 0);
    signal d_hundreds  : STD_LOGIC_VECTOR(3 downto 0);
    signal d_thousands : STD_LOGIC_VECTOR(3 downto 0);

    signal current_bcd : STD_LOGIC_VECTOR(3 downto 0);

begin

    --------------------------------------------------------------------
    -- 1) Compteur pour le multiplexage (rafraîchissement des digits)
    --------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            refresh_cnt <= (others => '0');
        elsif rising_edge(clk) then
            refresh_cnt <= refresh_cnt + 1;
        end if;
    end process;

    digit_sel <= STD_LOGIC_VECTOR(refresh_cnt(15 downto 14));

    --------------------------------------------------------------------
    -- 2) Conversion binaire vers chiffres BCD
    --------------------------------------------------------------------
    process(count_in)
        variable v : integer range 0 to 9999;
        variable u, t, h, th : integer range 0 to 9;
    begin
        v := to_integer(count_in);

        if v < 0 then 
            v := 0;
        elsif v > 9999 then 
            v := 9999;
        end if;

        u  := v mod 10;
        t  := (v / 10)   mod 10;
        h  := (v / 100)  mod 10;
        th := (v / 1000) mod 10;

        d_units     <= STD_LOGIC_VECTOR(to_unsigned(u, 4));
        d_tens      <= STD_LOGIC_VECTOR(to_unsigned(t, 4));
        d_hundreds  <= STD_LOGIC_VECTOR(to_unsigned(h, 4));
        d_thousands <= STD_LOGIC_VECTOR(to_unsigned(th, 4));
    end process;

    --------------------------------------------------------------------
    -- 3) Sélection du digit + masquage des zéros en tête
    --------------------------------------------------------------------
    process(digit_sel, d_units, d_tens, d_hundreds, d_thousands, count_in)
        variable v_int : integer range 0 to 9999;
    begin
        v_int := to_integer(count_in);

        case digit_sel is

            when "00" =>  -- unités
                an <= "1110";
                current_bcd <= d_units;

            when "01" =>  -- dizaines
                an <= "1101";
                if v_int < 10 then
                    current_bcd <= "1111"; -- éteint
                else
                    current_bcd <= d_tens;
                end if;

            when "10" =>  -- centaines
                an <= "1011";
                if v_int < 100 then
                    current_bcd <= "1111";
                else
                    current_bcd <= d_hundreds;
                end if;

            when others => -- milliers
                an <= "0111";
                if v_int < 1000 then
                    current_bcd <= "1111";
                else
                    current_bcd <= d_thousands;
                end if;

        end case;
    end process;

    --------------------------------------------------------------------
    -- 4) Décodage des segments
    --------------------------------------------------------------------
    decoder_inst : entity work.bcd_to_7seg
        port map (
            bcd => current_bcd,
            seg => seg
        );

end rtl;
