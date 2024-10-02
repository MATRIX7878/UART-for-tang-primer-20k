LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY toplevel IS
    PORT(clk, RST, RX : IN STD_LOGIC;
         TX : OUT STD_LOGIC
        );
END ENTITY;

ARCHITECTURE behavior OF toplevel IS
TYPE state IS (IDLE, RECEIVE, SENDINPUT, INPUT, SENDASCII, ASCII, SENDHEX, HEX);
SIGNAL currentState : state := IDLE;

CONSTANT CR : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"7F"; --Delete

SIGNAL rx_data : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL rx_valid : STD_LOGIC;
SIGNAL rx_ready : STD_LOGIC;

SIGNAL tx_data, tx_str, tx_in, tx_asc, tx_hex : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL tx_ready : STD_LOGIC;
SIGNAL tx_valid : STD_LOGIC;

SIGNAL dataString : STRING (7 DOWNTO 1);
SIGNAL dataLogic : STD_LOGIC_VECTOR (55 DOWNTO 0);

SIGNAL dataInput : STD_LOGIC_VECTOR (23 DOWNTO 0);
SIGNAL dataAscii : STD_LOGIC_VECTOR (39 DOWNTO 0);
SIGNAL dataHex : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL strCount : INTEGER := 0;
SIGNAL inCount : INTEGER := 0;
SIGNAL asCount : INTEGER := 0;
SIGNAL hexCount : INTEGER := 0;

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
    VARIABLE output : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        FOR i IN 0 TO 7 LOOP
            output(i) := input(7 - i);
        END LOOP;
    RETURN output;
END FUNCTION;

IMPURE FUNCTION STR2SLV (str : STRING) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(55 DOWNTO 0);
    BEGIN
    FOR i IN 7 DOWNTO 1 LOOP
        data(i * 8 - 1 DOWNTO i * 8 - 8) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN IDLE => IF NOT RX THEN
                currentState <= RECEIVE;
            END IF;
            WHEN RECEIVE => IF rx_valid THEN
                tx_valid <= '1';
                currentState <= SENDINPUT;
            END IF;
            WHEN SENDINPUT => dataString <= "Input: ";
                dataLogic <= STR2SLV(dataString);
                tx_data <= BITSHIFT(tx_str);
                IF tx_valid = '1' AND tx_ready = '1' AND strCount < 6 THEN
                    strCount <= strCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    strCount <= 0;
                    currentState <= INPUT;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN INPUT => dataInput(23 DOWNTO 0) <= rx_data & CR & LF;
                IF inCount = 0 THEN
                    tx_data <= tx_in;
                ELSE
                    tx_data <= BITSHIFT(tx_in);
                END IF;
                IF tx_valid = '1' AND tx_ready = '1' AND inCount < 2 THEN
                    inCount <= inCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    inCount <= 0;
                    currentState <= SENDASCII;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN SENDASCII => dataString <= "Ascii: ";
                dataLogic <= STR2SLV(dataString);
                tx_data <= BITSHIFT(tx_str);
                IF tx_valid = '1' AND tx_ready = '1' AND strCount < 6 THEN
                    strCount <= strCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    strCount <= 0;
                    currentState <= ASCII;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN ASCII => dataAscii(39 DOWNTO 32) <= HUND;
                dataAscii(31 DOWNTO 24) <= TENS;
                dataAscii(23 DOWNTO 16) <= ONES;
                dataAscii(15 DOWNTO 0) <= CR & LF;
                tx_data <= BITSHIFT(tx_asc);
                IF tx_valid = '1' AND tx_ready = '1' AND asCount < 4 THEN
                    asCount <= asCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    asCount <= 0;
                    currentState <= SENDHEX;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN SENDHEX => dataString <= "Hex: 0x";
                dataLogic <= STR2SLV(dataString);
                tx_data <= BITSHIFT(tx_str);
                IF tx_valid = '1' AND tx_ready = '1' AND strCount < 6 THEN
                    strCount <= strCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    strCount <= 0;
                    currentState <= HEX;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN HEX => dataHex(31 DOWNTO 24) <= HEXHIGH;
                dataHex(23 DOWNTO 16) <= HEXLOW;
                dataHex(15 DOWNTO 0) <= CR & LF;
                tx_data <= BITSHIFT(tx_hex);
                IF tx_valid = '1' AND tx_ready = '1' AND hexCount < 3 THEN
                    hexCount <= hexCount + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    hexCount <= 0;
                    currentState <= IDLE;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            tx_str <= dataLogic(55 - strCount * 8 DOWNTO 48 - strCount * 8);
            tx_in <= dataInput(23 - inCount * 8 DOWNTO 16 - inCount * 8);
            tx_asc <= dataAscii(39 - asCount * 8 DOWNTO 32 - asCount * 8);
            tx_hex <= dataHex(31 - hexCount * 8 DOWNTO 24 - hexCount * 8);
        END IF;
    END PROCESS;

    uartrx : UART_RX PORT MAP (clk => clk, reset => RST, rx_IN => RX, rx_valid => rx_valid, rx_data => rx_data);
    uarttx : UART_TX PORT MAP (clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);
    change : conv PORT MAP (clk => clk, char => rx_data, hund => HUND, tens => TENS, ones => ONES, hexLow => HEXLOW, hexHigh => HEXHIGH);

END ARCHITECTURE;
