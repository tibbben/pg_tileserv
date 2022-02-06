# Shortcuts to load all data in PostGIS DB in Docker Container
# NB the docker-compose stack must be running !
#

# first get data, this is a bit of a hack, it delays any DDL enough to have everything running before writing to the db
cd data
curl -X GET "https://opendata.vancouver.ca/explore/dataset/water-hydrants/download/?format=shp&timezone=America/Los_Angeles&lang=en&epsg=26910" > water-hydrants.zip
unzip water-hydrants.zip
wget "https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip" -O ne_50m_admin_0_countries.zip
unzip ne_50m_admin_0_countries.zip
wget "https://svi.cdc.gov/Documents/Data/2018_SVI_Data/States/Florida.zip" -O Florida_SVI_2018.zip
unzip Florida_SVI_2018.zip
wget "https://s3.amazonaws.com/dmap-cache-prod/soft/8cbe4cc7-654c-4514-be00-19f736267468.csv" -O Florida_TRI_2020.csv
cd ..

# make sure database is ready
sleep 10

#set up schema
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "cat work/DDL/*.sql | psql -v ON_ERROR_STOP=1 --username tileserv --dbname tileserv -tA -1"

# Load Admin 0 countries
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s 4326 /work/ne_50m_admin_0_countries.shp | psql -U tileserv -d tileserv"

# Load Vancouver Water Hydrants
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s 26910 -I /work/water-hydrants.shp hydrants | psql -U tileserv -d tileserv"

# Load SQL Functions for OpenLayers example
cp ../openlayers/openlayers-function-click.sql ./data/
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "cat /work/openlayers-function-click.sql | psql -U tileserv -d tileserv"
rm ./data/openlayers-function-click.sql

# Load SVI
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "shp2pgsql -D -s 4326 /work/SVI2018_FLORIDA_tract.shp | psql -U tileserv -d tileserv"

# load TRI
sed -i '1 s/\(.*\),$/\1/' data/Florida_TRI_2020.csv 
cat <<SQL | /usr/local/bin/sqlite3
.mode csv
.import data/Florida_TRI_2020.csv florida_tri_2020
.output data/Florida_TRI_2020.sql
.dump florida_tri_2020
.quit
SQL
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "cat /work/Florida_TRI_2020.sql | psql -U tileserv -d tileserv"
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "psql -U tileserv -d tileserv -c \"SELECT AddGeometryColumn ('public','florida_tri_2020','geom',4326,'POINT',2);\""
/usr/local/bin/docker-compose exec -T pg_tileserv_db sh -c "psql -U tileserv -d tileserv -c \"UPDATE florida_tri_2020 SET geom=ST_SetSRID(ST_MakePoint(\\\"13. LONGITUDE\\\"::double precision,\\\"12. LATITUDE\\\"::double precision),4326) WHERE \\\"13. LONGITUDE\\\" != 'NAD83';\""