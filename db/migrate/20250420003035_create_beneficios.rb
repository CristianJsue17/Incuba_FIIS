class CreateBeneficios < ActiveRecord::Migration[7.1]
  def change
    create_table :beneficios do |t|
      t.text :descripcion

      t.timestamps
    end
  end
end
