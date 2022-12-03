#!/usr/bin/env bash

url=$(jq '.url' <<< $source | tr -d '"')
wfstypes=$(jq -r '.wfstypes' <<<$source)
wfstypes=$(echo $wfstypes | tr -d "[]" | tr "," "\n" | tr -d '"')
layername=$(echo $layername | tr -d "[]" | tr -d '"')
IFS=', ' read -r -a layername <<< "$layername"
epsg=$(jq '.epsg' <<< $geography | tr -d '"')
typenum=0
for type in $wfstypes
do
  echo $DC_DIR/docker-compose exec -T pg_gdal sh \
  -c "ogr2ogr -overwrite -lco GEOMETRY_NAME=geom -f 'PostgreSQL' -t_srs EPSG:$epsg PG:'dbname=tileserv user=tileserv host=pg_tileserv_db password=tileserv' -nln ${layername[typenum]} '$url&request=GetFeature&typeNames=namespace:$type&srsName=EPSG:$epsg'"
  sudo $DC_DIR/docker-compose exec -T pg_gdal sh \
  -c "ogr2ogr -overwrite -lco GEOMETRY_NAME=geom -f 'PostgreSQL' -t_srs EPSG:$epsg PG:'dbname=tileserv user=tileserv host=pg_tileserv_db password=tileserv' -nln ${layername[typenum]} '$url&request=GetFeature&typeNames=namespace:$type&srsName=EPSG:$epsg'"
  typenum=$((typenum+1))
done
