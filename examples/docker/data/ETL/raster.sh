style=$(jq -r '.style' <<< $item)
torender=${filename::-4}.tif

if [[ " $(jq 'keys' <<<$style) " =~ ".monobandpsuedocolor" ]]
then
  colorramp=$(jq -r '.monobandpsuedocolor.colorramp' <<<$style)
  echo -e "$colorramp" > $DATA_DIR/colors.txt
  render=$(jq '.monobandpsuedocolor.render' <<<$style)
  torender=${filename::-4}_color.tif
  $DC_DIR/docker-compose exec -T pg_gdal sh -c "$render $filename $DATA_DIR/colors.txt $DATA_DIR/$torender"
  rm $DATA_DIR/colors.txt $DATA_DIR/$layername.*
fi

if [[ " $(jq 'keys' <<<$style) " =~ "tiles" ]]
then
  mkdir $DATA_DIR/html/$layername
  zoom=$(jq '.tiles.zoom' <<<$style)
  $DC_DIR/docker-compose exec -T pg_gdal sh -c "gdal2tiles.py -z $zoom --xyz -w none $DATA_DIR/$torender $DATA_DIR/tiles/$layername"
fi

rm $DATA_DIR/${torender::-4}.*
