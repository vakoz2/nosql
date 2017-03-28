SELECT "Primary Type", COUNT(*) AS "type" FROM crimes 
WHERE "Date" >= '2016-01-01' AND "Date" < '2016-04-01'
GROUP BY "Primary Type"
ORDER BY "type" DESC
LIMIT 5