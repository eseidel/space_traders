# Database

package:db is an internal package for storing state in a Postgres database.

## Setup

You will need Docker. On Ubuntu:
```
snap install docker
```

```
docker pull postgres
docker run \
    --name spacetraders_postgres \
    -p 127.0.0.1:5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=spacetraders \
    -e POSTGRES_PASSWORD=password \
    -d \
    postgres
```

```
docker cp scripts/. space_traders-db-1:/scripts
docker cp sql/. space_traders-db-1:/sql
```

### To run a single sql
docker exec -it space_traders-db-1 psql -U postgres -d spacetraders -f /sql/tables/19_static_data.sql


### To get a shell
docker exec -it space_traders-db-1 /bin/sh


### To init the whole db
```
docker exec space_traders-db-1 /scripts/init_db.sh spacetraders
```