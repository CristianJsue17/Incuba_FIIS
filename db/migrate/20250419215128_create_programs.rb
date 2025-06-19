class CreatePrograms < ActiveRecord::Migration[7.1]
  def change
    create_table :programs do |t|
      t.string :titulo
      t.text :descripcion
      t.string :encargado
      t.string :tipo
      t.timestamp :fecha_publicacion
      t.timestamp :fecha_vencimiento
      t.string :estado
      t.references :user, null: false, foreign_key: true
      #t.references :ocupacion, null: false, foreign_key: true  #no necesita ocupacion
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
