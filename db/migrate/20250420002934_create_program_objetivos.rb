class CreateProgramObjetivos < ActiveRecord::Migration[7.1]
  def change
    create_table :program_objetivos do |t|
      t.references :program, null: false, foreign_key: true
      t.references :objetivo, null: false, foreign_key: true

      t.timestamps
    end
  end
end
