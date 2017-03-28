SELECT "Year", COUNT(*) AS count FROM crimes 
GROUP BY "Year" 
ORDER BY "Year" DESC