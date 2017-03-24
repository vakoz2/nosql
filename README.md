g## Łukasz Szlas

Wybrany zbiór danych: [Crimes in Chicago 2012 - 2017](https://www.kaggle.com/currie32/crimes-in-chicago)

(zaliczenie)

- [ ] EDA
- [ ] Aggregation Pipeline

(egzamin)

- [ ] MapReduce

Informacje o komputerze na którym były wykonywane obliczenia:

| Nazwa                 | Wartosć    |
|-----------------------|------------|
| System operacyjny     | Windows 8 x64 |
| Procesor              | i7-2630QM 2.0 GHz, 2.9 GHz Turbo, 4 rdzenie |
| Pamięć                | 8 GB |
| Dysk                  | SSD GoodRam Iridium Pro 240GB |
| Baza danych           | TODO |

# Trochę informacji o danych
##### Spakowany plik z danymi, w formacie csv, waży 90 mb. Po rozpakowaniu zajmuje 344 mb.
##### Wcześniej miałem tutaj notkę, że [csvjson](http://csvkit.readthedocs.io/en/latest/scripts/csvjson.html) nie działa dla moich danych. Dostałem (po użyciu opcji -verbose) MEMORY ERROR - okazało się, że problem stanowi 32bitowa wersja Pythona. Po reinstalacji mogłem już korzystać z CSVKit zamiast swoich programów w C++. Chociaż trzeba przyznać, iż czas działania CSVKit jest okropnie długi (mimo że mój kod był daleki od optymalnego wykonywał się <code>30 sec </code>

#### Początek oryginalnego pliku
```
,ID,Case Number,Date,Block,IUCR,Primary Type,Description,Location Description,Arrest,Domestic,Beat,District,Ward,Community Area,FBI Code,X Coordinate,Y Coordinate,Year,Updated On,Latitude,Longitude,Location
3,10508693,HZ250496,05/03/2016 11:40:00 PM,013XX S SAWYER AVE,0486,BATTERY,DOMESTIC BATTERY SIMPLE,APARTMENT,True,True,1022,10.0,24.0,29.0,08B,1154907.0,1893681.0,2016,05/10/2016 03:56:50 PM,41.864073157,-87.706818608,"(41.864073157, -87.706818608)"
```
#### Objaśnienie kolumn
##### Te, które postanowiłem zatrzymać

- [x] Date - data zajścia incydentu
- [x] Primary Type - typ przestępstwa
- [x] Description - opis przestępstwa
- [x] Location Description - opis miejsca
- [x] Arrest - czy doszło do zatrzymania
- [x] Domestic - czy typu przemoc domowa
- [x] Beat - najmniejszy obszar policyjny. Od 3 do 5 takich obszarów tworzą sektor, a 3 sektory tworzą dystrykt. Current Police Beats: https://data.cityofchicago.org/d/aerh-rz74
- [x] District - https://data.cityofchicago.org/d/fthy-xz3r
- [x] Ward - dystrykt rady miejskiej - https://data.cityofchicago.org/d/sp34-6z76
- [x] Community Area - kolejny podział na obszary - https://data.cityofchicago.org/d/cauq-8yn6
- [x] Year - rok w którym doszło do przestępstwa. W sumie mógłym pominąć...
- [x] Updated On - data dokonania ostatniej aktualizacji rekordu
- [x] Latitude - szerokość geograficzna miejsca popełnienia przestępstwa
- [x] Longitude - długość geograficzna

Kolumny, które odrzuciłem to: id, nume sprawy, kod FBI, IUCR (który jest id dla Primary Type & Description) oraz współrzędne geograficzne (X, Y coordianate), ponieważ mam już pola lat/lon.
#### Generowanie pliku z losową próbką danych
Jak wspomniałem wyżej działanie CSVKit dla całego pliku z  danymi trwa bardzo długo (po ponad godzinie go przerwałem).
- Początek
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/csvjson-poczatek.png)
jak widać spore wykorzystanie pamięci, procesor się nudzi(użycie na poziomie 5-20%)
- Po godzinie
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/csvjson-pamiec.png)
Wykorzystanie pamięci ~100%. Procesor nadal słabo wykorzystywany.
- Po przerwaniu
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/csvjson-koniec.png)

Postanowiłem utworzyć próbkę losowych rekordów, wrzucić ją na gita i na niej dokonywać operacji (dane będą pobierane, obrabiane i wrzucane do bazy (bez zapisu na dysk)).
<code>head -n 1 Chicago_Crimes_2012_to_2017.csv > sample.csv</code>
<code>time sort -R Chicago_Crimes_2012_to_2017.csv | head -n 10000 >> sample.csv </code>
Tutaj czas i wykorzystanie wyglądają znacznie lepiej
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/bash power.png)
real    1m48,901s
user    13m57,561s
sys     0m3,499s

# Zadanie GEO
## Elasticsearch
### Utworzenie bazy
<code>curl.exe -s -XPUT localhost:9200/crimes --data-binary @crimes.mappings</code>
### Import pliku z danymi
Do importu wykorzystałem narzędzie <b>type</b> (windowsowy cat) i <b>jq</b>

<code>type data\crimesSample.json |jq -c ".| .Location = [.Longitude, .Latitude] | {\"index\": {\"_index\": \"crimes\", \"_type\": \"crime\", \"_id\": .id}}, ." | curl.exe -XPOST localhost:9200/_bulk --data-binary @- </code>

<code> curl localhost:9200/crimes/crime/_count | jq .count </code>

Zwraca 10000, czyli ok.

### Zapytania
Treści zapytań są w plikach: elQuery1.query, elQuery2.query, elQuery3.query. Operuję na bazie 10k losowych danych zaimportowanych krok wcześniej.
#### Przestępstwa dokonane w promieniu kilometra od ratusza [Mapka](https://github.com/vakoz2/nosql/blob/master/geojson/query1.geojson)
#### Przestępstwa dokonane na danym obszarze (polygon) [Mapka](https://github.com/vakoz2/nosql/blob/master/geojson/query2.geojson)
#### Kradzieże na terenie lotniska (bounding_box) [Mapka](https://github.com/vakoz2/nosql/blob/master/geojson/query3.geojson)
Tutaj tabelka pokazująca dokładne miejsca kradzieży:
![alt tag](https://github.com/vakoz2/nosql/blob/master/złodziejaszki.png)

elQuery1.query
```
{
    "query": {
        "bool" : {
            "must" : {
                "match_all" : {}
            },
            "filter" : {
                "geo_distance" : {
                    "distance" : "1km",
                    "Location": [-87.631631, 41.88386]
                }
            }
        }
    }
}

```
elQuery2.query
```
{
    "query": {
        "bool" : {
            "must" : {
                "match_all" : {}
            },
            "filter" : {
                "geo_polygon" : {
                    "Location" : {
                        "points" : [
                            [-87.63119101524353, 41.89085702404937],
                            [-87.62666344642639, 41.89085702404937],
                            [-87.62666344642639, 41.89322904173341],
                            [-87.63119101524353, 41.89322904173341]
                        ]
                    }
                }
            }
        }
    }
}
```
elQuery3.query
```
{
    "query": {
        "bool" : {
            "must" : {
                "match" : {"Primary Type": "THEFT"}
            },
            "filter" : {
                "geo_bounding_box" : {
                    "Location": {
                      "top_left": [-87.9400634765625,42.00772369765501],
                      "bottom_right": [-87.86848068237305,41.956171100940026]
                    }
                }
            }
        }
    }
}
```

#### Opis kroków:

<code>curl.exe localhost:9200/crimes/_search?size=10000 --data-binary @elQuery1.query | jq .hits.hits[]._source > result1.json</code>

Jako, że plik result1.json nie jest prawidłowym jsonem napisałem prosty program, który go poprawia.

<code>Geohelper.exe result1.json</code>

zwraca result1fixed.json, który się waliduje.

Następnie korzystam z którkiego skruptu w js
```
var converter = require('json-2-csv');
var fs = require('fs');

var csv2jsonCallback = function (err, json) {
    if (err) throw err;
    console.log(json);
}

var data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
converter.json2csv(data, csv2jsonCallback);
```

<code>node.exe geojson.js result1fixed.json >> result1.csv</code>,

który zamienia mi format danych z json na csv. Następnie przy użyciu [geoison.io](http://geojson.io) zapisuje plik geojson do mojego repo.

# Zadanie 1
## Postgres
#### Stworzenie klastra:
<code>pg_ctl init</code>
#### Uruchomienie serwera:
<code>pg_ctl start</code>
#### Stworzenie bazy danych:
<code>createdb.exe testdb</code>
#### Połączenie z bazą:
<code>psql.exe testdb</code>
#### Stworzenie tabli:
```
CREATE TABLE Crimes(Date varchar, PrimaryType varchar, Description varchar, LocationDescription varchar, 
Arrest boolean, Domestic boolean, Beat integer, District decimal, Ward decimal, CommunityArea decimal, Year integer,
UpdatedOn varchar, Latitude decimal, Longitude decimal);
```
(daty póki co są jako varchar, bo są w złym formacie. Z dokumentacji wynika, że powinna pomóc zmiana ustawień w konfigu, ale póki co
nie udało mi się tego ustawić. Jak dalej nie będę mógł tego ogarnąć to chyba usunę godziny i zostawię samą datę)
#### Import danych
<code>\copy Crimes FROM 'C:\Users\vakoz\nosql\data\crimesSample.csv' DELIMITER ',' CSV HEADER</code>

zwróciło <code>COPY 10000</code>, czyli ok
#### Ilość kradzieży zakończonych aresztowaniem
<code>SELECT COUNT(*) FROM Crimes WHERE PrimaryType='THEFT' AND Arrest=TRUE;</code>
```
262
```

