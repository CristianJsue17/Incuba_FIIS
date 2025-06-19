class CreateFormularioContactos < ActiveRecord::Migration[7.1]
  def change
    create_table :formulario_contactos do |t|
      #t.references :user, null: false, foreign_key: true  No debe llevar xq el que envia sms es alguien de afuera
      t.string :nombre
      t.string :correo
      t.string :asunto
      t.text :mensaje
      #t.timestamp :created_at

      t.timestamps
    end
  end
end
