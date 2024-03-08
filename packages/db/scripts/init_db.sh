#!/bin/bash
# 
# This script will drop all tables and re-create them.
# Usage: ./scripts/init_db.sh

DB_NAME=spacetraders

# Create the database if it doesn't exist
psql -U postgres -c "CREATE DATABASE $DB_NAME"

# Drop the tables if the exist.
psql -U postgres -d $DB_NAME -f sql/flows/drop_tables.sql

# Create the tables.
table_sqls=`ls sql/tables/*.sql`
for sql_path in $table_sqls
do
    psql -U postgres -d $DB_NAME -f $sql_path
done
