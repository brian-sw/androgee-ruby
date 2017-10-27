#!/bin/bash

sed -i s/_DISCORDTOKEN_/$DISCORD_TOKEN/g dockerfile
docker build . -t discord

git clone
git clone https://github.com/egee-irl/andro-wrcon.git
cd andro-wrcon
sed -i s/localhost/redis/g main.coffee

sed -i s/_RUSTIP_/$RUST_IP/g dockerfile
sed -i s/_RUSTPORT_/$RUST_PORT/g dockerfile
sed -i s/_RUSTPASSWORD_/$RUST_PASSWORD/g dockerfile

docker build . -t wrcon

cd .. && docker-compose up
