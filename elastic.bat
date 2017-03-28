@echo off
curl -s -XPUT localhost:9200/crimes --data-binary @scripts\crimes.mappings
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
ptime scripts\el_import.bat %link%
ptime scripts\el_count.bat
ptime scripts\el_query1.bat
ptime scripts\el_query2.bat
ptime scripts\el_query3.bat

ENDLOCAL 
:END
