class CreateEquipoIncubas < ActiveRecord::Migration[7.1]
  def change
    create_table :equipo_incubas do |t|
      t.string :nombre
      t.string :apellido
      t.string :cargo
      t.references :user, null: false, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
