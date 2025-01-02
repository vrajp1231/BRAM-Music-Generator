----------------------------------------------------------------------------------
-- Engineer: Vraj Patel
-- Module Name: pwm_gen - Behavioral
-- Description: PWM Generator
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PWM_Generator is
    Port (
        clk         : in  std_logic;                 -- Input clock
        reset       : in  std_logic;                 -- Active-high reset
        audio_in  : in  std_logic_vector(9 downto 0); -- 10-bit audio sample input
        PWM_out     : out std_logic                 -- PWM output
    );
end PWM_Generator;

architecture Behavioral of PWM_Generator is

    signal pwm_counter : std_logic_vector(9 downto 0) := (others => '0'); -- 10-bit counter
    signal pwm_signal  : std_logic := '0';

begin

    -- Process to generate the PWM signal
    process(clk, reset)
    begin
        if reset = '1' then
            pwm_counter <= (others => '0');
            pwm_signal <= '0';
        elsif rising_edge(clk) then
            -- Increment the counter
            pwm_counter <= pwm_counter + 1;

            -- Compare the counter value with the audio sample
            if pwm_counter < audio_in then
                pwm_signal <= '1'; -- PWM high
            else
                pwm_signal <= '0'; -- PWM low
            end if;
        end if;
    end process;

    -- Assign the PWM signal to the output
    PWM_out <= pwm_signal;

end Behavioral;
