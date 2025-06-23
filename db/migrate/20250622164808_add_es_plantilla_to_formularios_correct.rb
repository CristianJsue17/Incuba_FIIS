class AddEsPlantillaToFormulariosCorrect < ActiveRecord::Migration[7.1]
  def change
    # Agregar campo es_plantilla a todas las tablas de formularios
    add_column :formulario_programa_preincubacions, :es_plantilla, :boolean, default: false, null: false
    add_column :formulario_programa_incubacions, :es_plantilla, :boolean, default: false, null: false
    add_column :formulario_programa_innovacions, :es_plantilla, :boolean, default: false, null: false
    
    # Agregar índices para optimizar consultas
    add_index :formulario_programa_preincubacions, [:program_id, :es_plantilla], 
              name: 'index_preincubacion_program_plantilla'
    add_index :formulario_programa_incubacions, [:program_id, :es_plantilla],
              name: 'index_incubacion_program_plantilla'
    add_index :formulario_programa_innovacions, [:program_id, :es_plantilla],
              name: 'index_innovacion_program_plantilla'
  end
end