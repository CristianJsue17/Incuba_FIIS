# app/controllers/home_controller.rb 

class HomeController < ApplicationController
  
  # Método para mostrar la página de inicio
  def index
    @datos_home = HomeService.call
  end 



end