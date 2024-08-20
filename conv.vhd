LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.MATH_REAL.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ascii, hexLow, hexHigh : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE behavior OF conv IS
SIGNAL temp : INTEGER;

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
            FOR i IN 7 DOWNTO 0 LOOP
                temp <= 1 WHEN char(i) ELSE 0;
                ascii <= ascii + STD_LOGIC_VECTOR(TO_UNSIGNED(temp * (2 ** i), 8));
            END LOOP;
        END IF;
    END PROCESS;
END ARCHITECTURE;
