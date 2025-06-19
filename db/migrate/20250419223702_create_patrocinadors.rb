class CreatePatrocinadors < ActiveRecord::Migration[7.1]
  def change
    create_table :patrocinadors do |t|
      t.string :nombre
      t.string :campo_laboral
      t.text :mensaje
      t.string :url
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
