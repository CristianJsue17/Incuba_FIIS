# app/controllers/admin/dashboard_controller.rb - ACTUALIZADO
module Admin
  class DashboardController < Admin::BaseController # Heredar de BaseController
    
      def index
    # === ESTADÍSTICAS DE PROGRAMAS ===
    @total_programas = Program.count
    @programas_activos = Program.where(estado: 'activo').count
    @programas_pendientes = Program.where(estado: 'pendiente').count
    @programas_finalizados = Program.where(estado: 'finalizado').count
    @programas_inactivos = Program.where(estado: 'inactivo').count

    # === ESTADÍSTICAS DE EVENTOS ===
    @total_eventos = Event.count
    @eventos_activos = Event.where(estado: 'activo').count
    @eventos_pendientes = Event.where(estado: 'pendiente').count
    @eventos_finalizados = Event.where(estado: 'finalizado').count
    @eventos_inactivos = Event.where(estado: 'inactivo').count

    # === ESTADÍSTICAS DE PARTICIPANTES ===
    # Calcular total de inscripciones en programas y eventos
    total_inscripciones_programas = calcular_total_inscripciones_programas
    total_inscripciones_eventos = calcular_total_inscripciones_eventos
    @total_participantes = total_inscripciones_programas + total_inscripciones_eventos

    # Calcular crecimiento del mes pasado
    @crecimiento_participantes = calcular_crecimiento_participantes

    # === ESTADÍSTICAS DE REPORTES ===
    @total_reportes = 42 # Puedes cambiar esto por una lógica real cuando tengas reportes
    @ultimo_reporte = "Hoy" # También puedes hacer esto dinámico

    # === PORCENTAJES DE TIPOS DE PROGRAMAS ===
    calcular_porcentajes_programas

    # === ACTIVIDADES RECIENTES ===
    @actividades_recientes = generar_actividades_recientes

    # === DATOS PARA EL GRÁFICO ===
    generar_datos_grafico_inscripciones
    generar_datos_grafico_12_meses
  end

  private

  def calcular_total_inscripciones_programas
    total = 0
    
    # Sumar inscripciones de preincubación
    total += FormularioProgramaPreincubacion.where(es_plantilla: [false, nil]).count
    
    # Sumar inscripciones de incubación
    total += FormularioProgramaIncubacion.where(es_plantilla: [false, nil]).count
    
    # Sumar inscripciones de innovación
    total += FormularioProgramaInnovacion.where(es_plantilla: [false, nil]).count
    
    total
  end

  def calcular_total_inscripciones_eventos
    # Sumar todas las inscripciones de eventos (excluyendo plantillas)
    FormularioEvento.where(es_plantilla: [false, nil]).count
  end

  def calcular_crecimiento_participantes
    # Calcular participantes del mes actual
    inicio_mes_actual = Time.current.beginning_of_month
    fin_mes_actual = Time.current.end_of_month
    
    participantes_mes_actual = calcular_participantes_en_periodo(inicio_mes_actual, fin_mes_actual)
    
    # Calcular participantes del mes pasado
    inicio_mes_pasado = 1.month.ago.beginning_of_month
    fin_mes_pasado = 1.month.ago.end_of_month
    
    participantes_mes_pasado = calcular_participantes_en_periodo(inicio_mes_pasado, fin_mes_pasado)
    
    # Calcular porcentaje de crecimiento
    if participantes_mes_pasado > 0
      ((participantes_mes_actual - participantes_mes_pasado).to_f / participantes_mes_pasado * 100).round
    else
      participantes_mes_actual > 0 ? 100 : 0
    end
  end

  # Generar datos para el gráfico de 12 meses
  def generar_datos_grafico_12_meses
    # Generar array de los últimos 12 meses incluyendo el actual
    meses_12 = []
    (0..11).each do |i|
      meses_12 << i.months.ago.beginning_of_month
    end
    meses_12.reverse! # Para que aparezcan del más antiguo al más reciente

    @meses_12_labels = meses_12.map { |mes| mes.strftime('%b %Y') }
    
    @inscripciones_programas_12_data = []
    @inscripciones_eventos_12_data = []

    meses_12.each do |mes|
      inicio_mes = mes.beginning_of_month
      fin_mes = mes.end_of_month

      # Contar inscripciones de programas en este mes
      inscripciones_programas_mes = calcular_participantes_programas_en_periodo(inicio_mes, fin_mes)
      @inscripciones_programas_12_data << inscripciones_programas_mes

      # Contar inscripciones de eventos en este mes
      inscripciones_eventos_mes = FormularioEvento.where(
        es_plantilla: [false, nil],
        created_at: inicio_mes..fin_mes
      ).count
      @inscripciones_eventos_12_data << inscripciones_eventos_mes
    end
  end

  def calcular_participantes_en_periodo(inicio, fin)
    total = 0
    
    # Inscripciones de programas en el periodo
    total += FormularioProgramaPreincubacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total += FormularioProgramaIncubacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total += FormularioProgramaInnovacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    # Inscripciones de eventos en el periodo
    total += FormularioEvento.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total
  end

  def calcular_porcentajes_programas
    if @total_programas > 0
      preincubacion_count = Program.where(tipo: 'preincubacion').count
      incubacion_count = Program.where(tipo: 'incubacion').count
      innovacion_count = Program.where(tipo: 'innovacion').count
      
      @porcentaje_preincubacion = ((preincubacion_count.to_f / @total_programas) * 100).round
      @porcentaje_incubacion = ((incubacion_count.to_f / @total_programas) * 100).round
      @porcentaje_innovacion = ((innovacion_count.to_f / @total_programas) * 100).round
    else
      @porcentaje_preincubacion = 0
      @porcentaje_incubacion = 0
      @porcentaje_innovacion = 0
    end
  end

  def generar_actividades_recientes
    actividades = []
    
    # Obtener las 2 inscripciones más recientes de programas
    inscripciones_programas_recientes = obtener_inscripciones_programas_recientes(2)
    inscripciones_programas_recientes.each do |inscripcion|
      programa = inscripcion.program rescue nil
      next unless programa

      # Determinar el campo de apellido según el tipo de formulario
      apellido = if inscripcion.is_a?(FormularioProgramaPreincubacion)
                   inscripcion.apellidos_lider  # plural para preincubación
                 else
                   inscripcion.apellido_lider   # singular para incubación e innovación
                 end

      actividades << {
        usuario: "#{inscripcion.nombre_lider} #{apellido}",
        accion: "se registró en",
        objetivo: programa.titulo,
        tiempo: time_ago_in_words(inscripcion.created_at),
        icono: "fas fa-user-plus",
        color_bg: "bg-blue-100",
        color_text: "text-blue-600",
        tipo: "programa",
        fecha: inscripcion.created_at
      }
    end

    # Obtener las 2 inscripciones más recientes de eventos
    inscripciones_eventos_recientes = FormularioEvento.where(es_plantilla: [false, nil])
                                                      .order(created_at: :desc)
                                                      .limit(2)
    
    inscripciones_eventos_recientes.each do |inscripcion|
      evento = inscripcion.event rescue nil
      next unless evento

      # Para eventos siempre es apellidos_lider (plural)
      actividades << {
        usuario: "#{inscripcion.nombre_lider} #{inscripcion.apellidos_lider}",
        accion: "se inscribió en el evento",
        objetivo: evento.titulo,
        tiempo: time_ago_in_words(inscripcion.created_at),
        icono: "fas fa-calendar-check",
        color_bg: "bg-purple-100",
        color_text: "text-purple-600",
        tipo: "evento",
        fecha: inscripcion.created_at
      }
    end

    # Ordenar todas las actividades por fecha (más recientes primero) y tomar las primeras 4
    actividades_ordenadas = actividades.sort_by { |a| a[:fecha] }.reverse.first(4)

    # Solo si no hay actividades reales, agregar ejemplos
    if actividades_ordenadas.empty?
      actividades_ordenadas = [
        {
          usuario: "Ana Rodriguez",
          accion: "se registró en",
          objetivo: "Programa de Innovación",
          tiempo: "Hace 1 día",
          icono: "fas fa-user-plus",
          color_bg: "bg-blue-100",
          color_text: "text-blue-600",
          tipo: "programa",
          fecha: 1.day.ago
        },
        {
          usuario: "Carlos Mendoza",
          accion: "se inscribió en el evento",
          objetivo: "Taller de Marketing Digital",
          tiempo: "Hace 2 días",
          icono: "fas fa-calendar-check",
          color_bg: "bg-purple-100",
          color_text: "text-purple-600",
          tipo: "evento",
          fecha: 2.days.ago
        }
      ]
    end

    # Retornar máximo 4 actividades
    actividades_ordenadas.first(4)
  end

  def obtener_inscripciones_programas_recientes(limite)
    inscripciones = []
    
    # Obtener de cada tipo de programa
    inscripciones += FormularioProgramaPreincubacion.where(es_plantilla: [false, nil])
                                                    .order(created_at: :desc)
                                                    .limit(limite)
    
    inscripciones += FormularioProgramaIncubacion.where(es_plantilla: [false, nil])
                                                 .order(created_at: :desc)
                                                 .limit(limite)
    
    inscripciones += FormularioProgramaInnovacion.where(es_plantilla: [false, nil])
                                                 .order(created_at: :desc)
                                                 .limit(limite)
    
    # Ordenar todas juntas y limitar
    inscripciones.sort_by(&:created_at).reverse.first(limite)
  end

  # Método auxiliar para formatear tiempo en español
  def time_ago_in_words(from_time)
    return '' unless from_time
    
    distance_in_seconds = Time.current - from_time
    
    case distance_in_seconds
    when 0..59
      'Hace unos segundos'
    when 60..3599
      minutos = (distance_in_seconds / 60).round
      "Hace #{minutos} minuto#{'s' if minutos != 1}"
    when 3600..86399
      horas = (distance_in_seconds / 3600).round
      "Hace #{horas} hora#{'s' if horas != 1}"
    when 86400..604799
      dias = (distance_in_seconds / 86400).round
      "Hace #{dias} día#{'s' if dias != 1}"
    when 604800..2629743
      semanas = (distance_in_seconds / 604800).round
      "Hace #{semanas} semana#{'s' if semanas != 1}"
    else
      meses = (distance_in_seconds / 2629743).round
      "Hace #{meses} mes#{'es' if meses != 1}"
    end
  end

  # Generar datos para el gráfico de inscripciones
  def generar_datos_grafico_inscripciones
    # Generar array de los últimos 6 meses incluyendo el actual
    meses = []
    (0..5).each do |i|
      meses << i.months.ago.beginning_of_month
    end
    meses.reverse! # Para que aparezcan del más antiguo al más reciente

    @meses_labels = meses.map { |mes| mes.strftime('%b %Y') }
    
    @inscripciones_programas_data = []
    @inscripciones_eventos_data = []

    meses.each do |mes|
      inicio_mes = mes.beginning_of_month
      fin_mes = mes.end_of_month

      # Contar inscripciones de programas en este mes
      inscripciones_programas_mes = calcular_participantes_programas_en_periodo(inicio_mes, fin_mes)
      @inscripciones_programas_data << inscripciones_programas_mes

      # Contar inscripciones de eventos en este mes
      inscripciones_eventos_mes = FormularioEvento.where(
        es_plantilla: [false, nil],
        created_at: inicio_mes..fin_mes
      ).count
      @inscripciones_eventos_data << inscripciones_eventos_mes
    end
  end

  def calcular_participantes_programas_en_periodo(inicio, fin)
    total = 0
    
    total += FormularioProgramaPreincubacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total += FormularioProgramaIncubacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total += FormularioProgramaInnovacion.where(
      es_plantilla: [false, nil],
      created_at: inicio..fin
    ).count
    
    total
  end
  end
end