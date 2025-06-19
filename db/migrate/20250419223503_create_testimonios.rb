class CreateTestimonios < ActiveRecord::Migration[7.1]
  def change
    create_table :testimonios do |t|
      t.references :user, null: false, foreign_key: true
      t.text :mensaje
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
