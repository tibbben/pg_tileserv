#!/usr/bin/env bash

shapefile=/work/${filename%.*}.shp
epsg=$(jq -r '.epsg' <<< $geography)
echo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s $epsg '$shapefile' $layername | psql -U $POSTGRES_USER -d $POSTGRES_DB"
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s $epsg '$shapefile' $layername | psql -U $POSTGRES_USER -d $POSTGRES_DB"
if [[ " $(jq 'keys' <<<$source) " =~ "subset" ]]
then
  where=$(jq '.subset' <<<$source) | tr -d '"'
  sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'DELETE FROM $layername WHERE $where;'"
fi
# rm -f $DATA_DIR/${filename%.*}.*
