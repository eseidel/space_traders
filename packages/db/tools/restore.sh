#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
cd ..
docker cp scripts/. space_traders-db-1:/scripts
docker cp sql/. space_traders-db-1:/sql
docker exec space_traders-db-1 /scripts/restore.sh