class CreateFormularioProgramaInnovacions < ActiveRecord::Migration[7.1]
  def change
    create_table :formulario_programa_innovacions do |t|
      t.references :program, null: false, foreign_key: true
      t.string :nombre_lider
      t.string :apellido_lider
      t.string :dni_lider
      t.string :telefono_lider
      t.string :correo_lider
      t.string :nombre_proyecto

      t.timestamps
    end
  end
end
