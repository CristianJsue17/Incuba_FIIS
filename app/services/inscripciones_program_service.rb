# app/services/inscripciones_program_service.rb
class InscripcionesProgramService < ApplicationService
    
  # Método para preparar nueva inscripción
  def self.prepare_new_inscription(program_id)
    program = find_and_validate_program(program_id)
        
    return program unless program[:success]
        
    program_obj = program[:program]
    unless program_obj.puede_inscribirse?
      return {
        success: false,
        error: "Las inscripciones no están disponibles. #{program_obj.mensaje_disponibilidad}"
      }
    end

    formulario_data = create_formulario_by_type(program_obj)

    {
      success: true,
      program: program_obj,
      formulario: formulario_data[:formulario],
      template: formulario_data[:template]
    }
  end

  # Método para crear inscripción
  def self.create_inscription(program_id:, formulario_params:, tipo:)
    program = find_and_validate_program(program_id)
        
    return program unless program[:success]
        
    program_obj = program[:program]

    unless program_obj.puede_inscribirse?
      return {
        success: false,
        error: "Las inscripciones no están disponibles. #{program_obj.mensaje_disponibilidad}"
      }
    end

    formulario = create_formulario_for_creation(program_obj, formulario_params)

    if formulario.save
      {
        success: true,
        message: 'Tu inscripción ha sido enviada exitosamente.',
        session_data: {
          tipo_programa: program_obj.tipo,
          last_form_type: program_obj.tipo,
          programa_titulo: program_obj.titulo  # Para mostrar en confirmación
        }
      }
    else
      {
        success: false,
        formulario: formulario,
        errors: formulario.errors.full_messages,
        template: template_by_type(program_obj.tipo)
      }
    end
  end

  # Método para confirmación
  def self.confirmacion_data(session_tipo:, session_last_form_type:)
    tipo = session_tipo || session_last_form_type
    { tipo: tipo }
  end

  private

  def self.find_and_validate_program(program_id)
    program = Program.find(program_id)
    program.actualizar_estado_automatico!
        
    if program.estado == 'inactivo'
      return {
        success: false,
        error: 'Este programa ya no está disponible'
      }
    end

    { success: true, program: program }
  rescue ActiveRecord::RecordNotFound
    { success: false, error: 'Programa no encontrado' }
  end

  def self.create_formulario_by_type(program)
    case program.tipo
    when 'preincubacion'
      {
        formulario: FormularioProgramaPreincubacion.new(program: program, es_plantilla: false),
        template: 'formulario_preincubacion'
      }
    when 'incubacion'
      {
        formulario: FormularioProgramaIncubacion.new(program: program, es_plantilla: false),
        template: 'formulario_incubacion'
      }
    when 'innovacion'
      {
        formulario: FormularioProgramaInnovacion.new(program: program, es_plantilla: false),
        template: 'formulario_innovacion'
      }
    else
      raise ArgumentError, "Tipo de programa no válido: #{program.tipo}"
    end
  end

  def self.create_formulario_for_creation(program, formulario_params)
    base_params = { program: program, es_plantilla: false}
        
    case program.tipo
    when 'preincubacion'
      FormularioProgramaPreincubacion.new(formulario_params.merge(base_params))
    when 'incubacion'
      FormularioProgramaIncubacion.new(formulario_params.merge(base_params))
    when 'innovacion'
      FormularioProgramaInnovacion.new(formulario_params.merge(base_params))
    else
      raise ArgumentError, "Tipo de programa no válido: #{program.tipo}"
    end
  end

  def self.template_by_type(tipo)
    case tipo
    when 'preincubacion'
      'formulario_preincubacion'
    when 'incubacion'
      'formulario_incubacion'
    when 'innovacion'
      'formulario_innovacion'
    else
      raise ArgumentError, "Tipo de programa no válido: #{tipo}"
    end
  end
end