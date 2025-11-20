
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  -- mieux pour les conversions

entity compteur_places is
    generic(
        MAX_PLACES : integer := 100  -- Capacité maximale du parking
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

    process(clk, rst)
    begin
        if rst = '1' then
            compteur <= MAX_PLACES; -- Reset: toutes les places disponibles
        elsif rising_edge(clk) then
            -- Incrémentation si une voiture sort et qu'on n'est pas déjà à max
            if voiture_sortie = '1' and compteur < MAX_PLACES then
                compteur <= compteur + 1;
            end if;

            -- Décrémentation si une voiture entre et qu'il reste des places
            if voiture_entree = '1' and compteur > 0 then
                compteur <= compteur - 1;
            end if;
        end if;
    end process;

    nb_places_dispo <= std_logic_vector(to_unsigned(compteur, 7));  -- 7 bits pour 0-100

end Behavioral;
