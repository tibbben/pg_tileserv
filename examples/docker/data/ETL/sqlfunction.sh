#!/usr/bin/env bash

src=$(jq -r '.src' <<< $source)
cp $src ./$DATA_DIR/
echo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "cat /work/openlayers-function-click.sql | psql -U $POSTGRES_USER -d $POSTGRES_DB"
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "cat /work/openlayers-function-click.sql | psql -U $POSTGRES_USER -d $POSTGRES_DB"
# rm ./$DATA_DIR/$filename
