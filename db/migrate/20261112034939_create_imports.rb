class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.string :filename, null: false

      # processing, completed or failed
      t.string :status, null: false, default: "processing"

      # Why the whole file was refused; empty unless status is failed
      t.string :failure_reason

      t.integer :processed_count, null: false, default: 0
      t.integer :created_count, null: false, default: 0
      t.integer :updated_count, null: false, default: 0
      t.integer :unchanged_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0

      t.integer :duration_ms

      t.timestamps
    end
  end
end
