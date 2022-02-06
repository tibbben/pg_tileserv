DATADIR=data
readarray -t collection < <(jq -c '.collection[]' collection.json)
for item in "${collection[@]}"
do
        source=$(jq '.source' <<< $item)
        command=($(jq -r '.download' <<< $source))
        url=$(jq '.url' <<< $source)

        command+=($url)
        filename=$(jq -r '.filename' <<< $source)
        save='> '$DATADIR/$filename
        if [ $command == "wget" ]
        then
                save=-'O '$DATADIR/$filename
        fi
        command+=($save)
        echo "${command[@]}"
        if [ $(jq -r '.format' <<< $source) == "zip" ]
        then
                echo unzip $DATADIR/$(jq -r '.filename' <<< $source) -d $DATADIR
        fi
done
