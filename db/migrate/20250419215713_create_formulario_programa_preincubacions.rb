class CreateFormularioProgramaPreincubacions < ActiveRecord::Migration[7.1]
  def change
    create_table :formulario_programa_preincubacions do |t|
      t.references :program, null: false, foreign_key: true
      t.string :nombre_emprendimiento
      t.text :descripcion
      t.text :propuesta_valor
      t.integer :numero_integrantes_equipo
      t.string :nombre_lider
      t.string :apellidos_lider
      t.string :dni_lider
      t.string :correo_lider
      t.string :telefono_lider
      t.string :ocupacion_lider
      t.string :enteraste_programa
      t.text :expectativas_programa

      t.timestamps
    end
  end
end
