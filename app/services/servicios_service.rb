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