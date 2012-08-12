COMMENT ON FUNCTION FD_oldest() IS 
'Returns the oldest year that can be used.';

COMMENT ON FUNCTION FD_youngest() IS 
'Returns the youngest year that can be used.';

COMMENT ON FUNCTION FD_makeX(date) IS 
'Turns a date into a point on our X axis.';

COMMENT ON FUNCTION FD_maakVoorstelling(date, date, date, date) IS
'Create a FTI based on four dates that are the start of the support, 
the start of the core, the end of the core and the end of the support.';

COMMENT ON FUNCTION FD_maakVoorstelling(date, date) IS
'Create a FTI based on two dates that are the start and the end of the core.
The support is considered to be equal to the core. 
In effect this creates a sharp time interval.';

COMMENT ON FUNCTION FD_maakVoorstelling(date) IS
'Create a FTI based on one date that is both the start and the end of the core.
The support is considered to be equal to the core. 
In effect this creates a sharp time interval of a single date.';

COMMENT ON FUNCTION FD_fuzzify(date, date, interval, interval) IS
'Creates a FTI based on two dates that form the core of the FTI and two intervals
that determine the Fuzzy Beginning and Fuzzy End of the FTI.';

COMMENT ON FUNCTION FD_fuzzify(date, date, interval) IS
'Creates a FTI based on two dates that form the core of the FTI and one interval
that determines both the Fuzzy Beginning and Fuzzy End of the FTI.';

COMMENT ON FUNCTION FD_fuzzify(date, interval, interval) IS
'Create a FTI based on one date that forms the core of the FTI and two intervals
that determines the Fuzzy Beginning and Fuzzy End of the FTI.';

COMMENT ON FUNCTION FD_fuzzify(date, interval) IS
'Create a FTI based on one date that forms the core of the FTI and one interval
that determines both the Fuzzy Beginning and Fuzzy End of the FTI.';
