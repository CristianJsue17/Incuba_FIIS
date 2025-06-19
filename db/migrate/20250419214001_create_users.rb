class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :nombre
      t.string :apellido
      t.string :correo
      t.string :contrasenia
      t.text :descripcion
      t.string :telefono
      t.timestamp :ultimo_acceso
      t.string :facultad
      t.string :estado
      t.string :dni
      t.integer :cantidad_miembros_equipo
      t.string :nombre_proyectos
      t.string :proviene
      t.string :tipo
      t.references :occupation, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
