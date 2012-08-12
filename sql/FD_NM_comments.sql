COMMENT ON FUNCTION FD_NM_makeTimeline() IS
'Create a box that represents our timeline and has a height of 1.';

COMMENT ON FUNCTION FD_NM_YMin(geometry) IS
'Calculate the minimum Y value greater than 0 of a FTI.';

COMMENT ON FUNCTION FD_NM_extendNegative(geometry) IS
'Extend the FTI towards the past.';

COMMENT ON FUNCTION FD_NM_extendPositive(geometry) IS
'Extend the FTI towards the future.';

COMMENT ON FUNCTION FD_NM_complement(geometry) IS
'Calculates the complement of a FTI.';
