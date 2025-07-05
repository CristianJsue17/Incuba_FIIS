class AddEstadoToFormularios < ActiveRecord::Migration[7.1]
  def change
    # Agregar estado a FormularioProgramaPreincubacion
    add_column :formulario_programa_preincubacions, :estado, :string, default: 'pendiente', null: false
    add_index :formulario_programa_preincubacions, :estado
    
    # Agregar estado a FormularioProgramaIncubacion
    add_column :formulario_programa_incubacions, :estado, :string, default: 'pendiente', null: false
    add_index :formulario_programa_incubacions, :estado
    
    # Agregar estado a FormularioProgramaInnovacion
    add_column :formulario_programa_innovacions, :estado, :string, default: 'pendiente', null: false
    add_index :formulario_programa_innovacions, :estado
    
  end
end