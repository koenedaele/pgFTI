CREATE OR REPLACE FUNCTION FD_NM_maakTijdsbalk() RETURNS box2d AS $$
	SELECT ST_MakeBox2D(ST_MakePoint(FD_oudste(), 0), ST_MakePoint(FD_jongste(), 1));
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_YMin(g geometry) RETURNS float AS $$
DECLARE
	y float := 1;
	yTmp float;
	tmp geometry;
BEGIN
	IF ST_GeometryType(g) = 'ST_MultiPolygon' THEN
		RETURN 0;
	END IF;
	tmp := ST_Boundary(g);
	FOR p IN 1..ST_NPoints(tmp) LOOP
		yTmp := ST_Y(ST_PointN(tmp,p));
		IF yTmp > 0 AND y > yTmp THEN
			y = yTmp::float;
		END IF; 
	END LOOP;
	RETURN y;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_extendNegative(g geometry) RETURNS geometry AS $$
	SELECT ST_ConvexHull(ST_Collect(ST_MakeLine(ST_MakePoint(FD_oudste(),0),ST_MakePoint(FD_oudste(),1)),$1));
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_extendPositive(g geometry) RETURNS geometry AS $$
	SELECT ST_ConvexHull(ST_Collect(ST_MakeLine(ST_MakePoint(FD_jongste(),0),ST_MakePoint(FD_jongste(),1)),$1));
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_complement(g geometry) RETURNS geometry AS $$
SELECT ST_MakePolygon(ST_MakeLine(punt)) FROM (				
	SELECT ST_Point(x,comp) AS punt FROM (
		SELECT 	
			ST_X(ST_PointN(column1,generate_series(1,ST_NPoints(column1)))) AS x,
			1 - ST_Y(ST_PointN(column1,generate_series(1,ST_NPoints(column1)))) AS comp
		FROM (VALUES(ST_Boundary(ST_Difference(FD_NM_maakTijdsbalk(),$1)))) AS split
	) AS punten
) AS lijn;
$$ LANGUAGE sql IMMUTABLE;

--------------------
-- Allen Relaties --
--------------------


CREATE OR REPLACE FUNCTION FD_NM_allen_before(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	tmp geometry;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 1;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	tmp := ST_Intersection( FD_NM_complement(FD_NM_extendNegative(g1)),
							FD_NM_complement(FD_NM_extendPositive(g2)));
	IF ST_IsEmpty(tmp) THEN
		RETURN 0;
	ELSE
		RETURN ST_YMAX(tmp);
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_meets(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_YMin(ST_Union(FD_NM_extendNegative(g1),FD_NM_extendPositive(g2)));
	IF a = 0 THEN
		RETURN 0;
	END IF;
	b := FD_NM_YMin(ST_Union(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_complement(FD_NM_extendPositive(g2))));
	IF b = 0 THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(a,b);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_overlaps(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
	c float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := ST_YMax(ST_Intersection(FD_NM_extendPositive(g1),FD_NM_complement(FD_NM_extendPositive(g2))));
	IF a = 0 THEN
		RETURN 0;
	END IF;
	b := ST_YMax(ST_Intersection(FD_NM_extendNegative(g1),FD_NM_extendPositive(g2)));
	IF b = 0 THEN
		RETURN 0;
	END IF;
	c := ST_YMax(ST_Intersection(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_extendNegative(g2)));
	IF c = 0 THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(float8smaller(a,b),c);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_starts(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
	c float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_YMin(ST_Union(FD_NM_complement(FD_NM_extendPositive(g1)),FD_NM_extendPositive(g2)));
	IF a = 0 THEN
		RETURN a;
	END IF;
	b := FD_NM_YMin(ST_Union(FD_NM_extendPositive(g1),FD_NM_complement(FD_NM_extendPositive(g2))));
	IF b = 0 THEN
		RETURN b;
	END IF;
	c := ST_YMax(ST_Intersection(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_extendNegative(g2)));
	IF c = 0 THEN
		RETURN c;
	END IF;
	RETURN float8smaller(float8smaller(a,b),c);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_during(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := ST_YMax(ST_Intersection(FD_NM_complement(FD_NM_extendPositive(g1)),FD_NM_extendPositive(g2)));
	IF a = 0 THEN
		RETURN 0;
	END IF;
	b := ST_YMax(ST_Intersection(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_extendNegative(g2)));
	IF b = 0 THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(a,b);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_finishes(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
	c float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_YMin(ST_Union(FD_NM_extendNegative(g1),FD_NM_complement(FD_NM_extendNegative(g2))));
	IF a = 0 THEN
		RETURN 0;
	END IF;
	b := FD_NM_YMin(ST_Union(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_extendNegative(g2)));
	IF b = 0 THEN
		RETURN 0;
	END IF;
	c := ST_YMax(ST_Intersection(FD_NM_extendPositive(g1),FD_NM_complement(FD_NM_extendPositive(g2))));
	IF c = 0 THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(float8smaller(a,b),c);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_allen_after(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_before(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_equals(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
	c float;
	d float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_YMin(ST_Union(FD_NM_extendNegative(g1),FD_NM_complement(FD_NM_extendNegative(g2))));
	IF a = 0 THEN
		RETURN 0;
	END IF;
	b := FD_NM_YMin(ST_Union(FD_NM_complement(FD_NM_extendNegative(g1)),FD_NM_extendNegative(g2)));
	IF b = 0 THEN
		RETURN 0;
	END IF;
	c := FD_NM_YMin(ST_Union(FD_NM_complement(FD_NM_extendPositive(g1)),FD_NM_extendPositive(g2)));
	IF c = 0 THEN
		RETURN 0;
	END IF;
	d := FD_NM_YMin(ST_Union(FD_NM_extendPositive(g1),FD_NM_complement(FD_NM_extendPositive(g2))));
	IF d = 0 THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(float8smaller(a,b),float8smaller(c,d));
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_met_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_meets(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_overlapped_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_overlaps(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_started_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_starts(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_contains(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_during(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_allen_finished_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_allen_finishes(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

----------------------------
-- Samengestelde Relaties --
----------------------------

CREATE OR REPLACE FUNCTION FD_NM_kvd_before(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 1;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_allen_before(g1, g2);
	IF a = 1 THEN 
		RETURN 1;
	END IF;
	b := FD_NM_allen_meets(g1,g2);
	IF b = 1 THEN
		RETURN 1;
	END IF;
	RETURN float8larger(a,b);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_kvd_during(g1 geometry, g2 geometry) RETURNS float AS $$
DECLARE
	a float;
	b float;
	c float;
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	a := FD_NM_allen_starts(g1,g2);
	IF (a = 1) THEN
		RETURN 1;
	END IF;
	b := FD_NM_allen_during(g1,g2);
	IF (b = 1) THEN
		RETURN 1;
	END IF;
	c := FD_NM_allen_during(g1,g2);
	IF (c = 1) THEN 
		RETURN 1;
	END IF;
	RETURN float8larger(a,float8larger(b,c));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_NM_kvd_intersects(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN ST_YMax(ST_Intersection(g1, g2));
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_kvd_after(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_kvd_before(g2, g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_NM_kvd_contains(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_NM_kvd_during(g2, g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
