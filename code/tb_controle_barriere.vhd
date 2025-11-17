LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- L'entité du testbench
ENTITY tb_controle_barriere IS
END ENTITY tb_controle_barriere;


ARCHITECTURE test OF tb_controle_barriere IS

  -- 1. Déclarer le composant à tester (votre module)
  COMPONENT controle_barriere
    PORT (
      clk                   : IN  STD_LOGIC;
      rst                   : IN  STD_LOGIC;
      trigger_open        : IN  STD_LOGIC;
      sensor_passage      : IN  STD_LOGIC;
      sensor_open_limit   : IN  STD_LOGIC;
      sensor_closed_limit : IN  STD_LOGIC;
      motor_open          : OUT STD_LOGIC;
      motor_close         : OUT STD_LOGIC
    );
  END COMPONENT;

  -- 2. Créer les signaux pour se connecter au composant
  -- Signaux d'entrée (stimuli)
  SIGNAL s_clk                 : STD_LOGIC := '0';
  SIGNAL s_rst                 : STD_LOGIC;
  SIGNAL s_trigger_open        : STD_LOGIC := '0';
  SIGNAL s_sensor_passage      : STD_LOGIC := '0';
  SIGNAL s_sensor_open_limit   : STD_LOGIC := '0';
  SIGNAL s_sensor_closed_limit : STD_LOGIC := '0';

  -- Signaux de sortie (observation)
  SIGNAL s_motor_open  : STD_LOGIC;
  SIGNAL s_motor_close : STD_LOGIC;

  -- Période d'horloge
  CONSTANT CLK_PERIOD : TIME := 10 ns; -- Horloge de 100 MHz

BEGIN

  -- 3. Instancier le DUT (Device Under Test)
  -- On connecte les signaux du testbench aux ports du module
  DUT : controle_barriere
    PORT MAP (
      clk                   => s_clk,
      rst                   => s_rst,
      trigger_open        => s_trigger_open,
      sensor_passage      => s_sensor_passage,
      sensor_open_limit   => s_sensor_open_limit,
      sensor_closed_limit => s_sensor_closed_limit,
      motor_open          => s_motor_open,
      motor_close         => s_motor_close
    );

  -- 4. Générateur d'horloge 
  clk_gen_proc : PROCESS
  BEGIN
    s_clk <= '0';
    WAIT FOR CLK_PERIOD / 2;
    s_clk <= '1';
    WAIT FOR CLK_PERIOD / 2;
  END PROCESS clk_gen_proc;


  -- 5. Processus de simulation (scénario de test)
  stimulus_proc : PROCESS
  BEGIN
    -- == PHASE 1: RESET ==
    s_rst <= '1'; -- Appliquer le reset
    WAIT FOR 20 ns;
    s_rst <= '0'; -- Relâcher le reset
    WAIT FOR 10 ns;
    -- À ce stade, la FSM doit être dans l'état IDLE_CLOSED
    -- et les moteurs doivent être à '0'.

    -- == PHASE 2: SCÉNARIO D'OUVERTURE ==
    s_trigger_open <= '1'; -- Le module principal demande l'ouverture
    WAIT FOR CLK_PERIOD;
    s_trigger_open <= '0'; -- L'ordre est une impulsion
    
    -- La FSM doit passer à OPENING. s_motor_open doit passer à '1'.
    WAIT FOR 50 ns; -- Simule le temps que prend la barrière pour s'ouvrir

    -- Le capteur de limite haute est atteint
    s_sensor_open_limit <= '1';
    WAIT FOR CLK_PERIOD;
    s_sensor_open_limit <= '0';
    
    -- La FSM doit passer à IDLE_OPEN. Les moteurs doivent s'arrêter.
    WAIT FOR 100 ns; -- Simule la voiture qui passe sous la barrière

    -- == PHASE 3: SCÉNARIO DE FERMETURE ==
    -- La voiture a activé le capteur de passage
    s_sensor_passage <= '1';
    WAIT FOR CLK_PERIOD;
    s_sensor_passage <= '0';

    -- La FSM doit passer à CLOSING. s_motor_close doit passer à '1'.
    WAIT FOR 50 ns; -- Simule le temps que prend la barrière pour se fermer

    -- Le capteur de limite basse est atteint
    s_sensor_closed_limit <= '1';
    WAIT FOR CLK_PERIOD;
    s_sensor_closed_limit <= '0';
    
    -- La FSM doit revenir à IDLE_CLOSED. Les moteurs doivent s'arrêter.

    -- == FIN DE LA SIMULATION ==
    WAIT; 
  END PROCESS stimulus_proc;

END ARCHITECTURE test;
