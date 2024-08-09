LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY toplevel IS
    PORT(clk, RST, RX : IN STD_LOGIC;
         TX : OUT STD_LOGIC
        );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE state IS (IDLE, RECEIVE, SEND);
SIGNAL currentState, nextState : state;

CONSTANT CR : STD_LOGIC_VECTOR := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR := x"7F"; --Delete

SIGNAL rx_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL rx_valid : STD_LOGIC;

SIGNAL tx_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL tx_ready : STD_LOGIC;
SIGNAL tx_valid : STD_LOGIC;

SIGNAL dataString : STRING (16 DOWNTO 1);
SIGNAL dataLogic : STD_LOGIC_VECTOR (127 DOWNTO 0);

COMPONENT UART_RX IS
    PORT(clk : IN  STD_LOGIC;
         reset : IN  STD_LOGIC;
         rx_IN : IN  STD_LOGIC;
         rx_valid : OUT STD_LOGIC;
         rx_data : OUT STD_LOGIC_VECTOR (7 downto 0)
         );
END COMPONENT;

COMPONENT UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 downto 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END COMPONENT;

IMPURE FUNCTION STR2SLV (str : STRING) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(str'LENGTH * 8 - 1 DOWNTO 0) ;
    BEGIN
    FOR i IN 1 TO str'HIGH LOOP
        data(i*8 - 1 DOWNTO (i-1) * 8) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

BEGIN
    uartrx : UART_RX PORT MAP (clk => clk, reset => RST, rx_IN => RX, rx_valid => rx_valid, rx_data => rx_data);
    uarttx : UART_TX PORT MAP (clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN IDLE => IF RX = '0' THEN
                nextState <= RECEIVE;
            END IF;
            WHEN RECEIVE => IF rx_valid <= '1' THEN
                    nextState <= SEND;
            END IF;
            WHEN SEND => tx_valid <= '1';
                tx_data <= rx_data;
                IF tx_ready = '1' AND tx_valid <= '1' AND RX = '1' THEN
                    tx_valid <= '0';
                    nextState <= IDLE;
                END IF;
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF RX = '0' THEN
                dataString <= "Input: ";
                dataLogic <= STR2SLV(dataString);
            END IF;
        END IF;
    END PROCESS;

    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            currentState <= nextState;
        END IF;
    END PROCESS;
END ARCHITECTURE;
