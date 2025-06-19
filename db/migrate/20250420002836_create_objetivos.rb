class CreateObjetivos < ActiveRecord::Migration[7.1]
  def change
    create_table :objetivos do |t|
      t.text :descripcion

      t.timestamps
    end
  end
end
