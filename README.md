# Fuzzy Time Intervals for PostgreSQL

This code enables storing fuzzy time intervals in PostgreSQL and querying them using differents algorithms.

## Requirements

 * Postgresql database server (tested with 8.4)
 * PostGIS extension (tested with 1.5)

## Installation

 Installtion is simple: just source the file sql/FD.sql into the database. If you want to test the code before adding, change the commit statement in this file to a rollback statement. This will test that all syntax is correct.

## Further reading

 * Van Daele, Koen 2010: Imperfecte tijdsmodellering in historische databanken. Universiteit Gent, onuitgegeven masterproef. http://lib.ugent.be/fulltxt/RUG01/001/418/820/RUG01-001418820_2010_0001_AC.pdf.
