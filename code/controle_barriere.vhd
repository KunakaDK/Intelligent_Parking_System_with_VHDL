LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Entité du module de contrôle de la barrière

ENTITY controle_barriere IS
  PORT (
    -- Signaux de contrôle
    clk   : IN  STD_LOGIC; -- Horloge (pour la logique séquentielle)
    rst   : IN  STD_LOGIC; -- Reset asynchrone (pour initialiser)

    -- Entrées (capteurs et commandes)
    trigger_open        : IN  STD_LOGIC; -- Ordre d'ouverture (vient du module principal)
    sensor_passage      : IN  STD_LOGIC; -- Capteur: la voiture est passée
    sensor_open_limit   : IN  STD_LOGIC; -- Capteur: la barrière est en position haute
    sensor_closed_limit : IN  STD_LOGIC; -- Capteur: la barrière est en position basse

    -- Sorties (commandes moteur)
    motor_open  : OUT STD_LOGIC; -- Commande au moteur: Ouvrir
    motor_close : OUT STD_LOGIC  -- Commande au moteur: Fermer
  );
END ENTITY controle_barriere;


-- Architecture 
-- Nous utilisons une machine à états (FSM)

ARCHITECTURE fsm OF controle_barriere IS

  -- 1. Définition des états de notre FSM
  TYPE state_type IS (
    IDLE_CLOSED, -- La barrière est fermée et attend
    OPENING,     -- La barrière est en train de s'ouvrir
    IDLE_OPEN,   -- La barrière est ouverte et attend le passage
    CLOSING      -- La barrière est en train de se fermer
  );

  -- 2. Signal interne pour mémoriser l'état actuel et le prochain état
  SIGNAL state, next_state : state_type;

BEGIN

  -- PROCESS 1: Logique Séquentielle (Registre d'état)
  -- Ce process mémorise l'état actuel.
  -- Il est sensible au 'clk' et au 'rst', comme la bascule D (DFF)
  state_register_proc : PROCESS (clk, rst)
  BEGIN
    IF (rst = '1') THEN
      state <= IDLE_CLOSED; -- État initial de reset
    ELSIF (clk'EVENT AND clk = '1') THEN -- Détection du front montant 
      state <= next_state; -- Mémorisation du prochain état
    END IF;
  END PROCESS state_register_proc;


  -- PROCESS 2: Logique Combinatoire (Calcul du prochain état)
  -- Ce process calcule l'état suivant en fonction de l'état
  -- actuel et des entrées (capteurs).
  next_state_logic_proc : PROCESS (state, trigger_open, sensor_passage, sensor_open_limit, sensor_closed_limit)
  BEGIN
    -- Par défaut, on reste dans le même état
    next_state <= state; 

    CASE state IS
      -- État 1: Barrière fermée
      WHEN IDLE_CLOSED =>
        IF (trigger_open = '1') THEN
          next_state <= OPENING; -- On passe à l'ouverture
        END IF;

      -- État 2: Barrière en ouverture
      WHEN OPENING =>
        IF (sensor_open_limit = '1') THEN
          next_state <= IDLE_OPEN; -- On est arrivé en haut
        END IF;

      -- État 3: Barrière ouverte
      WHEN IDLE_OPEN =>
        IF (sensor_passage = '1') THEN
          next_state <= CLOSING; -- La voiture est passée, on ferme
        END IF;

      -- État 4: Barrière en fermeture
      WHEN CLOSING =>
        IF (sensor_closed_limit = '1') THEN
          next_state <= IDLE_CLOSED; -- On est arrivé en bas, retour à l'état initial
        END IF;

      -- Cas par défaut (sécurité)
      WHEN OTHERS =>
        next_state <= IDLE_CLOSED;

    END CASE;
  END PROCESS next_state_logic_proc;


  -- PROCESS 3: Logique Combinatoire (Logique de sortie)
  -- Ce process détermine les sorties (commandes moteur)
  -- en fonction de l'état actuel.
  output_logic_proc : PROCESS (state)
  BEGIN
    -- Valeurs par défaut pour éviter les "latches"
    motor_open  <= '0';
    motor_close <= '0';

    CASE state IS
      WHEN IDLE_CLOSED =>
        motor_open  <= '0';
        motor_close <= '0';
      
      WHEN OPENING =>
        motor_open  <= '1'; -- On active le moteur pour ouvrir
        motor_close <= '0';
      
      WHEN IDLE_OPEN =>
        motor_open  <= '0';
        motor_close <= '0';
      
      WHEN CLOSING =>
        motor_open  <= '0';
        motor_close <= '1'; -- On active le moteur pour fermer
      
      WHEN OTHERS =>
        motor_open  <= '0';
        motor_close <= '0';
        
    END CASE;
  END PROCESS output_logic_proc;

END ARCHITECTURE fsm;
