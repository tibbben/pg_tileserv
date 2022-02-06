readarray -t collection < <(jq -c '.collection' collection.json)
for item in "${collection[@]}"
do
        source=$(jq '.source' <<< $item)
        readarray -t params < <(jq -r '.params | to_entries[] | "\(.key + " " + .value)"' <<< $source)
        echo $(jq -r '.download' <<< $source) $(jq '.url' <<< $source) $(for p in "${params[@]}"; do echo  $p; done)
        if [ $(jq -r '.format' <<< $source) == "zip" ]
        then
                echo unzip $(jq -r '.filename' <<< $source)
        fi
done