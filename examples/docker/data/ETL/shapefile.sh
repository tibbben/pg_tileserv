shapefile=/work/${filename::-4}.shp
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s $epsg $shapefile $layername | psql -U $POSTGRES_USER -d $POSTGRES_DB"
rm -f $DATA_DIR/${filename::-4}.*
