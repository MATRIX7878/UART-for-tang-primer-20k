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
TYPE part IS (INTS, BASE, HUN, TEN, ONE);
SIGNAL currentPart : part;

TYPE bits IS ARRAY (0 TO 7) OF INTEGER RANGE 0 TO 1;
SIGNAL int : bits;

SIGNAL cache : INTEGER RANGE 0 TO 255;
SIGNAL downup : STD_LOGIC_VECTOR (7 DOWNTO 0);

IMPURE FUNCTION UPDOWN (var : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
VARIABLE switch : STD_LOGIC_VECTOR (7 DOWNTO 0);
BEGIN
    FOR i IN 0 TO 7 LOOP
        switch(i) := var(7 - i);
    END LOOP;
    RETURN switch;
END FUNCTION;

BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            downup <= UPDOWN(char);
            hexHigh <= downup(7 DOWNTO 4) + TO_STDLOGICVECTOR(48, 8) WHEN downup(7 DOWNTO 4) <= 9 ELSE downup(7 DOWNTO 4) + TO_STDLOGICVECTOR(55, 8);
            hexLow <= downup(3 DOWNTO 0) + TO_STDLOGICVECTOR(48, 8) WHEN downup(3 DOWNTO 0) <= 9 ELSE downup(3 DOWNTO 0) + TO_STDLOGICVECTOR(55, 8);
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
			CASE currentPart IS
            WHEN INTS => FOR i IN 0 TO 7 LOOP
				int(i) <= 1 WHEN char(i) ELSE 0;
			END LOOP;
                currentPart <= BASE;
            WHEN BASE => cache <= int(0) * 128 + int(1) * 64 + int(2) * 32 + int(3) * 16 + int(4) * 8 + int(5) * 4 + int(6) * 2 + int(7) * 1;
                currentPart <= HUN;
			WHEN HUN => IF cache >= 100 THEN
				hund <= TO_STDLOGICVECTOR(48, 8) + "1";
				cache <= cache - 100;
			ELSE
				hund <= TO_STDLOGICVECTOR(48, 8);
			END IF;
			currentPart <= TEN;
			WHEN TEN => IF cache >= 90 AND cache <= 99 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"9";
				cache <= cache - 90;
			ELSIF cache >= 80 AND cache <= 89 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"8";
				cache <= cache - 80;
			ELSIF cache >= 70 AND cache <= 79 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"7";
				cache <= cache - 70;
			ELSIF cache >= 60 AND cache <= 69 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"6";
				cache <= cache - 60;
			ELSIF cache >= 50 AND cache <= 59 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"5";
				cache <= cache - 50;
			ELSIF cache >= 40 AND cache <= 49 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"4";
				cache <= cache - 40;
			ELSIF cache >= 30 AND cache <= 39 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"3";
				cache <= cache - 30;
			ELSIF cache >= 20 AND cache <= 29 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + d"2";
				cache <= cache - 20;
			ELSIF cache >= 10 AND cache <= 19 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + "1";
				cache <= cache - 10;
			ELSE
				tens <= TO_STDLOGICVECTOR(48, 8);
			END IF;
			currentPart <= ONE;
			WHEN ONE =>	ones <= TO_STDLOGICVECTOR(48, 8) + TO_STDLOGICVECTOR(cache, 4);
				currentPart <= INTS;
			END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;
