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
curl "https://na-georss.waze.com/rtserver/web/TGeoRSS?tk=ccp_partner&format=JSON&types=traffic%2Calerts%2Cirregularities&polygon=-80.873124%2C25.760866%3B-80.872932%2C25.979434%3B-80.680038%2C25.978749%3B-80.680016%2C25.956857%3B-80.351384%2C25.956963%3B-80.294972%2C25.95677%3B-80.295187%2C25.97057%3B-80.278764%2C25.970968%3B-80.165724%2C25.973783%3B-80.123874%2C25.974484%3B-80.117798019680592%2C25.975152100031597%3B-80.111366842388989%2C25.700883883523296%3B-80.149265839783681%2C25.509609618567772%3B-80.234933618489734%2C25.347053471127754%3B-80.31036%2C25.3731%3B-80.407755%2C25.256811%3B-80.723335345852362%2C25.159074670963498%3B-80.857985411542899%2C25.1766094650017%3B-80.862191%2C25.364193%3B-80.87319%2C25.363993%3B-80.873124%2C25.760866" > $DATA_DIR/wazefeed.json
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
