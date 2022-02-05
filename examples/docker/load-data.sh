# Shortcuts to load all data in PostGIS DB in Docker Container
# NB the docker-compose stack must be running !
#

#set up schema
docker-compose exec pg_tileserv_db sh -c "cat work/DDL/*.sql | psql -v ON_ERROR_STOP=1 --username tileserv --dbname tileserv -tA -1"

# first get data
curl -X GET "https://opendata.vancouver.ca/explore/dataset/water-hydrants/download/?format=shp&timezone=America/Los_Angeles&lang=en&epsg=26910" > data/water-hydrants.zip
unzip data/water-hydrants.zip -d data
curl -X GET "https://www.naturalearthdata.com/http//www.naturalearthdata.com/download/50m/cultural/ne_50m_admin_0_countries.zip" > data/ne_50m_admin_0_countries.zip
unzip data/ne_50m_admin_0_countries.zip -d data
curl -X GET "https://svi.cdc.gov/Documents/Data/2018_SVI_Data/States/Florida.zip" > data/Florida_SVI_2018.zip
unzip data/Florida_SVI_2018.zip -d data
curl -X GET "https://s3.amazonaws.com/dmap-cache-prod/soft/8cbe4cc7-654c-4514-be00-19f736267468.csv" > data/Florida_TRI_2020.csv

# Load Admin 0 countries
docker-compose exec pg_tileserv_db sh -c "shp2pgsql -D -s 4326 /work/ne_50m_admin_0_countries.shp | psql -U tileserv -d tileserv"

# Load Vancouver Water Hydrants
docker-compose exec pg_tileserv_db sh -c "shp2pgsql -D -s 26910 -I /work/water-hydrants.shp hydrants | psql -U tileserv -d tileserv"

# Load SQL Functions for OpenLayers example
cp ../openlayers/openlayers-function-click.sql ./data/
docker-compose exec pg_tileserv_db sh -c "cat /work/openlayers-function-click.sql | psql -U tileserv -d tileserv"
rm ./data/openlayers-function-click.sql

# Load SVI
docker-compose exec pg_tileserv_db sh -c "shp2pgsql -D -s 4326 /work/SVI2018_FLORIDA_tract.shp | psql -U tileserv -d tileserv"

# load TRI
sed -i '1 s/\(.*\),$/\1/' data/Florida_TRI_2020.csv 
sed -i 's/(?<!\n|,)"(?!(,|$))//' data/Florida_TRI_2020.csv
cat <<SQL | /usr/local/bin/sqlite3
.mode csv
.import data/Florida_TRI_2020.csv florida_tri_2020
.output data/Florida_TRI_2020.sql
.dump florida_tri_2020
.quit
SQL
docker-compose exec pg_tileserv_db sh -c "cat /work/Florida_TRI_2020.sql | psql -U tileserv -d tileserv"
docker-compose exec pg_tileserv_db sh -c "psql -U tileserv -d tileserv -c \"SELECT AddGeometryColumn ('public','florida_tri_2020','geom',4326,'POINT',2);\""
docker-compose exec pg_tileserv_db sh -c "psql -U tileserv -d tileserv -c \"UPDATE florida_tri_2020 SET geom=ST_SetSRID(ST_MakePoint(\\\"13. LONGITUDE\\\"::double precision,\\\"12. LATITUDE\\\"::double precision),4326) WHERE \\\"13. LONGITUDE\\\" != 'NAD83';\""