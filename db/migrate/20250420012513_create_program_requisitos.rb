class CreateProgramRequisitos < ActiveRecord::Migration[7.1]
  def change
    create_table :program_requisitos do |t|
      t.references :program, null: false, foreign_key: true
      t.references :requisito, null: false, foreign_key: true

      t.timestamps
    end
  end
end
