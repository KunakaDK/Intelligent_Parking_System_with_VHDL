library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity compteur_places is
    generic(
        MAX_PLACES : integer := 99  -- Capacité maximale du parking
    );
    port(
        clk       : in  std_logic;      -- Horloge
        rst       : in  std_logic;      -- Reset synchrone
        voiture_entree : in std_logic;  -- Signal d'entrée d'une voiture
        voiture_sortie : in std_logic;  -- Signal de sortie d'une voiture
        nb_places_dispo : out std_logic_vector(6 downto 0)  -- Nombre de places disponibles
    );
end compteur_places;

architecture Behavioral of compteur_places is
    signal compteur : integer range 0 to MAX_PLACES := MAX_PLACES;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                compteur <= MAX_PLACES; -- Reset: 99 places disponibles
            else
                -- Gestion des cas avec priorités claires
                if voiture_sortie = '1' and voiture_entree = '1' then
                    -- Cas simultané : pas de changement
                    compteur <= compteur;
                elsif voiture_sortie = '1' and compteur < MAX_PLACES then
                    -- Une voiture sort
                    compteur <= compteur + 1;
                elsif voiture_entree = '1' and compteur > 0 then
                    -- Une voiture entre
                    compteur <= compteur - 1;
                end if;
            end if;
        end if;
    end process;
    
    -- Conversion du compteur en std_logic_vector
    nb_places_dispo <= std_logic_vector(to_unsigned(compteur, 7));
    
end Behavioral;
