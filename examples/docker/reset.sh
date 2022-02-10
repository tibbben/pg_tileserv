sudo /usr/local/bin/docker-compose down
sudo docker volume prune
rm data/*.*
sudo /usr/local/bin/docker-compose up -d
