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
