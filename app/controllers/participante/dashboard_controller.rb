class Participante::DashboardController < ApplicationController
  layout 'participante'
  before_action :authenticate_user!
  before_action :authorize_participante!

  def index
    
  end

  private

  def authorize_participante!
    unless current_user.roles.exists?(nombre: 'Participante')
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección"
    end
  end
end