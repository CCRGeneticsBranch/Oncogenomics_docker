#sudo docker build --build-arg INCUBATOR_VER=$(date +%s) -t hsienchao/oncogenomics:latest .
export now=$(date +%s)
sudo docker compose up --build -d
