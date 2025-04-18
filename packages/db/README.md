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

docker exec -it spacetraders_postgres /bin/sh

```
docker exec space_traders-db-1 /scripts/init_db.sh spacetraders
```