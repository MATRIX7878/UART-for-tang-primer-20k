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

TYPE part IS (HUN, TEN, ONE);
SIGNAL currentPart : part;

SIGNAL int : INTEGER;

SIGNAL step : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
SIGNAL cache, downup : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
SIGNAL digits : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');

SIGNAL temp1, temp2, temp3 : STD_LOGIC_VECTOR (11 DOWNTO 0);

IMPURE FUNCTION UPDOWN (var : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
VARIABLE switch : STD_LOGIC_VECTOR (7 DOWNTO 0);
BEGIN
    FOR i IN 0 TO 7 LOOP
        switch(i) := var(7 - i);
    END LOOP;
    RETURN switch;
END FUNCTION;

IMPURE FUNCTION POW (raise : INTEGER) RETURN INTEGER IS
VARIABLE power : INTEGER := 1;
BEGIN
	IF raise = 0 THEN
		power := 1;
	ELSE
		FOR i IN 1 TO raise LOOP
			power := 2 * power;
		END LOOP;
	END IF;
	RETURN power;
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
--            CASE currentState IS
--            WHEN START => cache <= char;
--                step <= (OTHERS => '0');
--                digits <= (OTHERS => '0');
--                currentState <= ADD3;
--            WHEN ADD3 => temp1 <= TO_STDLOGICVECTOR(3, 12) WHEN digits(3 DOWNTO 0) >= 5 ELSE (OTHERS => '0');
--                temp2 <= TO_STDLOGICVECTOR(48, 12) WHEN digits(7 DOWNTO 4) >= 5 ELSE (OTHERS => '0');
--                temp3 <= TO_STDLOGICVECTOR(768, 12) WHEN digits(11 DOWNTO 8) >= 5 ELSE (OTHERS => '0');
--                digits <= digits + temp1 + temp2 + temp3;
--                currentState <= SHIFT;
--            WHEN SHIFT => digits <= digits(10 DOWNTO 0) & cache(7);
--                cache <= cache(6 DOWNTO 0) & '0';
--                IF step = 7 THEN
--                    currentState <= DONE;
--                ELSE
--                    step <= step + '1';
--                    currentState <= ADD3;
--                END IF;
--            WHEN DONE => hund <= TO_STDLOGICVECTOR(48, 8) + digits(11 DOWNTO 8);
--                tens <= TO_STDLOGICVECTOR(48, 8) + digits(7 DOWNTO 4);
--                ones <= TO_STDLOGICVECTOR(48, 8) + digits(3 DOWNTO 0);
--                currentState <= START;
--            END CASE;
			FOR i IN 0 TO 7 LOOP
				int <= 1 WHEN char(i) ELSE 0;
				cache <= TO_STDLOGICVECTOR(int * POW(i), 8);
			END LOOP;

			CASE currentPart IS
			WHEN HUN => IF cache > 99 THEN
				hund <= TO_STDLOGICVECTOR(48, 8) + 1;
				cache <= cache - 100;
			ELSE
				hund <= TO_STDLOGICVECTOR(48, 8);
			END IF;
			currentPart <= TEN;
			WHEN TEN => IF cache >= 90 AND cache <= 99 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 9;
				cache <= cache - 90;
			ELSIF cache >= 80 AND cache <= 89 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 8;
				cache <= cache - 80;
			ELSIF cache >= 70 AND cache <= 79 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 7;
				cache <= cache - 70;
			ELSIF cache >= 60 AND cache <= 69 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 6;
				cache <= cache - 60;
			ELSIF cache >= 50 AND cache <= 59 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 5;
				cache <= cache - 50;
			ELSIF cache >= 40 AND cache <= 49 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 4;
				cache <= cache - 40;
			ELSIF cache >= 30 AND cache <= 39 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 3;
				cache <= cache - 30;
			ELSIF cache >= 20 AND cache <= 29 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 2;
				cache <= cache - 20;
			ELSIF cache >= 10 AND cache <= 19 THEN
				tens <= TO_STDLOGICVECTOR(48, 8) + 1;
				cache <= cache - 10;
			ELSE
				tens <= TO_STDLOGICVECTOR(48, 8);
			END IF;
			currentPart <= ONE;
			WHEN ONE =>	ones <= TO_STDLOGICVECTOR(48, 8) + cache;
				currentPart <= HUN;
			END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;
