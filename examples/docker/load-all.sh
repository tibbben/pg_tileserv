#!/usr/bin/env bash

DATA_DIR=data
DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

# get the metadata collection
echo "$(jq -c '.collection[]' $DATA_DIR/html/collection/public_collection.json)" > temp.txt

# first download all data
while read item
do
        source=$(jq '.source' <<< $item)
        if [[ " $(jq 'keys' <<<$source) " =~ "download" ]];
        then

                # construct the download url
                command=($(jq -r '.download' <<< $source))
                if [[ " $(jq 'keys' <<<$source) " =~ "token" ]];
                then
                        name=$(jq -r '.token' <<< $source)
                        token=$(<secrets/$name.txt)
                        flags=$(jq -r '.flags' <<< $source)
                        flags=$(echo $flags | sed "s/$name/$token/")
                        command=$command$flags

                fi
                url=$(jq '.url' <<< $source)
                command+=($url)
                if [[ " $(jq 'keys' <<<$source) " =~ "parameter" ]];
                then
                        parameter=($(jq -r '.parameter' <<< $source))
                        command+=($parameter)
                fi

                # construct the output/save location
                filename=$(jq -r '.filename' <<< $source)
                save='> '$DATA_DIR/$filename
                if [ $command == "wget" ]
                then
                        save=-'O '$DATA_DIR/$filename
                fi
                command+=($save)

                # download
                echo "${command[@]}"
                eval "${command[@]}"

                # unzip if needed
                if [ $(jq -r '.format' <<< $source) == "zip" ] || [ $(jq -r '.format' <<< $source) == "kmz" ]
                then
                        filename=$(jq -r '.filename' <<< $source)
                        echo unzip -ou $DATA_DIR/$filename -d $DATA_DIR
                        unzip -ou $DATA_DIR/$filename -d $DATA_DIR
                        chmod 755 $DATA_DIR/${filename%.*}.*
                        #rm $DATA_DIR/$filename
                fi
        fi
done < temp.txt

# second load all extra SQL functions
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

# rm temp.txt
