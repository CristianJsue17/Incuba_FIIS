class AddEstadoToFormularioEventos < ActiveRecord::Migration[7.1]
  def change
    # Agregar columna estado si no existe
    add_column :formulario_eventos, :estado, :string, default: 'pendiente' unless column_exists?(:formulario_eventos, :estado)
    
    # Agregar índices para mejorar performance
    add_index :formulario_eventos, :estado unless index_exists?(:formulario_eventos, :estado)
    add_index :formulario_eventos, [:event_id, :es_plantilla] unless index_exists?(:formulario_eventos, [:event_id, :es_plantilla])
    add_index :formulario_eventos, [:created_at] unless index_exists?(:formulario_eventos, [:created_at])
    
    # Actualizar registros existentes
    reversible do |dir|
      dir.up do
        # Asignar estado pendiente a registros existentes que no tengan estado
        execute "UPDATE formulario_eventos SET estado = 'pendiente' WHERE estado IS NULL OR estado = ''"
      end
    end
  end
end