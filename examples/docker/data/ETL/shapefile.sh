filename=/work/${filename::-4}.shp
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s $epsg $filename $layername | psql -U $POSTGRES_USER -d $POSTGRES_DB"
