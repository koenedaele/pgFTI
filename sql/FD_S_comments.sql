COMMENT ON FUNCTION FD_S_tw(float, float) IS
'Calculate the Lukasiewicz t-norm.';

COMMENT ON FUNCTION FD_S_iw(float, float) IS
'Calculate the Lukasiewicz residual implicator';

COMMENT ON FUNCTION FD_S_sw(float, float) IS
'Calculate the conorm.';

COMMENT ON FUNCTION FD_S_lb(float, float, float, float) IS
'Calculate how much the first argument is long before the second argument. 
The third and fourth parameters can be used to deteremine what long before is.';

COMMENT ON FUNCTION FD_S_beq(float, float, float, float) IS
'Calculate how much the first argument is contemporary to the second argument.
The third and fourth parameters can be used to deteremine what long before is.';

------------------------
-- Allen Relations S1 --
------------------------

COMMENT ON FUNCTION FD_S1_pointify(geometry) IS
'Change the geometry into a set of points.';

------------------------
-- Allen Relations S2 --
------------------------

COMMENT ON FUNCTION FD_S2_sl(geometry) IS
'Calculate the fuzzy beginning of a FTI.';

COMMENT ON FUNCTION FD_S2_sr(geometry) IS
'Calculate the fuzzy end of a FTI.';

COMMENT ON FUNCTION FD_S2_before_bb(geometry, geometry, float, float) IS
'Calculate how much the beginning of the first FTI is 
before the beginning of the second FTI.';

COMMENT ON FUNCTION FD_S2_equals_bb(geometry, geometry, float, float) IS
'Calculate how much the beginning of the first FTI is contemporary to 
the beginning of the second FTI.';

COMMENT ON FUNCTION FD_S2_before_ee(geometry, geometry, float, float) IS
'Calculate how much the end of the first FTI is 
before the end of the second FTI.';

COMMENT ON FUNCTION FD_S2_equals_ee(geometry, geometry, float, float) IS
'Calculate how much the end of the first FTI is contemporary to 
the end of the second FTI.';

COMMENT ON FUNCTION FD_S2_before_eb(geometry, geometry, float, float) IS
'Calculate how much the end of the first FTI is 
before the beginning of the second FTI.';

COMMENT ON FUNCTION FD_S2_equals_ee(geometry, geometry, float, float) IS
'Calculate how much the end of the first FTI is contemporary to 
the beginning of the second FTI.';

COMMENT ON FUNCTION FD_S2_before_be(geometry, geometry, float, float) IS
'Calculate how much the beginning of the first FTI is 
before the end of the second FTI.';

COMMENT ON FUNCTION FD_S2_equals_ee(geometry, geometry, float, float) IS
'Calculate how much the beginning of the first FTI is contemporary to 
the end of the second FTI.';


CREATE OR REPLACE FUNCTION FD_S2_allen_before(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_before_eb(g1, g2, alpha, beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_before(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 1;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_before_eb(g1, g2, 0, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_meets(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	equals_eb float;
	equals_be float;
BEGIN
	equals_eb := FD_S2_equals_eb(g1, g2, alpha, beta);
	IF (equals_eb = 0) THEN
		RETURN 0;
	END IF;
	equals_be := FD_S2_equals_be(g2, g1, alpha, beta);
	IF (equals_be = 0) THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(equals_eb,equals_be);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_meets(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_meets(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_overlaps(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	before_bb float;
	before_be float;
	before_ee float;
BEGIN
	before_bb := FD_S2_before_bb(g1,g2,alpha,beta);
	IF (before_bb = 0) THEN
		RETURN 0;
	END IF;
	before_be := FD_S2_before_be(g2,g1,alpha,beta);
	IF (before_be = 0) THEN
		RETURN 0;
	END IF;
	before_ee := FD_S2_before_ee(g1,g2,alpha,beta);
	IF (before_ee = 0) THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(	before_bb,
							float8smaller( before_be, before_ee));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_overlaps(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_overlaps(g1, g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_during(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	before_bb float;
	before_ee float;
BEGIN
	before_bb := FD_S2_before_bb(g2,g1,alpha,beta);
	IF (before_bb = 0) THEN
		RETURN before_bb;
	END IF;
	before_ee := FD_S2_before_ee(g1,g2,alpha,beta);
	IF (before_ee = 0) THEN
		RETURN before_ee;
	END IF;
	RETURN float8smaller( before_bb, before_ee );
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_during(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_during(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_starts(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	equals_bb_g1g2 float;
	equals_bb_g2g1 float;
	before_ee float;
BEGIN
	equals_bb_g1g2 := FD_S2_equals_bb(g1,g2,alpha,beta);
	IF (equals_bb_g1g2 = 0) THEN
		RETURN equals_bb_g1g2;
	END IF;
	equals_bb_g2g1 := FD_S2_equals_bb(g2,g1,alpha,beta);
	IF (equals_bb_g2g1 = 0) THEN
		RETURN equals_bb_g2g1;
	END IF;
	before_ee := FD_S2_before_ee(g1,g2,alpha,beta);
	IF (before_ee = 0) THEN
		RETURN before_ee;
	END IF;
	RETURN float8smaller(	before_ee,
							float8smaller(	equals_bb_g1g2,
											equals_bb_g2g1));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_starts(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_starts(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_finishes(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	equals_ee_g1g2 float;
	equals_ee_g2g1 float;
	before_bb float;
BEGIN
	equals_ee_g1g2 := FD_S2_equals_ee(g1,g2,alpha,beta);
	IF (equals_ee_g1g2 = 0) THEN
		RETURN 0;
	END IF;
	equals_ee_g2g1 := FD_S2_equals_ee(g2,g1,alpha,beta);
	IF (equals_ee_g2g1 = 0) THEN
		RETURN 0;
	END IF;
	before_bb := FD_S2_before_bb(g2,g1,alpha,beta);
	IF (before_bb = 0) THEN
		RETURN 0;
	END IF;
	RETURN float8smaller( 	equals_ee_g1g2,
							float8smaller(	equals_ee_g2g1,
											before_bb));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_finishes(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_finishes(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_equals(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	equals_ee_g1g2 float;
	equals_ee_g2g1 float;
	equals_bb_g1g2 float;
	equals_bb_g2g1 float;
BEGIN
	equals_ee_g1g2 := FD_S2_equals_ee(g1,g2,alpha,beta);
	IF (equals_ee_g1g2 = 0) THEN
		RETURN 0;
	END IF;
	equals_ee_g2g1 := FD_S2_equals_ee(g2,g1,alpha,beta);
	IF (equals_ee_g2g1 = 0) THEN
		RETURN 0;
	END IF;
	equals_bb_g1g2 := FD_S2_equals_bb(g1,g2,alpha,beta);
	IF (equals_bb_g1g2 = 0) THEN
		RETURN 0;
	END IF;
	equals_bb_g2g1 := FD_S2_equals_bb(g2,g1,alpha,beta);
	IF (equals_bb_g2g1 = 0) THEN
		RETURN 0;
	END IF;
	RETURN 	float8smaller(
				float8smaller( 	equals_ee_g1g2,
								equals_ee_g2g1),
				float8smaller(	equals_bb_g1g2,
								equals_bb_g2g1));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_equals(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_allen_equals(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_after(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_before(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_after(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_before(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_overlapped_by(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_overlaps(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_overlapped_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_overlaps(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_contains(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_during(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_contains(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_during(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_met_by(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_meets(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_met_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_meets(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_started_by(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_starts(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_started_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_starts(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_allen_finished_by(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_finishes(g2,g1,alpha,beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_allen_finished_by(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_allen_finishes(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


----------------------------
-- Composite Relations S2 --
----------------------------


CREATE OR REPLACE FUNCTION FD_S2_kvd_before(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_equals_eb(g1, g2, alpha, beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_kvd_before(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 1;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_equals_eb(g1, g2, 0, 0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_kvd_after(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_kvd_before(g2, g1, alpha, beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_kvd_after(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_kvd_before(g2, g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_kvd_during(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	beq_ee float;
	beq_bb float;
BEGIN
	beq_ee := FD_S2_equals_ee(g1,g2,alpha,beta);
	IF (beq_ee = 0) THEN
		RETURN 0;
	END IF;
	beq_bb := FD_S2_equals_bb(g2,g1,alpha,beta);
	IF (beq_bb = 0) THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(
			beq_ee,
			beq_bb
			);	
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_kvd_during(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_kvd_during(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_kvd_contains(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN FD_S2_kvd_during(g2, g1, alpha, beta);
END
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_kvd_contains(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	RETURN FD_S2_kvd_during(g2,g1);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_kvd_intersects(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	before_be_g1g2 float;
	before_be_g2g1 float;
BEGIN
	before_be_g1g2 := FD_S2_before_be(g1,g2,alpha,beta);
	IF (before_be_g1g2 = 0) THEN
		RETURN 0;
	END IF;
	before_be_g2g1 := FD_S2_before_be(g2,g1,alpha,beta);
	IF (before_be_g2g1 = 0) THEN
		RETURN 0;
	END IF;
	RETURN float8smaller(
			before_be_g1g2,
			before_be_g2g1
			);	
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_kvd_intersects(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 0;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S2_kvd_intersects(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;
