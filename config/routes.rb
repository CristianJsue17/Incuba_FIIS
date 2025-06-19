Rails.application.routes.draw do
  devise_for :users
  
  # AGREGAR RUTA PARA CAMBIO DE IDIOMA
  get '/change_locale/:locale', to: 'application#change_locale', as: :change_locale

  authenticate :user, ->(user) { user.roles.exists?(nombre: 'Administrador') } do
    namespace :admin do
      get 'dashboard', to: 'dashboard#index', as: :dashboard
      resources :programs do
        member do
          patch :cambiar_estado
        end
        collection do
          get 'tipo_formulario'
        end
      end
    end
  end

  # Rutas para servicios y programas
  get 'servicios', to: 'home#servicios', as: 'servicios'
  get 'servicios/:tipo', to: 'home#programas_tipo', as: 'programas_tipo'
     
  # Rutas para inscripciones con soporte para JSON
  get 'programas/:id/inscripcion', to: 'inscripciones#new', as: 'inscripcion_programa'
  post 'programas/:id/inscripcion', to: 'inscripciones#create'
     
  # Ruta para mostrar confirmación de inscripción
  get 'inscripciones/confirmacion', to: 'inscripciones#confirmacion', as: 'confirmacion_inscripcion'
       
  # Rutas para otros roles
  authenticate :user do
    namespace :participante do
      get 'dashboard', to: 'dashboard#index', as: :dashboard
    end
     
    namespace :mentor do
      get 'dashboard', to: 'dashboard#index', as: :dashboard
    end
  end
     
  get 'about', to: 'home#about', as: :about
  get 'contact', to: 'home#contact', as: :contact
  get 'mentores', to: 'home#mentores', as: :mentores

 

  # Ruta raíz
  root 'home#index'
end