## setup

```
docker pull postgres
docker run \
    --name spacetraders_postgres \
    -p 5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_DB=spacetraders \
    -e POSTGRES_PASSWORD=password \
    -d \
    postgres
```

```
docker cp scripts/ spacetraders_postgres:/scripts
docker cp sql/ spacetraders_postgres:/sql
```

```
docker exec spacetraders_postgres /scripts/init_db.sh spacetraders
```