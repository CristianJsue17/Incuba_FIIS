class CreateFormularioEventos < ActiveRecord::Migration[7.1]
  def change
    create_table :formulario_eventos do |t|
      t.references :event, null: false, foreign_key: true
      t.string :nombre_lider
      t.string :apellidos_lider
      t.string :dni_lider
      t.string :correo_lider
      t.string :telefono_lider
      t.integer :numero_integrantes_equipo
      t.string :nombre_emprendimiento
      t.text :descripcion
      t.text :cuentanos_proyecto
      t.text :atributos_ventaja_diferenciacion
      t.text :modelo_negocio
      t.text :indicadores_metas_6meses
      t.text :redes_sociales
      t.string :web_startup
      t.string :sector_economico
      t.string :categoria

      t.timestamps
    end
  end
end
