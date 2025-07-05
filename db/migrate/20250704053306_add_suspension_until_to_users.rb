class AddSuspensionUntilToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :suspension_until, :datetime
    add_index :users, :suspension_until
  end
end