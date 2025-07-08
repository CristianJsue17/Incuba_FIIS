# app/services/pdf_generator_service.rb

begin
  require 'prawn'
  require 'prawn/table'
rescue LoadError => e
  Rails.logger.error "Error loading Prawn: #{e.message}"
  raise "Prawn gems not installed. Run: bundle add prawn prawn-table"
end

# Suprimir warning de fuentes
Prawn::Fonts::AFM.hide_m17n_warning = true if defined?(Prawn::Fonts::AFM)

class ProgramPdfGeneratorService
  include Prawn::View
  
  def initialize
    @document = Prawn::Document.new(
      page_size: 'A4',
      margin: [50, 50, 50, 50],
      info: {
        Title: "Reporte de Inscripciones",
        Author: "LINAS - Sistema de Gestión",
        Subject: "Inscripciones de Programas",
        Creator: "Rails Application",
        Producer: "Prawn PDF Generator",
        CreationDate: Time.current
      }
    )
    setup_fonts
  end
  
  def generate_program_report(program, inscripciones)
    begin
      add_header(program)
      add_program_info(program)
      add_stats_section(program)
      add_inscripciones_table(program, inscripciones) if inscripciones.any?
      add_footer
      
      @document.render
    rescue => e
      Rails.logger.error "Error generating PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end
  
  def generate_all_programs_report(programs)
    add_general_header
    add_general_stats(programs)
    
    programs.each_with_index do |program, index|
      start_new_page if index > 0
      add_program_section(program)
    end
    
    add_footer
    @document.render
  end
  
  private
  
  def setup_fonts
    # Registrar fuentes si las tienes, o usar las por defecto
    font_families.update(
      "DejaVu" => {
        normal: Rails.root.join("app/assets/fonts/DejaVuSans.ttf").to_s,
        bold: Rails.root.join("app/assets/fonts/DejaVuSans-Bold.ttf").to_s,
        italic: Rails.root.join("app/assets/fonts/DejaVuSans-Oblique.ttf").to_s
      }
    ) if File.exist?(Rails.root.join("app/assets/fonts/DejaVuSans.ttf"))
    
    # Usar fuente por defecto si no tienes fuentes personalizadas
    font "Helvetica"
  end
  
  def add_header(program)
    # Logo o encabezado de la institución
    bounding_box([0, cursor], width: bounds.width, height: 100) do
      stroke_bounds if Rails.env.development? # Solo para debugging
      
      # Título principal
      font_size(24) do
        text "LINAS - Laboratorio de Innovación", align: :center, style: :bold, color: "1a365d"
      end
      
      move_down 10
      
      # Subtítulo del reporte
      font_size(18) do
        text "Reporte de Inscripciones", align: :center, style: :bold, color: "2d3748"
      end
      
      move_down 5
      
      # Nombre del programa
      font_size(14) do
        text "Programa: #{program.titulo}", align: :center, color: "4a5568"
      end
      
      move_down 15
      
      # Línea decorativa
      stroke do
        line_width 2
        stroke_color "3182ce"
        horizontal_line 0, bounds.width
      end
    end
    
    move_down 20
  end
  
  def add_general_header
    bounding_box([0, cursor], width: bounds.width, height: 100) do
      font_size(24) do
        text "LINAS - Laboratorio de Innovación", align: :center, style: :bold, color: "1a365d"
      end
      
      move_down 10
      
      font_size(18) do
        text "Reporte General de Inscripciones", align: :center, style: :bold, color: "2d3748"
      end
      
      move_down 5
      
      font_size(12) do
        text "Todos los Programas", align: :center, color: "4a5568"
      end
      
      move_down 15
      
      stroke do
        line_width 2
        stroke_color "3182ce"
        horizontal_line 0, bounds.width
      end
    end
    
    move_down 20
  end
  
def add_program_info(program)
  # Información del programa en una caja
  bounding_box([0, cursor], width: bounds.width) do
    fill_color "f7fafc"
    fill_rectangle [0, cursor], bounds.width, 140
    
    bounding_box([15, cursor - 15], width: bounds.width - 30) do
      font_size(16) do
        text "Información del Programa", style: :bold, color: "000000" # NEGRO EXPLÍCITO
      end
      
      move_down 15
      
      # Mostrar información línea por línea con NEGRO EXPLÍCITO
      font_size(11) do
        text "<b>Título:</b> #{program.titulo}", inline_format: true, color: "000000"
        move_down 8
        text "<b>Tipo:</b> #{program.tipo_humanizado}", inline_format: true, color: "000000"
        move_down 8
        text "<b>Encargado:</b> #{program.encargado}", inline_format: true, color: "000000"
        move_down 8
        text "<b>Estado:</b> #{program.estado.humanize}", inline_format: true, color: "000000"
        move_down 8
        text "<b>Fecha Publicación:</b> #{program.fecha_publicacion&.strftime('%d/%m/%Y %H:%M') || 'No definida'}", inline_format: true, color: "000000"
        move_down 8
        text "<b>Fecha Vencimiento:</b> #{program.fecha_vencimiento&.strftime('%d/%m/%Y %H:%M') || 'No definida'}", inline_format: true, color: "000000"
      end
    end
  end
  
  move_down 25
end
  
def add_stats_section(program)
  stats = program.inscripciones_por_estado
  
  # Título de estadísticas
  font_size(14) do
    text "Estadísticas de Inscripciones", style: :bold, color: "000000" # NEGRO EXPLÍCITO
  end
  
  move_down 10
  
  # Crear tabla de estadísticas con colores EXPLÍCITOS
  stats_data = [
    ["Métrica", "Cantidad"],
    ["Total Inscripciones", stats[:total].to_s],
    ["Pendientes", stats[:pendiente].to_s],
    ["Aprobadas", stats[:aprobado].to_s],
    ["Rechazadas", stats[:rechazado].to_s]
  ]
  
  table(stats_data, 
        cell_style: { 
          padding: [8, 12], 
          border_width: 1, 
          border_color: "000000",  # BORDE NEGRO
          size: 11,
          text_color: "000000"    # TEXTO NEGRO EXPLÍCITO
        }) do
    row(0).style(
      background_color: "CCCCCC",  # GRIS CLARO
      font_style: :bold,
      text_color: "000000"         # TEXTO NEGRO
    )
    
    # Sin colores de fondo para las otras filas - solo texto negro
    (1..4).each do |i|
      row(i).style(text_color: "000000")
    end
  end
  
  move_down 25
end
  
# Reemplaza COMPLETAMENTE el método add_inscripciones_table en tu servicio:

def add_inscripciones_table(program, inscripciones)
  return if inscripciones.empty?
  
  font_size(14) do
    text "Lista de Inscripciones (#{inscripciones.count})", style: :bold, color: "000000"
  end
  
  move_down 10
  
  # Preparar datos de la tabla
  headers = ["ID", "Nombre Completo", "Email", "Teléfono", "Estado", "Fecha"]
  
  # Agregar columna específica según tipo de programa
  case program.tipo
  when 'preincubacion'
    headers << "Proyecto"
  when 'incubacion'
    headers << "Empresa"
  when 'innovacion'
    headers << "Área Innovación"
  end
  
  # Preparar filas de datos
  table_data = [headers]
  
  inscripciones.each do |inscripcion|
    # Manejar apellidos correctamente
    apellidos = if inscripcion.respond_to?(:apellidos_lider) && inscripcion.apellidos_lider.present?
                  inscripcion.apellidos_lider
                elsif inscripcion.respond_to?(:apellido_lider) && inscripcion.apellido_lider.present?
                  inscripcion.apellido_lider
                else
                  ""
                end
    
    nombre_completo = "#{inscripcion.nombre_lider} #{apellidos}".strip
    
    row = [
      inscripcion.id.to_s,
      nombre_completo,
      inscripcion.correo_lider || "N/A",
      inscripcion.telefono_lider || "N/A",
      inscripcion.estado&.humanize || "Sin estado",
      inscripcion.created_at.strftime("%d/%m/%Y")
    ]
    
    # Agregar dato específico según tipo de programa
    case program.tipo
    when 'preincubacion'
      proyecto = if inscripcion.respond_to?(:nombre_proyecto) && inscripcion.nombre_proyecto.present?
                   inscripcion.nombre_proyecto
                 else
                   "Sin proyecto definido"
                 end
      row << proyecto
    when 'incubacion'
      empresa = if inscripcion.respond_to?(:nombre_empresa) && inscripcion.nombre_empresa.present?
                  inscripcion.nombre_empresa
                else
                  "Sin empresa definida"
                end
      row << empresa
    when 'innovacion'
      area = if inscripcion.respond_to?(:area_innovacion) && inscripcion.area_innovacion.present?
               inscripcion.area_innovacion
             else
               "Sin área definida"
             end
      row << area
    end
    
    table_data << row
  end
  
  # Crear tabla con colores EXPLÍCITOS
  table(table_data,
        cell_style: {
          padding: [6, 8],
          border_width: 1,
          border_color: "000000",     # BORDE NEGRO
          size: 9,
          text_color: "000000",       # TEXTO NEGRO EXPLÍCITO
          overflow: :shrink_to_fit
        }) do
    
    # Estilo del encabezado - COLORES EXPLÍCITOS
    row(0).style(
      background_color: "DDDDDD",   # GRIS MÁS CLARO
      text_color: "000000",         # TEXTO NEGRO
      font_style: :bold,
      size: 10
    )
    
    # Alternar colores de filas - SOLO GRISES CLAROS
    (1...table_data.length).each do |i|
      if i.odd?
        row(i).style(
          background_color: "F5F5F5", # GRIS MUY CLARO
          text_color: "000000"        # TEXTO NEGRO
        )
      else
        row(i).style(text_color: "000000") # SOLO TEXTO NEGRO
      end
    end
    
    # Sin colores específicos para estados - solo texto negro
    (1...table_data.length).each do |i|
      row(i).column(4).style(text_color: "000000") # COLUMNA ESTADO - TEXTO NEGRO
    end
  end
  
  move_down 15
end
  
  def add_program_section(program)
    add_program_info(program)
    add_stats_section(program)
    
    inscripciones = program.todas_inscripciones.limit(10) # Limitar para reporte general
    if inscripciones.any?
      font_size(12) do
        text "Últimas 10 Inscripciones", style: :bold, color: "2d3748"
      end
      move_down 5
      add_inscripciones_table(program, inscripciones)
    else
      font_size(10) do
        text "Sin inscripciones registradas", color: "718096", style: :italic
      end
    end
    
    move_down 15
  end
  
  def add_general_stats(programs)
    total_inscripciones = programs.sum { |p| p.inscripciones_por_estado[:total] }
    
    font_size(14) do
      text "Resumen General", style: :bold, color: "2d3748"
    end
    
    move_down 10
    
    summary_data = [
      ["Métrica", "Cantidad"],
      ["Total Programas", programs.count.to_s],
      ["Programas Activos", programs.count { |p| p.estado == 'activo' }.to_s],
      ["Total Inscripciones", total_inscripciones.to_s]
    ]
    
    table(summary_data,
          width: 300,
          cell_style: {
            padding: [8, 12],
            border_width: 1,
            border_color: "cbd5e0",
            size: 10
          }) do
      row(0).style(
        background_color: "edf2f7",
        font_style: :bold,
        text_color: "2d3748"
      )
    end
    
    move_down 25
  end
  
def add_footer
  repeat(:all) do
    bounding_box([0, 30], width: bounds.width, height: 20) do
      # stroke_bounds if Rails.env.development? # Comentar para quitar debug
      
      font_size(8) do
        text_box "Generado el #{Time.current.strftime('%d de %B del %Y a las %H:%M')}",
                 at: [0, 15],
                 width: bounds.width / 2,
                 style: :italic,
                 color: "000000"    # NEGRO EXPLÍCITO
        
        text_box "Página #{page_number} de #{page_count}",
                 at: [bounds.width / 2, 15],
                 width: bounds.width / 2,
                 align: :right,
                 style: :italic,
                 color: "000000"    # NEGRO EXPLÍCITO
      end
      
      stroke do
        stroke_color "000000"   # LÍNEA NEGRA
        line_width 1
        horizontal_line 0, bounds.width, at: 25
      end
    end
  end
end

end