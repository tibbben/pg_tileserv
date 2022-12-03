#!/usr/bin/env bash

python3 $ETL_DIR/wazefeed.py $DATA_DIR $filename
#rm $DATA_DIR/$filename
for file in alerts irregularities jams
do
  echo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' /$DATA_DIR/$file.json"
  sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' /$DATA_DIR/$file.json"
  # rm $file
done
