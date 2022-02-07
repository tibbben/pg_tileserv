style=$(jq -r '.style' <<< $item)
torender=${filename::-4}.tif

if [[ " $(jq 'keys' <<<$style) " =~ ".monobandpsuedocolor" ]]
then
  color_ramp=$(jq '.monobandpsuedocolor.colorramp' <<<$style)
  echo $color_ramp > $DATA_DIR/colors.txt
  render=$(jq '.monobandpsuedocolor.render' <<<$style)
  torender=${filename::-4}_color.tif
  $DC_DIR/docker-compose exec -T pg_gdal sh -c "$render $filename $DATA_DIR/colors.txt $DATA_DIR/$torender"
  rm $DATA_DIR/colors.txt $DATA_DIR/$layername.*
fi

if [[ " $(jq 'keys' <<<$style) " =~ "tiles" ]]
then
  [ ! -d "$DATA_DIR/tiles" ] && mkdir $DATA_DIR/tiles
  mkdir $DATA_DIR/tiles/$layername
  zoom=$(jq '.tiles.zoom' <<<$style)
  $DC_DIR/docker-compose exec -T pg_gdal sh -c "gdal2tiles.py -z $zoom --xyz $DATA_DIR/$torender $DATA_DIR/tiles/$layername"
fi

rm $DATA_DIR/${torender::-4}.*
