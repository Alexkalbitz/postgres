# Start the docker container
docker run -d -t \
    --name dj_postgres \
    -p 5555:5432 \
    -e POSTGRES_USER=root \
    -e POSTGRES_PASSWORD= \
    postgres:11.6

# Destroy the docker container
docker rm -f dj_postgres

# Connection to postgres via CLI
docker exec -ti dj_postgres /bin/bash -c psql

# Datagrip url:
# https://www.jetbrains.com/datagrip/download

# Import example database
docker exec -i dj_postgres /bin/bash -c psql < dvdrental_dump.sql
