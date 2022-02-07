long=$(jq -r '.geometry_columns.longitude' <<< $source)
lat=$(jq -r '.geometry_columns.latitude' <<< $source)
epsg=$(jq -r '.epsg' <<< $source)
# use sqlite3 as a tool for csv ETL 
sed -i '1 s/\(.*\),$/\1/' $DATA_DIR/$filename 
cat <<SQL | /usr/local/bin/sqlite3
.mode csv
.import $DATA_DIR/$filename $layername
.output $DATA_DIR/$layername.sql
.dump $layername
.quit
SQL
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "cat /work/$layername.sql $layername | psql -U $POSTGRES_USER -d $POSTGRES_DB"
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"SELECT AddGeometryColumn ('public','$layername','geom',$epsg,'POINT',2);\""
# the where clause in the following command is a hack for missing data that was messing with the ETL
sudo $DC_DIR/docker-compose exec -T pg_tileserv_db sh -c "psql -U $POSTGRES_USER -d $POSTGRES_DB -c \"UPDATE $layername SET geom=ST_SetSRID(ST_MakePoint(\\\"$long\\\"::double precision,\\\"$lat\\\"::double precision),$epsg) WHERE \\\"$long\\\" != 'NAD83';\""
rm $DATA_DIR/$filename $DATA_DIR/$layername.sql
