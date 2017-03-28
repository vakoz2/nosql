@echo off
REM pg_ctl start
SETLOCAL
SET var=%1
IF "%var%"=="sample" (
  SET link=https://raw.githubusercontent.com/vakoz2/nosql/master/data/sample.csv
  SET check=ok
)
IF "%var%"=="full" (
  SET link=https://bitbucket.org/vakoz/nosql/raw/b61e19efe79fb7bcc56837a593041cfcfd6be535/Chicago_Crimes_2012_to_2017.csv
  SET check=ok
)
IF NOT DEFINED check (
  echo Błędny lub brak argumentu. Wywołaj z sample lub full
  goto :END
)
ptime scripts\pg_import.bat %link%
ptime sql2csv --db postgresql:///test --query "SELECT COUNT(*) FROM crimes"
ptime psql -d test -f scripts\pg_query1.sql
ptime psql -d test -f scripts\pg_query2.sql
ptime psql -d test -f scripts\pg_query3.sql
ptime psql -d test -c "SELECT \"Year\", COUNT(*) AS count FROM crimes GROUP BY \"Year\" ORDER BY \"Year\" DESC"
REM psql -d test -c "DROP TABLE crimes"

ENDLOCAL 
:END
