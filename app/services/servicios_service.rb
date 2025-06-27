# app/services/servicios_service.rb
class ServiciosService < ApplicationService
  
  def initialize(tipo = nil)
    @tipo = tipo
  end

  def call
    if @tipo.present?
      # Si se proporciona un tipo, obtener programas de ese tipo
      # FILTRAR: Solo mostrar programas que NO estén inactivos
      programas = Program.where(tipo: @tipo)
                         .where.not(estado: 'inactivo')
                         .order(fecha_publicacion: :desc)

      # Actualizar estados automáticamente antes de mostrar
      programas.each(&:actualizar_estado_automatico!)

      {
        tipo: @tipo,
        tipo_actual: obtener_info_tipo(@tipo),
        programas: programas
      }
    else
      # Si no hay tipo, devolver datos generales para la vista de servicios
      {
        tipos_programas: [
          {
            tipo: 'preincubacion',
            titulo: 'Preincubación',
            descripcion: 'Programa diseñado para emprendedores en fase inicial que buscan validar su idea de negocio y desarrollar un modelo de negocio viable.',
            caracteristicas: [
              'Mentoría especializada',
              'Talleres de validación',
              'Networking con expertos'
            ]
          },
          {
            tipo: 'incubacion',
            titulo: 'Incubación',
            descripcion: 'Impulsa tu startup que ya tiene un producto mínimo viable y necesita escalar. Ofrecemos herramientas para consolidar tu modelo de negocio.',
            caracteristicas: [
              'Asesoría en gestión',
              'Acceso a financiamiento',
              'Espacio de coworking'
            ]
          },
          {
            tipo: 'innovacion',
            titulo: 'Innovación',
            descripcion: 'Programa para empresas establecidas que buscan reinventarse a través de la innovación y el desarrollo de nuevas soluciones disruptivas.',
            caracteristicas: [
              'Innovación abierta',
              'Transferencia tecnológica',
              'Aceleración empresarial'
            ]
          }
        ]
      }
    end
  end

  # Método para obtener datos de servicios generales
  def self.servicios_data
    new.call
  end

  # Método para obtener programas por tipo
  def self.programas_tipo(tipo)
    resultado = new(tipo).call
    
    # Asegurar que tipo_actual no sea nil
    if resultado[:tipo_actual].nil?
      resultado[:tipo_actual] = {
        titulo: 'Programas',
        descripcion: 'Todos nuestros programas disponibles.',
        color: '#607D8B',
        color_claro: 'rgba(96, 125, 139, 0.1)',
        icono: 'fa-th-list'
      }
    end

    # Log para depuración
    Rails.logger.debug "Tipo: #{tipo}"
    Rails.logger.debug "Tipo actual: #{resultado[:tipo_actual]}"
    Rails.logger.debug "Programas encontrados: #{resultado[:programas].count} para tipo #{tipo}"

    resultado
  end

  # Método para obtener detalles de un programa específico
  def self.programa_detalle(program_id)
    program = Program.includes(
      :objetivos,
      :beneficios,
      :requisitos,
      :user,
      :created_by
    ).find(program_id)

    # Actualizar estado automáticamente antes de mostrar
    program.actualizar_estado_automatico!

    # Verificar si el programa debe ser visible (no inactivo)
    if program.estado == 'inactivo'
      return {
        success: false,
        error: 'Este programa ya no está disponible'
      }
    end

    # Obtener información del tipo para estilos
    tipo_actual = new(program.tipo).call[:tipo_actual]

    # Contar inscripciones actuales
    total_inscripciones = program.total_inscripciones

    # Verificar disponibilidad para inscripciones según estado
    puede_inscribirse = program.puede_inscribirse?
    mensaje_disponibilidad = program.mensaje_disponibilidad
    estado_css_class = program.estado_css_class

    {
      success: true,
      program: program,
      tipo_actual: tipo_actual,
      total_inscripciones: total_inscripciones,
      puede_inscribirse: puede_inscribirse,
      mensaje_disponibilidad: mensaje_disponibilidad,
      estado_css_class: estado_css_class
    }
  end

  private

  def obtener_info_tipo(tipo)
    # Normalizar el tipo para evitar problemas con mayúsculas/minúsculas
    tipo_normalizado = tipo.to_s.downcase.strip

    case tipo_normalizado
    when 'preincubacion'
      {
        titulo: 'Preincubación',
        descripcion: 'Programas diseñados para validar y desarrollar tu idea de negocio.',
        color: '#2196F3',
        color_claro: 'rgba(33, 150, 243, 0.1)',
        icono: 'fa-lightbulb'
      }
    when 'incubacion'
      {
        titulo: 'Incubación',
        descripcion: 'Programas para startups en etapa temprana que buscan crecimiento y escalabilidad.',
        color: '#009688',
        color_claro: 'rgba(0, 150, 136, 0.1)',
        icono: 'fa-rocket'
      }
    when 'innovacion'
      {
        titulo: 'Innovación',
        descripcion: 'Programas para empresas establecidas que buscan innovar en sus productos o servicios.',
        color: '#CDDC39',
        color_claro: 'rgba(205, 220, 57, 0.1)',
        icono: 'fa-cogs'
      }
    else
      # Valor por defecto para tipos no reconocidos
      {
        titulo: 'Programas',
        descripcion: 'Todos nuestros programas disponibles.',
        color: '#607D8B',
        color_claro: 'rgba(96, 125, 139, 0.1)',
        icono: 'fa-th-list'
      }
    end
  end
end