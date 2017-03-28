## Łukasz Szlas

Wybrany zbiór danych: [Crimes in Chicago 2012 - 2017](https://bitbucket.org/vakoz/nosql/raw/b61e19efe79fb7bcc56837a593041cfcfd6be535/Chicago_Crimes_2012_to_2017.csv)

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
| Baza danych           | Elasticsearch 5.2.2, Postgresql 9.6.2 |

# Trochę informacji o danych
##### Spakowany plik z danymi, w formacie csv, waży 90 mb. Po rozpakowaniu zajmuje 349 mb.
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
Jak widać spore wykorzystanie pamięci, procesor się nudzi(użycie na poziomie 5-20%)
- Po godzinie
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/csvjson-pamiec.png)
Wykorzystanie pamięci ~100%. Procesor nadal słabo wykorzystywany.
- Po przerwaniu
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/csvjson-przerwanie.png)

Postanowiłem utworzyć próbkę losowych rekordów, wrzucić ją na gita i na niej dokonywać operacji (dane będą pobierane, obrabiane i wrzucane do bazy (bez zapisu na dysk)).

<code>head -n 1 Chicago_Crimes_2012_to_2017.csv > sample.csv</code>

<code>time sort -R Chicago_Crimes_2012_to_2017.csv | head -n 10000 >> sample.csv </code>

Tutaj wykorzystanie i czas wyglądają znacznie lepiej
![alt tag](https://github.com/vakoz2/nosql/blob/master/screenshots/bash%20power.png)
```
real    1m48,901s
user    13m57,561s
sys     0m3,499s
```
# Zadanie 1
## Postgres
##### Wymagane programy:
- Postgresql
- CSVKit i SQLAlchemy
- ptime (dostarczony w repo)

Wszystkie poniższe komendy są uruchamiane ze skryptu [postgres.bat](https://github.com/vakoz2/nosql/blob/master/postgres.bat). Skrypt należy uruchomić w katalogu z projektem (nosql) z parametrem **sample** lub **full**. Przedstawione poniżej wyniki są efektem działań na próbce.
##### Uruchomienie serwera:
<code>pg_ctl start</code>
##### Pobieranie (bez zapisu na dysk) i oczyszczanie danych oraz utworzenie bazy, tabeli i import danych.
Trzeba przyznać, że CSVKit świetnie sobie radzi z rozpoznawaniem typu danych i konwersji ich do odpowiedniego formatu, np w oryginalnym pliku data wygląda tak: 05/03/2016 11:40:00 PM (jak próbowałem ręcznie wpisać taką datę do postgresa to wyrzucało mi błąd (oczywiście można by użyć daty takiego typu, ale wymagało by to zmiany w configu, albo  zdefiniowanie tego formatu timestampem)).

<code>ptime scripts\pg_import.bat %link%</code>

**plik pg_import.bat**
```
curl -s %1 | 
csvcut -c 4,7,8,9,10,11,12,13,14,15,19,20,21,22 | 
csvgrep -c 13,14 -r "^$" -i | 
csvsql --db postgresql:///test --insert --tables crimes
```


![alt tag](http://tutaj link do pg_import)
```
Execution time: 13.358 s
```

##### Zliczanie wszystkich rekordów:
<code>ptime sql2csv --db postgresql:///test --query "SELECT COUNT(*) FROM crimes"</code>
```
count
9773

Execution time: 0.571 s
```
#### Agregacje
Pliki z zapytaniami agregującymi są odpalane poleceniem:

<code>ptime psql -d test -f scripts\pg_queryX.sql</code>, gdzie X to numer agregacji.

##### 1. Ilość przestępstw w danych latach:
```language
SELECT "Year", COUNT(*) AS count FROM crimes 
GROUP BY "Year" 
ORDER BY "Year" DESC
```
```
 Year | count
------+-------
 2017 |     1
 2016 |  1724
 2015 |  1806
 2014 |  1862
 2013 |  2041
 2012 |  2339
(6 wierszy)

Execution time: 0.055 s
```
##### 2. 5 najczęsciej popełnianych przestępstw w pierwszym kwartale 2016 roku:
```
SELECT "Primary Type", COUNT(*) AS "type" FROM crimes 
WHERE "Date" >= '2016-01-01' AND "Date" < '2016-04-01'
GROUP BY "Primary Type"
ORDER BY "type" DESC
LIMIT 5
```
```
  Primary Type   | type
-----------------+------
 BATTERY         |   92
 THEFT           |   64
 CRIMINAL DAMAGE |   56
 ASSAULT         |   32
 OTHER OFFENSE   |   24
(5 wierszy)

Execution time: 0.042 s
```

##### 3. Ilość kradzieży zakończonych aresztowaniem:
```
SELECT COUNT(*) FROM crimes 
WHERE "Primary Type" LIKE '%THEFT%' AND "Arrest"='TRUE'
```
```
   274
(1 wiersz)

Execution time: 0.046 s
```
## Elasticsearch
##### Wymagane programy:
- Elasticsearch (uruchomiony)
- CSVKit
- jq
- curl
- ptime (dostarczony w repo)

Wszystkie poniższe komendy są uruchamiane ze skryptu [elastic.bat](https://github.com/vakoz2/nosql/blob/master/elastic.bat). Skrypt należy uruchomić w katalogu z projektem (nosql) z parametrem **sample** lub **full**. Pomiary czasu były wykonywane na lokalnym pliku.
#### Utworzenie mappingu
<code>curl.exe -s -XPUT localhost:9200/crimes --data-binary @crimes.mappings</code>
#### Import pliku z danymi

<code>pip scripts\el_import.bat</code>

**plik el_import.bat**
```
curl -s %1 |
csvcut -c 4,7,8,9,10,11,12,13,14,15,19,20,21,22 |
csvgrep -c 13,14 -r "^$" -i |
csvjson --stream | jq -c ". |
.Location = [.Longitude, .Latitude] |
{\"index\": {\"_index\": \"crimes\", \"_type\": \"crime\", \"_id\": .id}}, ." |
curl -XPOST localhost:9200/_bulk --data-binary @-
```
![alt tag](http://tutaj link do el_import.png)
```
Execution time: 16.403 s
```
##### Zliczanie wszystkich rekordów:
<code>ptime scripts\el_count.bat</code>
**plik el_count.bat**
<code>curl localhost:9200/crimes/crime/_count | jq .count</code>
```
9773

Execution time: 0.058 s
```

#### Agregacje
Pliki z zapytaniami agregującymi są odpalane poleceniem:

<code>ptime scripts\el_queryX.bat</code>, gdzie X to numer agregacji.
##### 1. Ilość przestępstw w danych latach:
```
{
  "size": 0,
  "aggs": {
    "group_by_year": {
      "terms": {
        "field": "Year",
        "order": {
          "_term": "desc"
        }
      }
    }
  }
}
```
```
[
  {
    "key": 2017,
    "doc_count": 1
  },
  {
    "key": 2016,
    "doc_count": 1724
  },
  {
    "key": 2015,
    "doc_count": 1806
  },
  {
    "key": 2014,
    "doc_count": 1862
  },
  {
    "key": 2013,
    "doc_count": 2041
  },
  {
    "key": 2012,
    "doc_count": 2339
  }
]
Execution time: 0.111 s
```
##### 2. 5 najczęsciej popełnianych przestępstw w pierwszym kwartale 2016 roku:
```
{
  "size": 0,
  "query": {
    "bool": {
      "filter": [
        {
          "range": {
            "Date": {
              "gt": "2015-12-31T23:59:59.999Z",
              "lt": "2016-04-01T00:00:00.000Z"
            }
          }
        }
      ]
    }
  },
  "aggs": {
    "group_by_type": {
      "terms": {
        "field": "Primary Type.keyword",
        "size": 5
      }
    }
  }
}
```

```
[
  {
    "key": "BATTERY",
    "doc_count": 92
  },
  {
    "key": "THEFT",
    "doc_count": 64
  },
  {
    "key": "CRIMINAL DAMAGE",
    "doc_count": 56
  },
  {
    "key": "ASSAULT",
    "doc_count": 32
  },
  {
    "key": "OTHER OFFENSE",
    "doc_count": 24
  }
]

Execution time: 0.050 s
```

##### 3. Ilość kradzieży zakończonych aresztowaniem:
```
{
  "query": { 
    "bool": {
      "must": [
        {"match_all": {}}
      ],
      "filter": [
        {"term": {
          "Primary Type": "theft"
        }},
        {"term": {
          "Arrest": "true"
        }}
      ]
    }
  }
}
```
```
274

Execution time: 0.059 s
```

# Zadanie GEO(https://vakoz2.github.io)