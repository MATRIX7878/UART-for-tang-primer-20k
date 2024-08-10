LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ascii, hex : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
END ENTITY;

ARCHITECTURE behavior OF conv IS
SIGNAL flag : STD_LOGIC := '1';
SIGNAL temp : STD_LOGIC_VECTOR (7 DOWNTO 0);
BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            FOR i IN 0 TO 1 LOOP
                hex <= TO_STDLOGICVECTOR(48, 8) + char((7 - 4 * i) DOWNTO (4 - 4 * i)) WHEN char((7 - 4 * i) DOWNTO (4 - 4 * i)) <= 9 ELSE TO_STDLOGICVECTOR(55, 8) + char((7 - 4 * i) DOWNTO (4 - 4 * i));
            END LOOP;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF flag = '1' AND char > 0 THEN
                temp <= char;
                flag <= '0';
            ELSE
                WHILE temp >= 10 LOOP
                    temp <= temp / 10;
                    temp <= temp MOD 10;
                END LOOP;
            END IF;
            ascii <= temp + TO_STDLOGICVECTOR(48, 8);
        END IF;
    END PROCESS;
END ARCHITECTURE;