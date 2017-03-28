SELECT "Date", "Primary Type", "Description", "Location Description", "Arrest", "Latitude", "Longitude" 
FROM crimes 
WHERE geom &&
ST_MakeEnvelope(-87.63119101524353,41.89085702404937, -87.62666344642639,41.89322904173341, 4326)