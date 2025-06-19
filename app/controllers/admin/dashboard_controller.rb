module Admin
    class DashboardController < ApplicationController
      layout 'admin' # Esto es crucial
      def index
      end
  
      private
  
      def authorize_admin!
        redirect_to root_path, alert: "Acceso denegado" unless current_user.roles.exists?(nombre: 'Administrador')
      end
    end
  end
  