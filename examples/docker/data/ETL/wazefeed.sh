python3 $ETL_DIR/wazefeed.py $DATA_DIR $filename
rm $DATA_DIR/$filename
for file in $DATA_DIR/*.json
do
  sudo $DC_DIR/docker-compose exec -T pg_gdal sh -c "ogr2ogr -f 'PostgreSQL' PG:'dbname=$POSTGRES_DB user=$POSTGRES_USER host=pg_tileserv_db password=$POSTGRES_PASSWORD' /$file"
  rm $file
done
