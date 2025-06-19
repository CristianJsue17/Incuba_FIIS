class CreateProgramService < ApplicationService
  def initialize(params, user)
    @params = params
    @user = user
  end
  
  def call
    Program.transaction do
      program = create_program
      process_nested_attributes(program)
      create_form(program)
      program # Retornar el objeto program
    end
  rescue ActiveRecord::RecordInvalid => e
    program = handle_error(e)
    program
  end
  
  private
  
def create_program
  # Parsear fechas primero 
  fecha_pub = parse_datetime(@params[:fecha_publicacion])
  fecha_ven = parse_datetime(@params[:fecha_vencimiento])
  
  # Validar que la fecha de vencimiento sea posterior
  if fecha_pub.present? && fecha_ven.present? && fecha_ven <= fecha_pub
    program = Program.new
    program.errors.add(:fecha_vencimiento, "debe ser posterior a la fecha de publicación")
    raise ActiveRecord::RecordInvalid.new(program)
  end
  
  program = Program.new(
    titulo: @params[:titulo],
    descripcion: @params[:descripcion],
    encargado: @params[:encargado],
    tipo: @params[:tipo],
    estado: @params[:estado] || 'activo',
    fecha_publicacion: fecha_pub,  # Usar variables ya parseadas
    fecha_vencimiento: fecha_ven,  # Usar variables ya parseadas
    user: @user,
    created_by: @user,
    updated_by: @user
  )
  
  # Guardar primero sin las asociaciones
  program.save!
  
  # Adjuntar imagen después de guardar
  if @params[:image].present?
    program.image.attach(@params[:image])
  end
  
  program
end

  # Método para parsear fechas de manera segura
def parse_datetime(datetime_string)
  return if datetime_string.blank?
  
  if datetime_string.is_a?(String)
    DateTime.strptime(datetime_string, '%Y-%m-%dT%H:%M') rescue datetime_string
  else
    datetime_string
  end
end
  
# En app/services/create_program_service.rb
def process_nested_attributes(program)
  # Procesar objetivos
  if @params[:objetivos_attributes].present?
    @params[:objetivos_attributes].each do |key, attrs|
      next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
      
      # Crear objetivo y asociación
      objetivo = Objetivo.create!(descripcion: attrs[:descripcion])
      ProgramObjetivo.create!(program: program, objetivo: objetivo)
    end
  end
  
  # Procesar beneficios
  if @params[:beneficios_attributes].present?
    @params[:beneficios_attributes].each do |key, attrs|
      next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
      
      # Crear beneficio y asociación
      beneficio = Beneficio.create!(descripcion: attrs[:descripcion])
      ProgramBeneficio.create!(program: program, beneficio: beneficio)
    end
  end
  
  # Procesar requisitos
  if @params[:requisitos_attributes].present?
    @params[:requisitos_attributes].each do |key, attrs|
      next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
      
      # Crear requisito y asociación
      requisito = Requisito.create!(descripcion: attrs[:descripcion])
      ProgramRequisito.create!(program: program, requisito: requisito)
    end
  end
end
  
  def create_form(program)
    return unless program.persisted?
    
    case program.tipo
    when 'preincubacion'
      program.create_formulario_programa_preincubacion!
    when 'incubacion'
      program.create_formulario_programa_incubacion!
    when 'innovacion'
      program.create_formulario_programa_innovacion!
    end
  rescue => e
    Rails.logger.error("Error creating form: #{e.message}")
    program.errors.add(:base, "Error al crear formulario asociado: #{e.message}")
  end
  
  def handle_error(exception)
    program = exception.record || Program.new(@params.except(
      :objetivos_attributes,
      :beneficios_attributes,
      :requisitos_attributes,
      :formulario_programa_preincubacion_attributes,
      :formulario_programa_incubacion_attributes, 
      :formulario_programa_innovacion_attributes
    ))
    
    # No necesitamos reconstruir asociaciones aquí
    # ya que Rails debería mantener los valores del formulario
    program
  end
end