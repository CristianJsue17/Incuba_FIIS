class CreateNotificacions < ActiveRecord::Migration[7.1]
  def change
    create_table :notificacions do |t|
      t.references :user, null: false, foreign_key: true
      t.text :mensaje
      t.boolean :leida
      t.string :tipo

      t.timestamps
    end
  end
end
