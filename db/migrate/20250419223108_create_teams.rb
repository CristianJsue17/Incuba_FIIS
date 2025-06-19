class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.string :nombre_equipo
      t.string :nombre_lider
      t.integer :cantidad_miembros
      t.text :lista_integrantes_equipo
      t.references :mentor, null: false, foreign_key: { to_table: :users } #mentor es un tipo de usuario
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
