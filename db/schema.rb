# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_11_12_034945) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "import_errors", force: :cascade do |t|
    t.bigint "import_id", null: false
    t.integer "line_number", null: false
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["import_id"], name: "index_import_errors_on_import_id"
  end

  create_table "imports", force: :cascade do |t|
    t.string "filename", null: false
    t.string "status", default: "processing", null: false
    t.string "failure_reason"
    t.integer "processed_count", default: 0, null: false
    t.integer "created_count", default: 0, null: false
    t.integer "updated_count", default: 0, null: false
    t.integer "unchanged_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.integer "duration_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "patients", force: :cascade do |t|
    t.string "health_identifier", null: false
    t.string "health_identifier_province", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_name"
    t.string "phone"
    t.string "email"
    t.string "address_1"
    t.string "address_2"
    t.string "address_province"
    t.string "address_city"
    t.string "address_postal_code"
    t.date "date_of_birth"
    t.string "sex"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["health_identifier_province", "health_identifier"], name: "idx_on_health_identifier_province_health_identifier_f9357a65d5", unique: true
  end

  add_foreign_key "import_errors", "imports"
end
