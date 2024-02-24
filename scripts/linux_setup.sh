#!/bin/bash

set -e

# CAUTION, this script is lazy and just overwrites .zshrc, rather than
# trying to add to it.

# Path is needed for pub global activate
# BOT=true is needed to make flutter/dart not whine about using root user.
RC_FILE=";export PATH=\"\$PATH:$HOME/.pub-cache/bin\";export BOT=true;"
# Append to .bashrc if it exists, otherwise create it.
echo $RC_FILE >> $HOME/.bashrc
source $HOME/.bashrc

# https://stackoverflow.com/questions/359109/using-the-scrollwheel-in-gnu-screen
SCREEN_RC="termcapinfo xterm* ti@:te@"
echo $SCREEN_RC > $HOME/.screenrc

snap install flutter --classic
# Let flutter finish installing itself.
flutter --version

# Pub get for all the packages.
dart pub global activate very_good_cli
very_good packages get -r

snap install docker

cd packages/db
docker pull postgres
docker run \
    --name spacetraders_postgres \
    -p 127.0.0.1:5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=spacetraders \
    -e POSTGRES_PASSWORD=password \
    -d \
    postgres

docker cp scripts/. spacetraders_postgres:/scripts
docker cp sql/. spacetraders_postgres:/sql

docker exec spacetraders_postgres /scripts/init_db.sh spacetraders
