# app/controllers/contact_controller.rb
class ContactController < ApplicationController
  def contact
    @formulario_contacto = FormularioContacto.new
  end
  
  def create
    @formulario_contacto = FormularioContacto.new(formulario_contacto_params)
    
    if @formulario_contacto.save
      flash[:success] = "¡Mensaje enviado exitosamente! Te contactaremos pronto."
      redirect_to contact_path
    else
      flash.now[:error] = "Hubo un error al enviar el mensaje. Por favor, revisa los campos."
      render :contact, status: :unprocessable_entity
    end
  end
  
  private
  
  def formulario_contacto_params
    params.require(:formulario_contacto).permit(:nombre, :correo, :asunto, :mensaje)
  end
end