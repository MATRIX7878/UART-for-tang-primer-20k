LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END UART_TX;

ARCHITECTURE Behavior OF UART_TX IS
TYPE state IS (IDLE, START, SEND, STOP);
SIGNAL currentState : state;

CONSTANT BAUD : STD_LOGIC_VECTOR (7 DOWNTO 0) := d"234";

SIGNAL bits : INTEGER RANGE 7 DOWNTO 0 := 7;
SIGNAL counter : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF NOT reset THEN
                CASE currentState IS
                WHEN IDLE => IF tx_valid = '1' THEN
                    tx_ready <= '0';
                    tx_OUT <= '1';
                    currentState <= START;
                END IF;
                WHEN START => IF counter = BAUD THEN
                    tx_OUT <= '0';
                    counter <= (OTHERS => '0');
                    currentState <= SEND;
                ELSE
                    counter <= counter + '1';
                END IF;
                WHEN SEND => IF counter = BAUD AND bits = 0 THEN
                    tx_OUT <= tx_data(bits);    
                    counter <= (OTHERS => '0');
                    currentState <= STOP;
                ELSIF counter = BAUD AND bits > 0 THEN
                    tx_OUT <= tx_data(bits);
                    counter <= (OTHERS => '0');
                    bits <= bits - 1;
                ELSE
                    counter <= counter + '1';
                END IF;
                WHEN STOP => IF counter = BAUD THEN
                    bits <= 7;
                    tx_ready <= '1';
                    tx_OUT <= '1';
                    counter <= (OTHERS => '0');
                    currentState <= IDLE;
                ELSE
                    counter <= counter + '1';
                END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY UART_RX IS
    PORT(clk : IN  STD_LOGIC;
         reset : IN  STD_LOGIC;
         rx_IN : IN  STD_LOGIC;
         rx_valid : OUT STD_LOGIC;
         rx_data : OUT STD_LOGIC_VECTOR (7 downto 0)
         );
END UART_RX;

ARCHITECTURE Behavior OF UART_RX IS
TYPE state IS (IDLE, START, RECEIVE, STOP);
SIGNAL currentState : state;

CONSTANT BAUD : STD_LOGIC_VECTOR (7 DOWNTO 0) := d"234";

SIGNAL bits : INTEGER RANGE 7 DOWNTO 0 := 7;
SIGNAL counter : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF NOT reset THEN
                CASE currentState IS
                WHEN IDLE => IF NOT rx_In THEN
                    rx_valid <= '0';
                    currentState <= START;
                END IF;
                WHEN START => IF counter = BAUD / 2 THEN
                    counter <= (OTHERS => '0');
                    currentState <= RECEIVE;
                ELSE
                    counter <= counter + '1';
                END IF;
                WHEN RECEIVE => IF counter = BAUD AND bits = 0 THEN
                    rx_data(bits) <= rx_IN;
                    counter <= (OTHERS => '0');
                    currentState <= STOP;
                ELSIF counter = BAUD AND bits > 0 THEN
                    rx_data(bits) <= rx_IN;
                    counter <= (OTHERS => '0');
                    bits <= bits - 1;
                ELSE
                    counter <= counter + '1';
                END IF;
                WHEN STOP => IF counter = BAUD / 2 - '1' THEN
                    bits <= 7;
                    rx_valid <= '1';
                    counter <= (OTHERS => '0');
                    currentState <= IDLE;
                ELSE
                    counter <= counter + '1';
                END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;
END ARCHITECTURE;
