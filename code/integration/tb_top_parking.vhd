LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

ENTITY tb_top_parking IS
END ENTITY tb_top_parking;

ARCHITECTURE test OF tb_top_parking IS

  CONSTANT CLK_PERIOD   : TIME := 20 ns;
  CONSTANT MAX_PLACES   : INTEGER := 4;
  
  SIGNAL clk     : STD_LOGIC := '0';
  SIGNAL rst     : STD_LOGIC := '0';
  SIGNAL done    : BOOLEAN := FALSE;
  
  -- Capteurs
  SIGNAL voiture_entree          : STD_LOGIC := '0';
  SIGNAL voiture_sortie          : STD_LOGIC := '0';
  SIGNAL sensor_passage         : STD_LOGIC := '0';
  SIGNAL sensor_open_limit      : STD_LOGIC := '0';
  SIGNAL sensor_closed_limit    : STD_LOGIC := '1';
  
  -- Sorties
  SIGNAL motor_open             : STD_LOGIC;
  SIGNAL motor_close            : STD_LOGIC;
  SIGNAL cathode                : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL seg                    : STD_LOGIC_VECTOR(6 DOWNTO 0);
  
  -- Signaux de monitoring
  SIGNAL places_disponibles     : INTEGER := MAX_PLACES;
  SIGNAL nb_voitures_entrees    : INTEGER := 0;
  SIGNAL nb_voitures_sorties    : INTEGER := 0;
  SIGNAL nb_tentatives_refusees : INTEGER := 0;
  SIGNAL parking_full           : STD_LOGIC := '0';
  SIGNAL parking_has_place      : STD_LOGIC := '1';

BEGIN

  --------------------------------------------------------------------
  -- Générateur d'horloge
  --------------------------------------------------------------------
  clk_process : PROCESS
  BEGIN
    WHILE NOT done LOOP
      clk <= '0';
      WAIT FOR CLK_PERIOD / 2;
      clk <= '1';
      WAIT FOR CLK_PERIOD / 2;
    END LOOP;
    WAIT;
  END PROCESS;

  --------------------------------------------------------------------
  -- Instanciation du DUT
  --------------------------------------------------------------------
  DUT : ENTITY work.top_parking
    GENERIC MAP (
      MAX_PLACES => MAX_PLACES
    )
    PORT MAP (
      clk                   => clk,
      rst                   => rst,
      voiture_entree        => voiture_entree,
      voiture_sortie        => voiture_sortie,
      sensor_passage        => sensor_passage,
      sensor_open_limit     => sensor_open_limit,
      sensor_closed_limit   => sensor_closed_limit,
      motor_open            => motor_open,
      motor_close           => motor_close,
      cathode               => cathode,
      seg                   => seg
    );

  --------------------------------------------------------------------
  -- Process de monitoring
  --------------------------------------------------------------------
  monitoring : PROCESS(clk)
    VARIABLE prev_parking_full : STD_LOGIC := '0';
  BEGIN
    IF rising_edge(clk) THEN
      -- Calculer les places disponibles
      places_disponibles <= MAX_PLACES - nb_voitures_entrees + nb_voitures_sorties;
      
      -- Mise à jour des indicateurs
      IF places_disponibles = 0 THEN
        parking_full <= '1';
        parking_has_place <= '0';
      ELSE
        parking_full <= '0';
        parking_has_place <= '1';
      END IF;
      
      -- Afficher quand le parking devient plein
      IF parking_full = '1' AND prev_parking_full = '0' THEN
        REPORT "*** PARKING PLEIN ***" SEVERITY NOTE;
      END IF;
      
      prev_parking_full := parking_full;
    END IF;
  END PROCESS;

  --------------------------------------------------------------------
  -- Processus principal de test
  --------------------------------------------------------------------
  stimulus : PROCESS
  
    -- Procédure CORRIGÉE : Pulse d'UN SEUL cycle d'horloge
    PROCEDURE entree_voiture IS
    BEGIN
      REPORT ">>> Voiture arrive à l'entrée (Places: " & INTEGER'IMAGE(places_disponibles) & ")";
      
      -- Générer un pulse d'1 cycle d'horloge UNIQUEMENT
      WAIT UNTIL rising_edge(clk);
      voiture_entree <= '1';
      WAIT UNTIL rising_edge(clk);  -- 1 seul cycle
      voiture_entree <= '0';
      
      -- Attendre que motor_open s'active (quelques cycles)
      WAIT UNTIL motor_open = '1' FOR 500 ns;
      
      IF motor_open = '1' THEN
        -- Barrière autorise l'entrée
        REPORT "    Barrière s'ouvre";
        
        -- Attendre ouverture complète
        WAIT FOR 500 ns;
        sensor_closed_limit <= '0';
        sensor_open_limit <= '1';
        REPORT "    Barrière ouverte";
        
        -- Voiture passe sous la barrière (pulse d'1 cycle aussi)
        WAIT FOR 300 ns;
        WAIT UNTIL rising_edge(clk);
        sensor_passage <= '1';
        WAIT UNTIL rising_edge(clk);  -- 1 seul cycle
        sensor_passage <= '0';
        
        -- Incrémenter le compteur
        nb_voitures_entrees <= nb_voitures_entrees + 1;
        REPORT "    Voiture passée (Total entrées: " & INTEGER'IMAGE(nb_voitures_entrees + 1) & ")";
        
        -- Attendre que la barrière se ferme
        WAIT UNTIL motor_close = '1' FOR 1 us;
        WAIT FOR 500 ns;
        sensor_open_limit <= '0';
        sensor_closed_limit <= '1';
        REPORT "    Barrière refermée";
        WAIT FOR 200 ns;
        
      ELSE
        -- Parking plein - barrière reste fermée
        REPORT "    REFUS: Barrière reste fermée (parking plein)";
        nb_tentatives_refusees <= nb_tentatives_refusees + 1;
        WAIT FOR 500 ns;
      END IF;
    END PROCEDURE;

    -- Procédure CORRIGÉE pour sortie (pulse d'1 cycle)
    PROCEDURE sortie_voiture IS
    BEGIN
      REPORT "<<< Voiture demande à sortir";
      
      -- Pulse d'UN SEUL cycle
      WAIT UNTIL rising_edge(clk);
      voiture_sortie <= '1';
      WAIT UNTIL rising_edge(clk);  -- 1 seul cycle
      voiture_sortie <= '0';
      
      -- Attendre que motor_open s'active
      WAIT UNTIL motor_open = '1' FOR 500 ns;
      
      IF motor_open = '1' THEN
        -- Simuler ouverture
        WAIT FOR 500 ns;
        sensor_closed_limit <= '0';
        sensor_open_limit <= '1';
        
        -- Voiture passe (pulse d'1 cycle)
        WAIT FOR 300 ns;
        WAIT UNTIL rising_edge(clk);
        sensor_passage <= '1';
        WAIT UNTIL rising_edge(clk);  -- 1 seul cycle
        sensor_passage <= '0';
        
        -- Incrémenter compteur
        nb_voitures_sorties <= nb_voitures_sorties + 1;
        REPORT "    Voiture sortie (Total sorties: " & INTEGER'IMAGE(nb_voitures_sorties + 1) & ")";
        
        -- Fermeture
        WAIT UNTIL motor_close = '1' FOR 1 us;
        WAIT FOR 500 ns;
        sensor_open_limit <= '0';
        sensor_closed_limit <= '1';
        WAIT FOR 200 ns;
      ELSE
        REPORT "    ERREUR CRITIQUE: Barrière ne s'ouvre pas pour sortie!" SEVERITY ERROR;
        WAIT FOR 500 ns;
      END IF;
    END PROCEDURE;

  BEGIN
    REPORT "=================================================";
    REPORT "DEBUT DU TEST - Parking de " & INTEGER'IMAGE(MAX_PLACES) & " places";
    REPORT "=================================================";
    
    -- Reset initial
    rst <= '1';
    WAIT FOR 200 ns;
    rst <= '0';
    WAIT FOR 100 ns;
    
    REPORT " ";
    REPORT "=================================================";
    REPORT "PHASE 1: REMPLISSAGE COMPLET";
    REPORT "=================================================";
    FOR i IN 1 TO MAX_PLACES LOOP
      REPORT "--- Voiture " & INTEGER'IMAGE(i) & " ---";
      entree_voiture;
      WAIT FOR 100 ns;  -- Délai entre voitures
    END LOOP;
    
    REPORT " ";
    REPORT "=================================================";
    REPORT "PHASE 2: TENTATIVES AVEC PARKING PLEIN";
    REPORT "=================================================";
    FOR i IN 1 TO 2 LOOP
      REPORT "--- Tentative " & INTEGER'IMAGE(i) & " ---";
      entree_voiture;
      WAIT FOR 100 ns;
    END LOOP;
    
    REPORT " ";
    REPORT "=================================================";
    REPORT "PHASE 3: LIBERATION DE LA MOITIE";
    REPORT "=================================================";
    FOR i IN 1 TO (MAX_PLACES / 2) LOOP
      REPORT "--- Sortie " & INTEGER'IMAGE(i) & " ---";
      sortie_voiture;
      WAIT FOR 100 ns;
    END LOOP;
    
    REPORT " ";
    REPORT "=================================================";
    REPORT "PHASE 4: NOUVELLES ENTREES";
    REPORT "=================================================";
    FOR i IN 1 TO 2 LOOP
      REPORT "--- Nouvelle entrée " & INTEGER'IMAGE(i) & " ---";
      entree_voiture;
      WAIT FOR 100 ns;
    END LOOP;
    
    WAIT FOR 100 ns;
    done <= TRUE;
    WAIT;
  END PROCESS;

END ARCHITECTURE test;
