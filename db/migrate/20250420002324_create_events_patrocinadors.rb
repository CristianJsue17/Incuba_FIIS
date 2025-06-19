class CreateEventsPatrocinadors < ActiveRecord::Migration[7.1]
  def change
    create_table :events_patrocinadors do |t|
      t.references :event, null: false, foreign_key: true
      t.references :patrocinador, null: false, foreign_key: { to_table: :patrocinadors }

      t.timestamps
    end
  end
end
