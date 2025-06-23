class AddEsPlantillaToFormularioEventos < ActiveRecord::Migration[7.1]
  def change
    add_column :formulario_eventos, :es_plantilla, :boolean, default: false, null: false
    add_index :formulario_eventos, :es_plantilla
  end
end