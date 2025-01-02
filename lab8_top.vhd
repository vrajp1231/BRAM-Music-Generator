----------------------------------------------------------------------------------
-- Engineer: Vraj Patel
-- Module Name: lab8_top - Behavioral
-- Description: Lab 8 Top Module
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity lab8_top is
    Port (
        CLK100MHZ    : in std_logic;                     -- 100MHz system clock
        BTNR         : in std_logic;                     -- Active-high reset
        SW           : in std_logic_vector(15 downto 0); -- Switches
        BTNC         : in std_logic;                     -- Center pushbutton (playback)
        BTNU         : in std_logic;                     -- Up pushbutton (load data)
        AUD_PWM      : out std_logic;                    -- PWM output to audio jack
        AUD_SD       : out std_logic;                    -- Audio Output on/off
        LED          : out std_logic_vector(1 downto 0); -- LEDs
        UART_TXD_IN  : in std_logic;                     -- UART RX (receive)
        UART_RXD_OUT : out std_logic                     -- UART TX (transmit)
    );
end lab8_top;

architecture Behavioral of lab8_top is

    -- Signal declarations
    signal ena       : std_logic := '1';                      -- Enable BRAM
    signal wea       : std_logic_vector(0 downto 0) := "0";   -- Write enable
    signal addra     : std_logic_vector(18 downto 0);         -- BRAM address
    signal dina      : std_logic_vector(9 downto 0);          -- BRAM input data
    signal douta     : std_logic_vector(9 downto 0);          -- BRAM output data
    signal music_data: std_logic_vector(9 downto 0);          -- Data from serial
    signal load_music_sample : std_logic;                     -- Load trigger
    signal new_music_data    : std_logic;                     -- Data ready signal
    signal playback_en       : std_logic;                     -- Playback enable
    signal pwm_input         : std_logic_vector(9 downto 0);  -- PWM input
    signal clk_44k1          : std_logic;                     -- 44.1kHz clock
    signal playback_addr     : integer := 0;                  -- Playback address
    signal playback_cycles   : unsigned(1 downto 0);          -- Playback cycles

    component blk_mem_gen_0
        port (
            clka  : in std_logic;
            ena   : in std_logic;
            wea   : in std_logic_vector(0 downto 0);
            addra : in std_logic_vector(18 downto 0);
            dina  : in std_logic_vector(9 downto 0);
            douta : out std_logic_vector(9 downto 0) 
        ); 
    end component;

    -- 44.1kHz Clock Divider signals
    signal clk_div_counter : integer := 0;
    constant CLK_DIV_COUNT : integer := 1134; -- 100MHz / 44.1kHz / 2

begin

    -- BRAM instantiation
    bram_inst: blk_mem_gen_0
        port map (
            clka  => CLK100MHZ,
            ena   => ena,
            wea   => wea,
            addra => addra,
            dina  => dina,
            douta => douta
        );

    -- USB-to-Serial instantiation
    usb_serial_inst: entity work.usb_music_serial
        port map (
            clk             => CLK100MHZ,
            reset           => BTNR,
            UART_TXD_IN     => UART_TXD_IN,
            UART_RXD_OUT    => UART_RXD_OUT,
            load_music_sample => load_music_sample,
            new_music_data  => new_music_data,
            music_data      => music_data
        );

    -- PWM Generator instantiation
    pwm_gen_inst: entity work.PWM_Generator
        port map (
            clk    => CLK100MHZ,
            reset  => BTNR,
            audio_in   => pwm_input,
            PWM_out => AUD_PWM
        );

    -- 44.1kHz Clock Divider
    process(CLK100MHZ, BTNR)
    begin
        if BTNR = '1' then
            clk_div_counter <= 0;
            clk_44k1 <= '0';
        elsif rising_edge(CLK100MHZ) then
            if clk_div_counter = CLK_DIV_COUNT then
                clk_44k1 <= not clk_44k1;
                clk_div_counter <= 0;
            else
                clk_div_counter <= clk_div_counter + 1;
            end if;
        end if;
    end process;

    -- Control Logic
    process(clk_44k1, BTNR)
    begin
        if BTNR = '1' then
            playback_en <= '0';
            addra       <= (others => '0');
            wea         <= "0";
            LED         <= (others => '0');
            playback_addr <= 0;
            playback_cycles <= (others => '0');
        elsif rising_edge(clk_44k1) then
            -- Playback Logic
            if BTNC = '1' then
                playback_en <= '1';
                playback_cycles <= unsigned(SW(1 downto 0));
            end if;

            if playback_en = '1' then
                if playback_addr = 264600 then
                    playback_addr <= 0;
                    if playback_cycles = 1 then
                        playback_en <= '0';
                    else
                        playback_cycles <= playback_cycles - 1;
                        if playback_cycles = 1 then
                            playback_en <= '0';
                        end if;
                    end if;
                else
                    addra <= std_logic_vector(to_unsigned(playback_addr, 19));
                    playback_addr <= playback_addr + 1;
                end if;
            end if;

            -- Data Loading Logic
            if BTNU = '1' then
                LED(0) <= '1';
                LED(1) <= '0';
                load_music_sample <= '1';
                if new_music_data = '1' then
                    addra <= std_logic_vector(to_unsigned(playback_addr, 19));
                    dina <= music_data;
                    wea <= "1";
                    playback_addr <= playback_addr + 1;
                    if playback_addr = 264600 then
                        wea <= "0";
                        playback_addr <= 0;
                        LED(0) <= '0';
                        LED(1) <= '1';
                    end if;
                end if;
            else
                load_music_sample <= '0';
            end if;

            if UART_TXD_IN = '1' then 
                LED(0) <= '1';  LED(1) <= '0'; 
            else 
                LED(0) <= '0';  LED(1) <= '1';
            end if;
            
            pwm_input <= douta;
        end if;
    end process;
    
    -- Output on/off
    AUD_SD <= SW(15);
    
end Behavioral;

