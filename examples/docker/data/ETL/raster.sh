style=$(jq -r '.style' <<< $item)
torender=$filename

if [[ " $(jq 'keys' <<<$style) " =~ "monoband-psuedo-color" ]]
then
  color_ramp=$(jq '.monoband-psuedo-color.color-ramp' <<<$style)
  echo $color_ramp > $DATA_DIR/colors.txt
  render=$(jq '.monoband-psuedo-color.render' <<<$style)
  torender=${filename::-4}_color.tif
  $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "$render $filename $DATA_DIR/colors.txt $DATA_DIR/$torender"
  rm $DATA_DIR/colors.txt $DATA_DIR/$filename
fi

if [[ " $(jq 'keys' <<<$style) " =~ "tiles" ]]
then
  mkdir $DATA_DIR/tiles/$layername
  zoom=$(jq '.tiles.zoom' <<<$style)
  $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "gdal2tiles.py -z $zoom --xyz $DATA_DIR/$torender $DATA_DIR/tiles/$layername"
fi

rm $DATA_DIR/$torender