style=$(jq -r '.style' <<< $item)
filename=${filename::-4}.tif
torender=$filename

if [[ " $(jq 'keys' <<<$style) " =~ "monobandpsuedocolor" ]]
then
  colorramp=$(jq -r '.monobandpsuedocolor.colorramp' <<<$style)
  echo -e "$colorramp" > $DATA_DIR/colors.txt
  flags=$(jq -r '.monobandpsuedocolor.flags' <<<$style)
  torender=${filename::-4}_color.tif
  sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "gdaldem color-relief $flags $DATA_DIR/$filename $DATA_DIR/colors.txt $DATA_DIR/$torender"
  rm $DATA_DIR/colors.txt $DATA_DIR/$layername.*
fi

if [[ " $(jq 'keys' <<<$style) " =~ "tiles" ]]
then
  sudo mkdir $DATA_DIR/html/$layername
  zoom=$(jq -r '.tiles.zoom' <<<$style)
  sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "gdal2tiles.py -z $zoom --xyz -w none $DATA_DIR/$torender $DATA_DIR/html/$layername"
  sudo chown -R $(whoami):$(whoami) $DATA_DIR/html/$layername
  sudo echo "*.png" > $DATA_DIR/html/$layername/.gitignore
fi

sudo rm $DATA_DIR/${torender::-4}.*
