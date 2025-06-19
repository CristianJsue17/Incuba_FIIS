# app/services/home_service.rb
class HomeService < ApplicationService
    def initialize
      # Podrías pasar parámetros si se necesita luego
    end
  
    def call
      {
        programas: Program.order(created_at: :desc).limit(9),
        eventos: Event.order(created_at: :desc).limit(3),
        testimonios: Testimonio.order(created_at: :desc).limit(3),
        equipo: EquipoIncuba.order(:id)  # 👈 AQUÍ AÑADES el equipo de Incuba
      }
    end
  end
  