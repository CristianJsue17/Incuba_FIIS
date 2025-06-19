class CreateProgramsPatrocinadors < ActiveRecord::Migration[7.1]
  def change
    create_table :programs_patrocinadors do |t|
      t.references :program, null: false, foreign_key: true
      t.references :patrocinador, null: false, foreign_key: { to_table: :patrocinadors } # Assuming you have a Patrocinador model

      t.timestamps
    end
  end
end
