CREATE OR REPLACE FUNCTION FD_oldest() RETURNS float AS $$	
	SELECT -1000000.0::float;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_youngest() RETURNS float AS $$
	SELECT 100000.0::float;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_makeX(datum date) RETURNS float AS $$
DECLARE
	year int;
	last_day_of_year date;
	nr_of_days_in_year int;
BEGIN
	year := EXTRACT (year FROM $1);
	IF year < 0 THEN
		last_day_of_year = (lpad(abs(year)::text,4,'0') || '-12-31 BC')::date;
		year := jaar + 1;
	ELSE
		last_day_of_year = (lpad(abs(year)::text,4,'0') || '-12-31 AD')::date;
	END IF;
	nr_of_days_in_year := EXTRACT(doy FROM (last_day_of_year));
	RETURN year + ((EXTRACT(doy FROM $1) -1) / nr_of_days_in_year);
END
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_makeFTI(sa date, ka date, kb date, sb date) RETURNS geometry AS $$
	SELECT ST_MakeLine(ARRAY[ST_MakePoint(FD_makeX($1),0),
						ST_MakePoint(FD_makeX($2),1),
						ST_MakePoint(FD_makeX($3),1),
						ST_MakePoint(FD_makeX($4),0)]);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_makeFTI(ka date, kb date) RETURNS geometry AS $$
	SELECT FD_maakVoorstelling($1,$1,$2,$2);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_makeFTI(d date) RETURNS geometry AS $$
	SELECT FD_maakVoorstelling($1,$1,$1,$1);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_fuzzify(ka date, kb date, lv interval, rv interval) RETURNS geometry AS $$
	SELECT FD_maakVoorstelling(($1 - $3)::date, $1, $2, ($2 + $4)::date);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_fuzzify(ka date, kb date, v interval) RETURNS geometry AS $$
	SELECT FD_fuzzify($1,$2,$3,$3);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_fuzzify(d date, v interval) RETURNS geometry AS $$
	SELECT FD_fuzzify($1,$1,$2,$2);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_fuzzify(d date, lv interval, rv interval) RETURNS geometry AS $$
	SELECT FD_fuzzify($1,$1,$2,$3);
$$ LANGUAGE sql IMMUTABLE;
