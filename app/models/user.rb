# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :validatable

  belongs_to :occupation
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :user_roles
  has_many :roles, through: :user_roles

  has_one_attached :avatar      # imagen de perfil

  # Validaciones
  validates :nombre, :apellido, presence: true
  validates :estado, inclusion: { in: %w[activo suspendido inabilitado] }

  # Callbacks
  before_validation :set_default_estado, on: :create

  # Scopes
  scope :activos, -> { where(estado: 'activo') }
  scope :suspendidos, -> { where(estado: 'suspendido') }
  scope :inabilitados, -> { where(estado: 'inabilitado') }
  scope :por_ultima_actividad, -> { order(ultimo_acceso: :desc) }

  # Métodos existentes
  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def activo?
    estado == 'activo'
  end

  def suspendido?
    estado == 'suspendido'
  end

  def inabilitado?
    estado == 'inabilitado'
  end

  def suspension_activa?
    suspendido? && suspension_until.present? && suspension_until > Time.current
  end

  def puede_acceder?
    return false if inabilitado?
    return false if suspendido? && suspension_activa?
    true
  end

  def tiempo_restante_suspension
    return nil unless suspension_activa?
    ((suspension_until - Time.current) / 1.hour).ceil
  end

  def rol_principal
    roles.first&.nombre
  end

  def es_admin?
    roles.exists?(nombre: 'Administrador')
  end

  def es_participante?
    roles.exists?(nombre: 'Participante')
  end

  def es_mentor?
    roles.exists?(nombre: 'Mentor')
  end

  # Método simple para último acceso
  def ha_iniciado_sesion?
    ultimo_acceso.present?
  end

  # Método simple para descripción de actividad (sin "en línea")
  def descripcion_ultima_actividad
    return 'Nunca ha iniciado sesión' unless ha_iniciado_sesion?
        
    if ultimo_acceso > 24.hours.ago
      "Activo hoy a las #{ultimo_acceso.strftime('%H:%M')}"
    elsif ultimo_acceso > 7.days.ago
      "Último acceso hace #{time_ago_in_words(ultimo_acceso)}"
    else
      "Último acceso: #{ultimo_acceso.strftime('%d/%m/%Y %H:%M')}"
    end
  end

  private

  def set_default_estado
    self.estado ||= 'activo'
  end
end