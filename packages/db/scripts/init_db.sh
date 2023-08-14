#!/bin/bash
# 
# This script will drop all tables and re-create them.
# Usage: ./scripts/init_db.sh <database_name>

DB_NAME=$1

if [ -z "$DB_NAME" ]; then
    echo "Please provide a database name."
    exit 1
fi

# Create the database if it doesn't exist
psql -U postgres -c "CREATE DATABASE $DB_NAME"

# Drop the tables if the exist.
psql -U postgres -d $DB_NAME -f sql/flows/drop_tables.sql

# Create the tables.
psql -U postgres -d $DB_NAME -f sql/tables/01_request.sql
psql -U postgres -d $DB_NAME -f sql/tables/02_response.sql
psql -U postgres -d $DB_NAME -f sql/tables/03_transaction.sql
psql -U postgres -d $DB_NAME -f sql/tables/04_survey.sql
psql -U postgres -d $DB_NAME -f sql/tables/05_faction.sql
psql -U postgres -d $DB_NAME -f sql/tables/06_behavior.sql
psql -U postgres -d $DB_NAME -f sql/tables/07_extraction.sql