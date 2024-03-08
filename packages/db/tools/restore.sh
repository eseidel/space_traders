#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR
cd ..
docker cp scripts/. spacetraders_postgres:/scripts
docker cp sql/. spacetraders_postgres:/sql
docker exec spacetraders_postgres /scripts/restore.sh