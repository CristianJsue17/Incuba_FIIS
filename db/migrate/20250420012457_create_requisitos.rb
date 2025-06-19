class CreateRequisitos < ActiveRecord::Migration[7.1]
  def change
    create_table :requisitos do |t|
      t.text :descripcion

      t.timestamps
    end
  end
end
