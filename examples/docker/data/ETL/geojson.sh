#!/usr/bin/env bash

if [[ " $(jq 'keys' <<<$source) " =~ "flags" ]]
then
  flags=$(jq -r '.flags' <<<$source) 
fi
echo sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr $flags -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/$filename"
sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr $flags -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/$filename"
# rm $DATA_DIR/$filename
