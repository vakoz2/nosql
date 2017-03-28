SELECT "Date", "Primary Type", "Description", "Location Description", "Arrest", "Longitude", "Latitude"
FROM crimes 
WHERE "Primary Type" LIKE '%THEFT%' AND geom &&
ST_MakeEnvelope(-87.93834686279295, 41.95693703889415, -87.87483215332031, 42.0064481470799, 4326)
ORDER BY "Longitude", "Latitude", "Date"