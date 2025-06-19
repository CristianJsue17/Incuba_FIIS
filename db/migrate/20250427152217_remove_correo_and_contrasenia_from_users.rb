class RemoveCorreoAndContraseniaFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :correo, :string
    remove_column :users, :contrasenia, :string
  end
end
