#!/bin/bash

set -e

PGPASSWORD=password
PGUSER=postgres
CONTINER_NAME=spacetraders_postgres
DB_NAME=spacetraders

docker exec -e PGPASSWORD=$PGPASSWORD $CONTINER_NAME pg_dump $DB_NAME -U $PGUSER > spacetraders.sql