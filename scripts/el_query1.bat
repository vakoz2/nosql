curl localhost:9200/crimes/_search --data-binary @scripts\el_query1.body | jq .aggregations.group_by_year.buckets