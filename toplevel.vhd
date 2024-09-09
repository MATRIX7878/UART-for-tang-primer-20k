LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY toplevel IS
    PORT(clk, RST, RX : IN STD_LOGIC;
         TX : OUT STD_LOGIC
        );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE state IS (IDLE, RECEIVE, SENDINPUT, SENDASCII, SENDHEX);
SIGNAL currentState, nextState : state;

CONSTANT CR : STD_LOGIC_VECTOR := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR := x"7F"; --Delete

SIGNAL rx_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL rx_valid : STD_LOGIC;

SIGNAL tx_data, tx_str : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL tx_ready : STD_LOGIC;
SIGNAL tx_valid : STD_LOGIC;

SIGNAL dataString : STRING (7 DOWNTO 1);
SIGNAL dataLogic : STD_LOGIC_VECTOR (55 DOWNTO 0);

SIGNAL counter : INTEGER := 0;
SIGNAL textCount : INTEGER := 0;

SIGNAL HUND, TENS, ONES : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL HEXLOW, HEXHIGH : STD_LOGIC_VECTOR (7 DOWNTO 0);

COMPONENT UART_RX IS
    PORT(clk : IN  STD_LOGIC;
         reset : IN  STD_LOGIC;
         rx_IN : IN  STD_LOGIC;
         rx_valid : OUT STD_LOGIC;
         rx_data : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
END COMPONENT;

COMPONENT UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END COMPONENT;

COMPONENT conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         hund, tens, ones, hexLow, hexHigh : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
END COMPONENT;

IMPURE FUNCTION BITSHIFT (input : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE output : STD_LOGIC_VECTOR(7 DOWNTO 0) := input;
    BEGIN
        output := output(6 DOWNTO 0) & output(7);
    RETURN output;
END FUNCTION;

IMPURE FUNCTION STR2SLV (str : STRING) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(55 DOWNTO 0) ;
    BEGIN
    FOR i IN str'HIGH DOWNTO 1 LOOP
        data(i * 8 - 1 DOWNTO i * 8 - 8) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN IDLE => IF RX = '0' THEN
                nextState <= RECEIVE;
            END IF;
            WHEN RECEIVE => IF rx_valid = '1' THEN
                tx_valid <= '1';
                nextState <= SENDINPUT;
            ELSIF tx_valid AND tx_ready THEN
                tx_valid <= '0';
            END IF;
            WHEN SENDINPUT => dataString <= "Input: ";
                dataLogic <= STR2SLV(dataString);
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND textCount < 6 THEN
                    IF counter /= 1 THEN
                        counter <= counter + 1;
                    ELSE
                        textCount <= textCount + 1;
                        counter <= 0;
                    END IF;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    textCount <= 0;
                    nextState <= SENDASCII;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN SENDASCII => dataString <= "ASCII: ";
                dataLogic <= STR2SLV(dataString);
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND textCount < 6 THEN
                    IF counter /= 1 THEN
                        counter <= counter + 1;
                    ELSE
                        textCount <= textCount + 1;
                        counter <= 0;
                    END IF;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    textCount <= 0;
                    nextState <= SENDHEX;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN SENDHEX => dataString <= "Hex: 0x";
                dataLogic <= STR2SLV(dataString);
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND textCount < 6 THEN
                    IF counter /= 1 THEN
                        counter <= counter + 1;
                    ELSE
                        textCount <= textCount + 1;
                        counter <= 0;
                    END IF;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    textCount <= 0;
                    nextState <= IDLE;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            tx_str <= dataLogic(55 - textCount * 8 DOWNTO 48 - textCount * 8);
            currentState <= nextState;
        END IF;
    END PROCESS;

    uartrx : UART_RX PORT MAP (clk => clk, reset => RST, rx_IN => RX, rx_valid => rx_valid, rx_data => rx_data);
    uarttx : UART_TX PORT MAP (clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);
    change : conv PORT MAP (clk => clk, char => rx_data, hund => HUND, tens => TENS, ones => ONES, hexLow => HEXLOW, hexHigh => HEXHIGH);

END ARCHITECTURE;
