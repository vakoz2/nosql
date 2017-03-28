if not exist geojson mkdir geojson
echo Date,Primary Type,Description,Location Description,Arrest,Latitude,Longitude> result.csv
curl localhost:9200/crimes/_search?size=10000 --data-binary @scripts/el_geoQuery1.query | jq -r  ".hits.hits[]._source | [.Date, .\"Primary Type\", .Description, .\"Location Description\", .Arrest, .Latitude, .Longitude] | @csv" >> result.csv
csvjson --lat  Latitude --lon Longitude result.csv > geojson\query1.geojson
echo Date,Primary Type,Description,Location Description,Arrest,Latitude,Longitude> result.csv
curl localhost:9200/crimes/_search?size=10000 --data-binary @scripts/el_geoQuery2.query | jq -r  ".hits.hits[]._source | [.Date, .\"Primary Type\", .Description, .\"Location Description\", .Arrest, .Latitude, .Longitude] | @csv" >> result.csv
csvjson --lat  Latitude --lon Longitude result.csv > geojson\query2.geojson
echo Date,Primary Type,Description,Location Description,Arrest,Latitude,Longitude> result.csv
curl localhost:9200/crimes/_search?size=10000 --data-binary @scripts/el_geoQuery3.query | jq -r  ".hits.hits[]._source | [.Date, .\"Primary Type\", .Description, .\"Location Description\", .Arrest, .Latitude, .Longitude] | @csv" >> result.csv
csvjson --lat  Latitude --lon Longitude result.csv > geojson\query3.geojson
DEL result.csv
curl -XDELETE "http://localhost:9200/crimes"