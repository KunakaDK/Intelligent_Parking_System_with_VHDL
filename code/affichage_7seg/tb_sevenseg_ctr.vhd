library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sevenseg_ctrl is
end tb_sevenseg_ctrl;

architecture sim of tb_sevenseg_ctrl is

    signal clk_tb      : STD_LOGIC := '0';
    signal reset_n_tb  : STD_LOGIC := '0';
    signal count_in_tb : UNSIGNED(13 downto 0) := (others => '0');
    signal an_tb       : STD_LOGIC_VECTOR(3 downto 0);
    signal seg_tb      : STD_LOGIC_VECTOR(6 downto 0);

begin

    --------------------------------------------------------------------
    -- Instanciation du module Display
    --------------------------------------------------------------------
    dut : entity work.sevenseg_ctrl
        port map (
            clk      => clk_tb,
            reset_n  => reset_n_tb,
            count_in => count_in_tb,
            an       => an_tb,
            seg      => seg_tb
        );

    --------------------------------------------------------------------
    -- Horloge 50 MHz (période 20 ns)
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk_tb <= '0';
        wait for 10 ns;
        clk_tb <= '1';
        wait for 10 ns;
    end process;

    --------------------------------------------------------------------
    -- Stimuli
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- Reset
        reset_n_tb <= '0';
        wait for 100 ns;
        reset_n_tb <= '1';

        -- Valeurs à tester
        count_in_tb <= to_unsigned(0, 14);
        wait for 2 ms;

        count_in_tb <= to_unsigned(7, 14);
        wait for 2 ms;

        count_in_tb <= to_unsigned(12, 14);
        wait for 2 ms;

        count_in_tb <= to_unsigned(105, 14);
        wait for 2 ms;

        count_in_tb <= to_unsigned(9999, 14);
        wait for 2 ms;

        wait;
    end process;

end sim;

