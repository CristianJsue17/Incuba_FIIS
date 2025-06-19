class RemoveTipoFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :tipo, :string
  end
end
