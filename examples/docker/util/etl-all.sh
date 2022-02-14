#!/usr/bin/env bash

DATA_DIR=data
DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

# get the metadata collection
echo "$(jq -c '.collection[]' $DATA_DIR/html/collection/collection.json)" > temp.txt

for file in $DATA_DIR/SQL/*.sql
do
        file=/work/SQL/$(basename ${file})
        sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "cat $file | psql -U $POSTGRES_USER -d $POSTGRES_DB"
done

# third perform ETL
while read item
do
        source=$(jq '.source' <<< $item)
        geography=$(jq '.geography' <<< $item)
        filename=$(jq -r '.filename' <<< $source)
        layername=$(jq -r '.layername' <<< $source)
	echo ------------------------------ start $layername
        load=$(jq -r '.load' <<< $source)
        echo $DIR/$ETL_DIR/$load
        . "$DIR/$ETL_DIR/$load" </dev/null
	echo ------------------------------ done with $layername
done < temp.txt
echo done
# rm temp.txt
