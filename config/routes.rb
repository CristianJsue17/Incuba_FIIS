# config/routes.rb

Rails.application.routes.draw do

  devise_for :users
  
  # AGREGAR RUTA PARA CAMBIO DE IDIOMA
  get '/change_locale/:locale', to: 'application#change_locale', as: :change_locale

authenticate :user, ->(user) { user.roles.exists?(nombre: 'Administrador') } do
  namespace :admin do
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    
    # CORREGIDO: Especificar el controlador explícitamente
    resource :profile, only: [:show, :update], controller: 'profile' do
      patch :update_avatar
      delete :remove_avatar
    end
    
    # RUTAS EXISTENTES PARA GESTIÓN DE USUARIOS
    resources :users do
      member do
        patch :cambiar_estado
        patch :suspender_temporalmente
        patch :reactivar
      end
    end
                
    resources :programs do
      member do
        patch :cambiar_estado
      end
      collection do
        get 'tipo_formulario'
      end
    end
                            
    # RUTAS DE EVENTOS
    resources :events do
      member do
        patch :cambiar_estado
      end
    end

    # RUTAS DE CONTACTO CORREGIDAS
    resources :contact, only: [:index, :show, :destroy] do
      collection do
        get :stats
      end
    end

    # RUTAS PARA INSCRIPCIONES
    namespace :inscripciones do
      # Inscripciones de programas (existente)
      resources :programs, only: [:index, :show] do
        member do
          patch :cambiar_estado_inscripcion
          get :export_pdf
          get :export_excel
        end
        collection do
          get :export_all_excel
          get :export_all_pdf
        end
      end

      # NUEVO: Inscripciones de eventos
      resources :events, only: [:index, :show] do
        member do
          patch :cambiar_estado_inscripcion
          get :export_pdf
          get :export_excel
        end
        collection do
          get :export_all_excel
          get :export_all_pdf
        end
      end
    end
  end
end

 # Rutas para servicios y programas
  get 'servicios', to: 'services#servicios', as: 'servicios'
  get 'servicios/:tipo', to: 'services#programas_tipo', as: 'programas_tipo'
  get 'programas/:id', to: 'services#programa_detalle', as: 'programa_detalle'
    
  # Rutas para inscripciones de programas
  get 'programas/:id/inscripcion', to: 'inscripciones_program#new', as: 'inscripcion_programa'
  post 'programas/:id/inscripcion', to: 'inscripciones_program#create'
  post 'programas/:id/consultar_dni', to: 'inscripciones_program#consultar_dni' # NUEVA RUTA para consultar DNI
  get 'inscripciones_program/confirmacion', to: 'inscripciones_program#confirmacion', as: 'confirmacion_inscripcion'

 # ========== RUTAS PARA EVENTOS CORREGIDAS ==========
# Rutas principales para eventos
get 'eventos', to: 'events#eventos', as: 'eventos'
get 'eventos/:id', to: 'events#evento_detalle', as: 'evento_detalle'

# Rutas para inscripciones de eventos
get 'eventos/:id/inscripcion', to: 'inscripciones_event#new', as: 'inscripcion_evento'
post 'eventos/:id/inscripcion', to: 'inscripciones_event#create'

#Ruta para consultar DNI específica del evento (debe estar anidada)
post 'eventos/:id/consultar_dni', to: 'inscripciones_event#consultar_dni', as: 'consultar_dni_evento'

# Ruta para mostrar confirmación de inscripción de eventos
get 'inscripciones_event/confirmacion', to: 'inscripciones_event#confirmacion', as: 'confirmacion_inscripcion_evento'
  

# Rutas para roles de participante y mentor
# Estas rutas deben ir después de las rutas de admin para evitar conflictos
authenticate :user do
  namespace :participante do
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    
    resource :profile, only: [:show, :update], controller: 'profile' do
      patch :update_avatar
      delete :remove_avatar
    end
  end
  
  namespace :mentor do
    get 'dashboard', to: 'dashboard#index', as: :dashboard
    
    # AGREGAR ESTAS RUTAS PARA EL PERFIL DE MENTOR
    resource :profile, only: [:show, :update], controller: 'profile' do
      patch :update_avatar
      delete :remove_avatar
    end
  end
end
  
  get 'about', to: 'about#about', as: :about
  get 'contact', to: 'contact#contact', as: :contact
  post 'contact', to: 'contact#create'
  get 'mentores', to: 'mentors#mentores', as: :mentores
  
  # Ruta raíz
  root 'home#index'

  # RUTAS PARA PÁGINAS DE ERROR (deben ir al final)
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/503", to: "errors#service_unavailable", via: :all


    # ===== RUTAS TEMPORALES PARA PROBAR ERRORES (ELIMINAR DESPUÉS) =====
  #if Rails.env.development?
    #get '/test_404', to: proc { raise ActionController::RoutingError.new('Página no encontrada') }
    #get '/test_500', to: proc { raise StandardError.new('Error interno del servidor') }
    #get '/test_503', to: 'errors#service_unavailable'  # ← CAMBIAR ESTA LÍNEA
  #end
end