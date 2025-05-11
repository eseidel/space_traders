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
    --name space_traders-db-1 \
    -p 127.0.0.1:5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=spacetraders \
    -e POSTGRES_PASSWORD=password \
    -d \
    postgres
```

### To get a shell
```
docker exec -it space_traders-db-1 /bin/sh
psql -U postgres -d spacetraders
```