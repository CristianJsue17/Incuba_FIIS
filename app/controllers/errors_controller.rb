# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  # Saltar TODOS los callbacks del ApplicationController
  skip_before_action :check_user_status, raise: false
  skip_before_action :set_locale, raise: false
  skip_before_action :verify_authenticity_token, raise: false
  
  # Saltar autenticación de Devise si existe
  skip_before_action :authenticate_user!, raise: false if respond_to?(:authenticate_user!)

  def not_found
    respond_to do |format|
      format.html { render status: 404 }
      format.json { render json: { error: "Página no encontrada" }, status: 404 }
    end
  end

  def internal_server_error
    respond_to do |format|
      format.html { render status: 500 }
      format.json { render json: { error: "Error interno del servidor" }, status: 500 }
    end
  end

  def service_unavailable
    respond_to do |format|
      format.html { render status: 503 }
      format.json { render json: { error: "Servicio no disponible" }, status: 503 }
    end
  end
end