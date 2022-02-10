#!/usr/bin/env bash

DATA_DIR=data
DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

# get the metadata collection
echo "$(jq -c '.collection[]' $DATA_DIR/html/collection/collection.json)" > temp.txt

# first download all data
while read item
do
        source=$(jq '.source' <<< $item)
        if [[ " $(jq 'keys' <<<$source) " =~ "download" ]];
        then
                command=($(jq -r '.download' <<< $source))
                url=$(jq '.url' <<< $source)

                command+=($url)
                filename=$(jq -r '.filename' <<< $source)
                save='> '$DATA_DIR/$filename
                if [ $command == "wget" ]
                then
                        save=-'O '$DATA_DIR/$filename
                fi
                command+=($save)
                echo "${command[@]}"
                eval "${command[@]}"
                if [ $(jq -r '.format' <<< $source) == "zip" ]
                then
                        unzip $DATA_DIR/$(jq -r '.filename' <<< $source) -d $DATA_DIR
                        rm $DATA_DIR/$filename
                fi
        fi
done < temp.txt

