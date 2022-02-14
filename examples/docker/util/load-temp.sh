#!/usr/bin/env bash

DATA_DIR=data
DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

# get the collection metadata
echo "$(jq -c '.collection[]' $DATA_DIR/html/collection/cut_collection.json)" > temp.txt

# third perform ETL
while read item
do
        source=$(jq '.source' <<< $item)
        geography=$(jq '.geography' <<< $item)
        filename=$(jq -r '.filename' <<< $source)
        layername=$(jq -r '.layername' <<< $source)
        load=$(jq -r '.load' <<< $source)
        echo $DIR/$ETL_DIR/$load
        . "$DIR/$ETL_DIR/$load"
done < temp.txt

rm temp.txt
