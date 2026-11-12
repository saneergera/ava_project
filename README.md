# Patient Migration

A Ruby on Rails 8.1 application that imports a CSV file of patient demographics into PostgreSQL.

- Upload a CSV and see what happened to every row: created, updated, unchanged or failed.
- Uploading the same file again never duplicates patients.
- Rows with invalid data are rejected with the CSV line number and the reason; valid rows are still imported.

## Run it with Docker (recommended)

The only requirement is [Docker](https://docs.docker.com/get-docker/) with Docker Compose.

```bash
docker compose up --build
```

Then open <http://localhost:3000>.

This starts two containers:

- `db`: PostgreSQL 17
- `web`: the Rails app, which waits for the database, creates and migrates it, then starts the server

No keys or other configuration are needed.

If port 3000 is already in use, pick another one:

```bash
PORT=8080 docker compose up --build
```

To stop the app, press `Ctrl-C`, or run `docker compose down`. Add `-v` to also delete the database data.

## Try it

A sample file is included at `test/fixtures/files/patients.csv` (20 rows).

1. Open the app and upload the sample file. The details page shows 16 created and 4 failed, with a reason for each failed line.
2. Upload the same file again. It shows 0 created, 16 unchanged and 4 failed.
3. Open **Patients**: there are still 16 patients.

## Screens

| Screen | URL | Shows |
|---|---|---|
| Upload CSV | `/` | A file picker and a Start Migration button |
| Migration history | `/imports` | Every upload with its file name, date, status and counts |
| Migration details | `/imports/:id` | Rows processed, created, updated, unchanged and failed, the duration, and the reason for each rejected row |
| Patients | `/patients` | A read-only list of the patients in the database |

## How the import works

A patient is identified by **health identifier province + health identifier**. A unique database index on those two columns guarantees that a patient is stored only once.

For each row of the file:

1. Values are cleaned to one stored format: province names become two-letter codes, phone numbers become ten digits, postal codes become `A1A 1A1`, email is lowercased.
2. The row is validated. A row with a malformed value, or without a health identifier, province, first name or last name, is rejected with the reason. Other fields may be blank.
3. The patient is looked up by province and health identifier, then created, updated or left unchanged.

Other rules:

- A blank value never erases a value that is already stored.
- If the same patient appears twice in one file, the first row is used and the later one is rejected.
- A file that is not a readable CSV, is empty, or is missing a column is refused as a whole.

## Where the code is

| Path | Purpose |
|---|---|
| `app/services/patient_importer.rb` | Reads the CSV and imports each row |
| `app/models/patient.rb` | Cleaning and validation rules for a patient |
| `app/models/import.rb`, `app/models/import_error.rb` | One record per upload, and one per rejected line |
| `app/controllers/imports_controller.rb` | Upload, history and details screens |
| `db/migrate/` | Database tables, constraints and the unique index |
| `test/` | Automated tests |

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

The tests cover importing the same file twice, rejecting invalid rows, updating existing patients, and the result of the sample file.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_PORT` | `5433` | PostgreSQL port |
| `DB_USER` | `postgres` | PostgreSQL user |
| `DB_PASSWORD` | `postgres` | PostgreSQL password |
| `PORT` | `3000` | Port the app is published on by Docker Compose |
| `SECRET_KEY_BASE` | set in `compose.yaml` | Signs session cookies; the value in `compose.yaml` is for local use only |

## Limitations

- There is no login; anyone who can reach the app can see patient data.
- The import runs during the upload request, which suits small files. Uploads are limited to 5 MB.
- Health identifiers must be digits only.

Styling uses [Bootstrap](https://getbootstrap.com/) (MIT licence), included as a single CSS file.
