#!/usr/bin/env bash

kmlfile=${filename%.*}.kml
if [[ " $(jq 'keys' <<<$source) " =~ "zipfile" ]]
then
  kmlfile=$(jq -r '.zipfile' <<<$source)
fi
if [[ " $(jq 'keys' <<<$source) " =~ "zipfolder" ]]
then
  kmlfile=$(jq -r '.zipfolder' <<<$source)/${filename%.*}.kml
fi
flags=''
if [[ " $(jq 'keys' <<<$source) " =~ "flags" ]]
then
  flags=$(jq -r '.flags' <<<$source) 
fi
echo sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr $flags -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/$kmlfile"
sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr $flags -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/$kmlfile"
# rm $DATA_DIR/$filename $DATA_DIR/$kmlfile
