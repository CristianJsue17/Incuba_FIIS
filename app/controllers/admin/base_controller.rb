# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :authorize_admin!
  
    private
  
    def authorize_admin!
      unless current_user.roles.exists?(nombre: 'Administrador')
        redirect_to root_path, 
          alert: "No tienes permisos para acceder a esta sección"
      end
    end
  end