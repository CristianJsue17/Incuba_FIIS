class CreateProgramBeneficios < ActiveRecord::Migration[7.1]
  def change
    create_table :program_beneficios do |t|
      t.references :program, null: false, foreign_key: true
      t.references :beneficio, null: false, foreign_key: true

      t.timestamps
    end
  end
end
