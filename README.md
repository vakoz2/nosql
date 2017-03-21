## Łukasz Szlas

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

# Obróbka danych
#### Spakowany plik z danymi, w formacie csv, waży 90 mb. Po rozpakowaniu zajmuje 344 mb.
### Z nieznanego mi powodu program [csvjson](http://csvkit.readthedocs.io/en/latest/scripts/csvjson.html) nie działa dla całego pliku csv z danymi więc napisałem własny. CSVHelper [TODO daj link] oczyszcza tabelę ze zbędnych kolumn i zapisuje wynik do plików .csv i .json. Przyjmuje także parametr -random x, gdzie x to liczba losowych rekordów, które zwróci program.
#### Początek oryginalnego pliku
```
Num,ID,Case Number,Date,Block,IUCR,Primary Type,Description,Location Description,Arrest,Domestic,Beat,District,Ward,Community Area,FBI Code,X Coordinate,Y Coordinate,Year,Updated On,Latitude,Longitude,Location
3,10508693,HZ250496,05/03/2016 11:40:00 PM,013XX S SAWYER AVE,0486,BATTERY,DOMESTIC BATTERY SIMPLE,APARTMENT,True,True,1022,10.0,24.0,29.0,08B,1154907.0,1893681.0,2016,05/10/2016 03:56:50 PM,41.864073157,-87.706818608,"(41.864073157, -87.706818608)"
```
#### Początek plików .csv i .json wygenerowanych przez <code>CSVHelper -random 10000</code>
crimesSample.csv
```
Date,Primary Type,Description,Location Description,Arrest,Domestic,Beat,District,Ward,Community Area,Year,Updated On,Latitude,Longitude
05/03/2016 09:40:00 PM,BATTERY,DOMESTIC BATTERY SIMPLE,RESIDENCE,False,True,313,3.0,20.0,42.0,2016,05/10/2016 03:56:50 PM,41.782921527,-87.60436317
```
crimesSample.json
```
{"Date": "05/03/2016 09:40:00 PM", "Primary Type": "BATTERY", "Description": "DOMESTIC BATTERY SIMPLE", "Location Description": "RESIDENCE", "Arrest": "False", "Domestic": "True", "Beat": 313, "District": 3.0, "Ward": 20.0, "Community Area": 42.0, "Year": 2016, "Updated On": "05/10/2016 03:56:50 PM", "Latitude": 41.782921527, "Longitude": -87.60436317}
```
#### Wyjaśnienie poszczególnych wartości w [Crimes in Chicago 2012 - 2017](https://www.kaggle.com/currie32/crimes-in-chicago)
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
Treści zapytań są w plikach: elQuery1.query [TODO: Daj linki], elQuery2.query, elQuery3.query. Operuję na bazie 10k losowych danych zaimportowanych krok wcześniej.
#### Przestępstwa dokonane w promieniu kilometra od ratusza Mapka[TODO link]
<code>curl.exe localhost:9200/crimes/_search?size=10000 --data-binary @elQuery1.query | jq .hits.hits[]._source > result1.json</code>

Jako, że plik result1.json nie jest prawidłowym jsonem napisałem prosty program, który go poprawia.

<code>Geohelper.exe result1.json</code>

zwraca result1fixed.json, który się waliduje.

Następnie korzystam ze skruptu w js [TODO daj link]

<code>node.exe geojson.js result1fixed.json >> result1.csv</code>

który zamienia mi format danych z json na csv. Następnie przy użyciu [geoison.io](http://geojson.io) zapisuje plik geojson do mojego repo.

