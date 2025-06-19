class CreateOccupations < ActiveRecord::Migration[7.1]
  def change
    create_table :occupations do |t|
      t.string :nombre

      t.timestamps
    end
  end
end
