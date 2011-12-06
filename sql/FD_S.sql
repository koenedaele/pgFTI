CREATE OR REPLACE FUNCTION FD_S_tw(x float, y float) RETURNS float AS $$
	SELECT float8larger(0, $1 + $2 - 1);
$$LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S_iw(x float, y float) RETURNS float AS $$
	SELECT float8smaller(1, 1 - $1 + $2);
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S_sw(x float, y float) RETURNS float AS $$
	SELECT float8smaller(1, $1 + $2);
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S_lb(a float, b float, alpha float, beta float) RETURNS float AS $$
BEGIN
	IF (b - a) > ( alpha + beta) THEN
		RETURN 1;
	ELSIF (b - a) <= alpha THEN
		RETURN 0;
	ELSE 
		RETURN (b - a - alpha) / beta;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S_beq(a float, b float, alpha float, beta float) RETURNS float AS $$
BEGIN
	RETURN 1 - FD_S_lb(b, a , alpha, beta);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-----------------------
-- Allen Relaties S1 --
-----------------------

CREATE OR REPLACE FUNCTION FD_S1_verpunt(g geometry) RETURNS SETOF geometry AS $$
	SELECT ST_PointN($1,generate_series(1,ST_NPoints($1)))
	UNION
	SELECT ST_Line_Interpolate_Point(ST_MakeLine(sp,ep),0.01 * generate_series(1,100)) FROM (
		SELECT 	ST_PointN($1, generate_series(1, ST_NPoints($1)-1)) AS sp,
			ST_PointN($1, generate_series(2, ST_NPoints($1))) AS ep
	) AS lijn_punten
	WHERE ST_Y(sp) <> ST_Y(ep);
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S1_allen_before(g1 geometry, g2 geometry, a float, b float) RETURNS float AS $$
DECLARE
	p geometry;
	p2 geometry;
	tmp float[];
	tmpI float[];
	inf float;
	inf2 float;
BEGIN
	FOR p IN SELECT * FROM FD_S1_verpunt(g2) LOOP
		tmpI := '{}'::float[];
		FOR p2 IN SELECT * FROM FD_S1_verpunt(g1) LOOP
			inf2 := FD_S_iw(ST_Y(p2),FD_S_lb(ST_X(p2),ST_X(p),a,b));
			SELECT array_append(tmpI, inf2) INTO tmpI;
		END LOOP;
		SELECT INTO inf MIN(unnest) FROM UNNEST(tmpI);
		SELECT array_append(tmp, FD_S_iw(ST_Y(p),inf)) INTO tmp;
	END LOOP;
	SELECT INTO inf MIN(unnest) FROM UNNEST(tmp);
	RETURN inf;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S1_allen_before(g1 geometry, g2 geometry) RETURNS float AS $$
BEGIN
	IF ST_XMax(g1) < ST_XMin(g2) THEN
		RETURN 1;
	END IF;
	IF ST_XMin(g1) > ST_XMax(g2) THEN
		RETURN 0;
	END IF;
	RETURN FD_S1_allen_before(g1,g2,0,0);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-----------------------
-- Allen Relaties S2 --
-----------------------


CREATE OR REPLACE FUNCTION FD_S2_sl(g geometry) RETURNS float AS $$
	SELECT ST_X(ST_PointN($1, 2)) - ST_X(ST_PointN($1,1));
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_sr(g geometry) RETURNS float AS $$
	SELECT ST_X(ST_PointN($1, 4)) - ST_X(ST_PointN($1,3));
$$ LANGUAGE sql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_before_bb(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha1 float;
BEGIN
	i := FD_S_tw(ST_YMax(g1),1 - ST_YMax(g2));
	alpha1 := 	alpha
			+ ( float8smaller(0, FD_S2_sl(g2) - beta ) * ( 1 - ST_YMax(g2)) )
			+ ( float8larger(beta,FD_S2_sl(g2)) * (1 - ST_YMax(g1) ) )
			- (FD_S2_sl(g1))
			+ ( ST_YMax(g1) * float8smaller(float8larger( beta, FD_S2_sl(g2)),FD_S2_sl(g1)));
				
	j := float8smaller(	ST_YMax(g1),
						FD_S_lb(ST_X(ST_PointN(g1,2)),
								ST_X(ST_PointN(g2,2)), 
								alpha1, 
								float8larger( beta, float8larger(FD_S2_sl(g1), FD_S2_sl(g2)))
								)
						);
	RETURN float8larger(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_equals_bb(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha2 float;
BEGIN
	i := FD_S_iw(ST_YMax(g2),ST_YMax(g1));
	alpha2 := 	alpha
			+ ( float8smaller(0, FD_S2_sl(g1) - beta ) * ( 1 - ST_YMax(g1)) )
			+ ( float8larger(beta,FD_S2_sl(g1)) * (1 - ST_YMax(g2) ) )
			- (FD_S2_sl(g2))
			+ ( ST_YMax(g2) * float8smaller(float8larger( beta, FD_S2_sl(g1)),FD_S2_sl(g2)));
				
	j := float8larger(	1-ST_YMax(g2),
						FD_S_beq(	ST_X(ST_PointN(g1,2)),
									ST_X(ST_PointN(g2,2)), 
									alpha2, 
									float8larger( beta, float8larger(FD_S2_sl(g1), FD_S2_sl(g2)))
									)
						);
	RETURN float8smaller(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_before_ee(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha3 float;
BEGIN
	i := FD_S_tw(ST_YMax(g2),1 - ST_YMax(g1));
	alpha3 := 	alpha
			+ ( float8smaller(0, FD_S2_sr(g1) - beta ) * ( 1 - ST_YMax(g1)) )
			+ ( float8larger(beta,FD_S2_sr(g1)) * (1 - ST_YMax(g2) ) )
			- (FD_S2_sr(g2))
			+ ( ST_YMax(g2) * float8smaller(float8larger( beta, FD_S2_sr(g1)),FD_S2_sr(g2) ) );
				
	j := float8smaller(	ST_YMax(g2),
						FD_S_lb(	ST_X(ST_PointN(g1,3)),
									ST_X(ST_PointN(g2,3)), 
									alpha3, 
									float8larger( beta, float8larger(FD_S2_sr(g1), FD_S2_sr(g2)))
									)
						);
	RETURN float8larger(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_equals_ee(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha4 float;
BEGIN
	i := FD_S_iw(ST_YMax(g1),ST_YMax(g2));
	alpha4 := 	alpha
			+ ( float8smaller(0, FD_S2_sr(g2) - beta ) * ( 1 - ST_YMax(g2)) )
			+ ( float8larger(beta,FD_S2_sr(g2)) * (1 - ST_YMax(g1) ) )
			- (FD_S2_sr(g1))
			+ ( ST_YMax(g1) * float8smaller(float8larger( beta, FD_S2_sr(g2)),FD_S2_sr(g1) ) );
				
	j := float8larger(	1-ST_YMax(g1),
						FD_S_beq(	ST_X(ST_PointN(g1,3)),
									ST_X(ST_PointN(g2,3)), 
									alpha4, 
									float8larger( beta, float8larger(FD_S2_sr(g1), FD_S2_sr(g2)))
									)
						);
	RETURN float8smaller(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_before_eb(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha5 float;
BEGIN
	i := FD_S_sw(1 - ST_YMax(g1),1 - ST_YMax(g2));
	alpha5 := 	alpha
			+ ( float8smaller(0, FD_S2_sl(g2) - beta ) * ( 1 - ST_YMax(g2)) )
			+ ( float8smaller( float8larger(beta,FD_S2_sl(g2)), FD_S2_sr(g1) ) )
			- ( ST_YMax(g2) * float8larger( beta, FD_S2_sl(g2) ) )
			- ( FD_S2_sr(g1) * ST_YMax(g1))
			+ ( float8larger( beta, float8larger(FD_S2_sl(g2),FD_S2_sr(g1))) * FD_S_tw(ST_YMax(g1),ST_YMax(g2)));
				
	j := FD_S_lb(	ST_X(ST_PointN(g1,3)),
					ST_X(ST_PointN(g2,2)), 
					alpha5, 
					float8larger( beta, float8larger(FD_S2_sr(g1), FD_S2_sl(g2)))
					);
	RETURN float8larger(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_equals_eb(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha6 float;
BEGIN
	i := FD_S_sw(1 - ST_YMax(g1),1 - ST_YMax(g2));
	alpha6 := 	alpha
			+ ( float8smaller(beta - FD_S2_sl(g2),(beta-FD_S2_sl(g2)) * ( 1 - ST_YMax(g2) ) ) )
			+ ( float8larger(beta,FD_S2_sl(g2)) * ST_YMax(g2) )
			+ (FD_S2_sr(g1) * ST_YMax(g1))
			- ( FD_S2_sr(g1) )
			- ( float8larger( beta, float8larger(FD_S2_sr(g1),FD_S2_sl(g2))) * FD_S_tw(ST_YMax(g1),ST_YMax(g2)));
				
	j := FD_S_beq(	ST_X(ST_PointN(g1,3)),
					ST_X(ST_PointN(g2,2)), 
					alpha6, 
					float8larger( beta, float8larger(FD_S2_sr(g1), FD_S2_sl(g2)))
					);
	RETURN float8larger(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


CREATE OR REPLACE FUNCTION FD_S2_before_be(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha7 float;
BEGIN
	i := FD_S_tw(ST_YMax(g1),ST_YMax(g2));
	alpha7 := 	alpha
			+ ( float8smaller(beta-FD_S2_sr(g2),(beta-FD_S2_sr(g2))*(1-ST_YMax(g2))))
			+ ( FD_S2_sl(g1) * ST_YMax(g1))
			+ ( float8larger(beta,FD_S2_sr(g2)) * ST_YMax(g2) )
			- FD_S2_sl(g1)
			- (float8larger(beta,float8larger(FD_S2_sl(g1),FD_S2_sr(g2))) * FD_S_tw(ST_YMax(g1),ST_YMax(g2)) );
				
	j := FD_S_lb(	ST_X(ST_PointN(g1,2)),
					ST_X(ST_PointN(g2,3)), 
					alpha7, 
					float8larger( beta, float8larger(FD_S2_sl(g1), FD_S2_sr(g2)))
					);
	RETURN float8smaller(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION FD_S2_equals_be(g1 geometry, g2 geometry, alpha float, beta float) RETURNS float AS $$
DECLARE
	i float;
	j float;
	alpha8 float;
BEGIN
	i := FD_S_tw(ST_YMax(g1),ST_YMax(g2));
	alpha8 := 	alpha
			+ (float8smaller(0,FD_S2_sr(g2)-beta) * (1 - ST_YMax(g2)))
			+ (float8smaller(float8larger(beta,FD_S2_sr(g2)),FD_S2_sl(g1)))
			- (ST_YMax(g1) * FD_S2_sl(g1))
			- (ST_YMax(g2) * float8larger(beta,FD_S2_sr(g2)))
			+ float8larger(beta,float8larger(FD_S2_sl(g1),FD_S2_sr(g2)) * FD_S_tw(ST_YMax(g1),ST_YMax(g2)));
				
	j := FD_S_beq(	ST_X(ST_PointN(g1,2)),
					ST_X(ST_PointN(g2,3)), 
					alpha8, 
					float8larger( beta, float8larger(FD_S2_sl(g1), FD_S2_sr(g2)))
					);
	RETURN float8smaller(i,j);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


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


-------------------------------
-- Samengestelde Relaties S2 --
-------------------------------


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
