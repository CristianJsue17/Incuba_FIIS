class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :nombre
      t.references :equipo, null: false, foreign_key: { to_table: :teams } #equipo es un equipo de teams
      t.references :lider, null: false, foreign_key: { to_table: :users } #lider es un tipo de usuario (particpante)
      t.string :tipo
      t.boolean :gano
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
