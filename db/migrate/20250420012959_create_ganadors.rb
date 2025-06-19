class CreateGanadors < ActiveRecord::Migration[7.1]
  def change
    create_table :ganadors do |t|
      t.references :equipo, foreign_key: { to_table: :teams } # referencia a la tabla teams
      t.references :project, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true  #si se rellena el campo program_id va 'No' en evento
      t.references :event, null: false, foreign_key: true
      t.decimal :monto_ganado

      t.timestamps
    end
  end
end
