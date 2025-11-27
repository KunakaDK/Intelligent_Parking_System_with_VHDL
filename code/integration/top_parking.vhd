library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_parking is
    generic(
        MAX_PLACES : integer := 99
    );
    port(
        clk   : in  std_logic;
        rst   : in  std_logic;
        -- Capteurs entrée / sortie voitures
        voiture_entree : in std_logic;
        voiture_sortie : in std_logic;
        -- Capteurs barrière
        sensor_passage      : in std_logic;
        sensor_open_limit   : in std_logic;
        sensor_closed_limit : in std_logic;
        -- Afficheur 7 segments
        cathode : out std_logic_vector(3 downto 0);
        seg     : out std_logic_vector(6 downto 0);
        -- Commandes moteur barrière
        motor_open  : out std_logic;
        motor_close : out std_logic
    );
end top_parking;

architecture structural of top_parking is
    --------------------------------------------------------------------
    -- Signaux internes
    --------------------------------------------------------------------
    signal nb_places_dispo : std_logic_vector(6 downto 0);
    signal count_unsigned  : unsigned(6 downto 0);
    signal parking_has_place  : std_logic;
    signal trigger_open : std_logic;
    
    -- Synchronisation des entrées (recommandé)
    signal voiture_entree_sync : std_logic;
    signal voiture_sortie_sync : std_logic;
    
begin
    --------------------------------------------------------------------
    -- Synchronisation des signaux d'entrée (anti-métastabilité)
    --------------------------------------------------------------------
    sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                voiture_entree_sync <= '0';
                voiture_sortie_sync <= '0';
            else
                voiture_entree_sync <= voiture_entree;
                voiture_sortie_sync <= voiture_sortie;
            end if;
        end if;
    end process;
    
    --------------------------------------------------------------------
    -- 1) Compteur places
    --------------------------------------------------------------------
    compteur_inst : entity work.compteur_places
        generic map(MAX_PLACES => MAX_PLACES)
        port map(
            clk => clk,
            rst => rst,
            voiture_entree => voiture_entree_sync,
            voiture_sortie => voiture_sortie_sync,
            nb_places_dispo => nb_places_dispo
        );
    
    --------------------------------------------------------------------
    -- 2) Conversion et détection
    --------------------------------------------------------------------
    count_unsigned <= unsigned(nb_places_dispo);
    parking_has_place <= '1' when count_unsigned > 0 else '0';
    
    --------------------------------------------------------------------
    -- 3) Logique d'ouverture CORRIGÉE
    --------------------------------------------------------------------
    -- Entrée : seulement si places disponibles
    -- Sortie : toujours autorisée (sinon deadlock si parking plein)
    trigger_open <= (voiture_entree_sync and parking_has_place) 
                    or voiture_sortie_sync;
    
    --------------------------------------------------------------------
    -- 4) Module barrière
    --------------------------------------------------------------------
    barriere_inst : entity work.controle_barriere
        port map(
            clk   => clk,
            rst   => rst,
            trigger_open        => trigger_open,
            sensor_passage      => sensor_passage,
            sensor_open_limit   => sensor_open_limit,
            sensor_closed_limit => sensor_closed_limit,
            motor_open  => motor_open,
            motor_close => motor_close
        );
    
    --------------------------------------------------------------------
    -- 5) Afficheur 7 segments
    --------------------------------------------------------------------
    sevenseg_inst : entity work.sevenseg_counter
        port map(
            clk      => clk,
            rst    => rst,
            count_in => count_unsigned,
            cathode  => cathode,
            seg      => seg
        );
    
end structural;
