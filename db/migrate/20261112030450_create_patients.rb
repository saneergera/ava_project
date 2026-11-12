class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.string :health_identifier, null: false
      t.string :health_identifier_province, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :middle_name
      t.string :phone
      t.string :email

      t.string :address_1
      t.string :address_2
      t.string :address_province
      t.string :address_city
      t.string :address_postal_code

      t.date :date_of_birth
      t.string :sex
      t.timestamps
    end
    add_index :patients, [ :health_identifier_province, :health_identifier ], unique: true
  end
end
