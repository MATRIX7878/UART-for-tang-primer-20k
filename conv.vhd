LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         hund, tens, ones, hexLow, hexHigh : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE behavior OF conv IS
TYPE state IS (START, ADD3, SHIFT, DONE);
SIGNAL currentState : state;

SIGNAL step : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
SIGNAL cache : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
SIGNAL digits : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');

SIGNAL temp1, temp2, temp3 : STD_LOGIC_VECTOR (11 DOWNTO 0);

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            hexLow <= char(7 DOWNTO 4) + TO_STDLOGICVECTOR(48, 8) WHEN char(7 DOWNTO 4) <= 9 ELSE char(7 DOWNTO 4) + TO_STDLOGICVECTOR(55, 8);
            hexHigh <= char(3 DOWNTO 0) + TO_STDLOGICVECTOR(48, 8) WHEN char(3 DOWNTO 0) <= 9 ELSE char(3 DOWNTO 0) + TO_STDLOGICVECTOR(55, 8);
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN START => cache <= char;
                step <= (OTHERS => '0');
                digits <= (OTHERS => '0');
                currentState <= ADD3;
            WHEN ADD3 => temp1 <= TO_STDLOGICVECTOR(3, 12) WHEN digits(3 DOWNTO 0) >= 5 ELSE (OTHERS => '0');
                temp2 <= TO_STDLOGICVECTOR(48, 12) WHEN digits(7 DOWNTO 4) >= 5 ELSE (OTHERS => '0');
                temp3 <= TO_STDLOGICVECTOR(768, 12) WHEN digits(11 DOWNTO 8) >= 5 ELSE (OTHERS => '0');
                digits <= digits + temp1 + temp2 + temp3;
                currentState <= SHIFT;
            WHEN SHIFT => digits <= digits(10 DOWNTO 0) & cache(7);
                cache <= cache(6 DOWNTO 0) & '0';
                IF step = 7 THEN
                    currentState <= DONE;
                ELSE
                    step <= step + '1';
                    currentState <= ADD3;
                END IF;
            WHEN DONE => hund <= TO_STDLOGICVECTOR(48, 8) + digits(11 DOWNTO 8);
                tens <= TO_STDLOGICVECTOR(48, 8) + digits(7 DOWNTO 4);
                ones <= TO_STDLOGICVECTOR(48, 8) + digits(3 DOWNTO 0);
                currentState <= START;
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;
