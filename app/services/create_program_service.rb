class CreateProgramService < ApplicationService
  def initialize(params, user)
    @params = params
    @user = user
  end
  
  def call
    Program.transaction do
      program = create_program
      process_nested_attributes(program)
      create_form_plantilla(program) # CAMBIO: Método renombrado para claridad
      program
    end
  rescue ActiveRecord::RecordInvalid => e
    program = handle_error(e)
    program
  end
  
  private
  
  def create_program
    fecha_pub = parse_datetime(@params[:fecha_publicacion])
    fecha_ven = parse_datetime(@params[:fecha_vencimiento])
    
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
      fecha_publicacion: fecha_pub,
      fecha_vencimiento: fecha_ven,
      user: @user,
      created_by: @user,
      updated_by: @user
    )
    
    program.save!
    
    if @params[:image].present?
      program.image.attach(@params[:image])
    end
    
    program
  end

  def parse_datetime(datetime_string)
    return if datetime_string.blank?
    
    if datetime_string.is_a?(String)
      DateTime.strptime(datetime_string, '%Y-%m-%dT%H:%M') rescue datetime_string
    else
      datetime_string
    end
  end
  
  def process_nested_attributes(program)
    if @params[:objetivos_attributes].present?
      @params[:objetivos_attributes].each do |key, attrs|
        next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
        
        objetivo = Objetivo.create!(descripcion: attrs[:descripcion])
        ProgramObjetivo.create!(program: program, objetivo: objetivo)
      end
    end
    
    if @params[:beneficios_attributes].present?
      @params[:beneficios_attributes].each do |key, attrs|
        next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
        
        beneficio = Beneficio.create!(descripcion: attrs[:descripcion])
        ProgramBeneficio.create!(program: program, beneficio: beneficio)
      end
    end
    
    if @params[:requisitos_attributes].present?
      @params[:requisitos_attributes].each do |key, attrs|
        next if attrs[:_destroy] == "1" || attrs[:descripcion].blank?
        
        requisito = Requisito.create!(descripcion: attrs[:descripcion])
        ProgramRequisito.create!(program: program, requisito: requisito)
      end
    end
  end
  
  # CAMBIO PRINCIPAL: Crear plantillas para admin
  def create_form_plantilla(program)
    return unless program.persisted?
    
    case program.tipo
    when 'preincubacion'
      program.create_formulario_plantilla_preincubacion!(es_plantilla: true)
    when 'incubacion'
      program.create_formulario_plantilla_incubacion!(es_plantilla: true)
    when 'innovacion'
      program.create_formulario_plantilla_innovacion!(es_plantilla: true)
    end
  rescue => e
    Rails.logger.error("Error creating form template: #{e.message}")
    program.errors.add(:base, "Error al crear formulario plantilla: #{e.message}")
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
    
    program
  end
end