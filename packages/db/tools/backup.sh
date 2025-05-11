#!/bin/bash

set -e

PGPASSWORD=password
PGUSER=postgres
CONTAINER_NAME=space_traders-db-1
DB_NAME=spacetraders

docker exec -e PGPASSWORD=$PGPASSWORD $CONTAINER_NAME pg_dump $DB_NAME -U $PGUSER > spacetraders.sql