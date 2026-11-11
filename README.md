# Ava Project

A Ruby on Rails 8.1 application backed by PostgreSQL.

## Run it with Docker (recommended)

The only requirement is [Docker](https://docs.docker.com/get-docker/) with Docker Compose.

```bash
docker compose up --build
```

Then open <http://localhost:3000>. The health check is at <http://localhost:3000/up>.

This starts two containers:

- `db`: PostgreSQL 17
- `web`: the Rails app, which waits for the database, creates and migrates it, then starts the server

No keys or other configuration are needed.

If port 3000 is already in use, pick another one:

```bash
PORT=8080 docker compose up --build
```

To stop the app, press `Ctrl-C`, or run `docker compose down`. Add `-v` to also delete the database data.

## Run it without Docker (development)

Requires Ruby 3.4.12. The database still runs in Docker:

```bash
docker compose up -d db   # PostgreSQL on localhost:5433
bin/setup                 # install gems, prepare the database, start the server
```

Later, start the server with `bin/dev`.

To use your own PostgreSQL server instead, set `DB_HOST`, `DB_PORT`, `DB_USER` and `DB_PASSWORD`.

## Run the tests

```bash
docker compose up -d db
bin/rails test
```
