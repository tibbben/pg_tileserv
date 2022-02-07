DATA_DIR=data
readarray -t collection < <(jq -c '.collection[]' $DATA_DIR/collection.json)

# first download all data
for item in "${collection[@]}"
do
        source=$(jq '.source' <<< $item)
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
done

DC_DIR=/usr/local/bin
ETL_DIR=$DATA_DIR/ETL
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. "$DIR/pg.env"

# second perform ETL
for item in "${collection[@]}"
do
        source=$(jq '.source' <<< $item)
        filename=$(jq -r '.filename' <<< $source)
        layername=$(jq -r '.layername' <<< $source)
        epsg=$(jq -r '.epsg' <<< $source)
        load=$(jq -r '.load' <<< $source)
        echo $DIR/$ETL_DIR/$load
        . "$DIR/$ETL_DIR/$load"
done
