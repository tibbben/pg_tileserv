#!/usr/bin/env bash

HOME_DIR=/home/ec2-user/pg_tileserv/examples/docker
DATA_DIR=data
DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

cd $HOME_DIR
echo $(pwd)
echo Start: $(date '+%Y-%m-%d %H:%M:%S')

# USGS Earthquake feed
curl https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.geojson > $DATA_DIR/all_month.geojson
$DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'DROP TABLE all_month;'"
$DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr -nlt POINTZ -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/all_month.geojson"
rm $DATA_DIR/all_month.geojson

# Waze feed
curl "https://na-georss.waze.com/rtserver/web/TGeoRSS?tk=ccp_partner&format=JSON&types=traffic%2Calerts%2Cirregularities&polygon=-80.214000%2C25.810000%3B-80.359000%2C25.807000%3B-80.486000%2C25.805000%3B-80.481000%2C25.568000%3B-80.294000%2C25.566000%3B-80.272000%2C25.625000%3B-80.235000%2C25.715000%3B-80.184000%2C25.761000%3B-80.186000%2C25.811000%3B-80.214000%2C25.810000%3B-80.214000%2C25.810000" > $DATA_DIR/wazefeed.json
python3 $ETL_DIR/wazefeed.py $DATA_DIR wazefeed.json
rm $DATA_DIR/wazefeed.json
for tablename in "alerts" "irregularities" "jams"
do
  $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'DROP TABLE IF EXISTS $tablename;'" </dev/null
done
for file in $DATA_DIR/*.json
do
  filename=$(basename -- "$file")
  $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' $DATA_DIR/$filename" </dev/null
  rm $file
done

echo End: $(date '+%Y-%m-%d %H:%M:%S')
