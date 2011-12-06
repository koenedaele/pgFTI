CREATE OR REPLACE FUNCTION FD_oudste() RETURNS float AS $$	
	SELECT -1000000.0::float;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_jongste() RETURNS float AS $$
	SELECT 100000.0::float;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_maakX(datum date) RETURNS float AS $$
DECLARE
	jaar int;
	laatste_dag_jaar date;
	aantal_dagen_in_jaar int;
BEGIN
	jaar := EXTRACT (year FROM $1);
	IF jaar < 0 THEN
		laatste_dag_jaar = (lpad(abs(jaar)::text,4,'0') || '-12-31 BC')::date;
		jaar := jaar + 1;
	ELSE
		laatste_dag_jaar = (lpad(abs(jaar)::text,4,'0') || '-12-31 AD')::date;
	END IF;
	aantal_dagen_in_jaar := EXTRACT(doy FROM (laatste_dag_jaar));
	RETURN jaar + ((EXTRACT(doy FROM $1) -1) / aantal_dagen_in_jaar);
END
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_maakVoorstelling(sa date, ka date, kb date, sb date) RETURNS geometry AS $$
	SELECT ST_MakeLine(ARRAY[ST_MakePoint(FD_maakX($1),0),
						ST_MakePoint(FD_maakX($2),1),
						ST_MakePoint(FD_maakX($3),1),
						ST_MakePoint(FD_maakX($4),0)]);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_maakVoorstelling(ka date, kb date) RETURNS geometry AS $$
	SELECT FD_S_maakVoorstelling($1,$1,$2,$2);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_maakVoorstelling(d date) RETURNS geometry AS $$
	SELECT FD_S_maakVoorstelling($1,$1,$1,$1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_vervaag(ka date, kb date, lv interval, rv interval) RETURNS geometry AS $$
	SELECT FD_S_maakVoorstelling(($1 - $3)::date, $1, $2, ($2 + $4)::date);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_vervaag(ka date, kb date, v interval) RETURNS geometry AS $$
	SELECT FD_s_vervaag($1,$2,$3,$3);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_vervaag(d date, v interval) RETURNS geometry AS $$
	SELECT FD_S_vervaag($1,$1,$2,$2);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_vervaag(d date, lv interval, rv interval) RETURNS geometry AS $$
	SELECT FD_S_vervaag($1,$1,$2,$3);
$$ LANGUAGE sql IMMUTABLE;
