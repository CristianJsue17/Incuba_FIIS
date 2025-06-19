# app/controllers/mentor/dashboard_controller.rb
class Mentor::DashboardController < ApplicationController
  layout 'mentor'
  before_action :authenticate_user!
  before_action :authorize_mentor!

  def index
    
  end

  private

  def authorize_mentor!
    unless current_user.roles.exists?(nombre: 'Mentor')
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección"
    end
  end
end