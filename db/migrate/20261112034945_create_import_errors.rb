class CreateImportErrors < ActiveRecord::Migration[8.1]
  def change
    create_table :import_errors do |t|
      t.references :import, null: false, foreign_key: true

      # Line in the CSV file; the header is line 1
      t.integer :line_number, null: false

      # Only the reason is stored, never the patient's data
      t.string :message, null: false

      t.timestamps
    end
  end
end
