# config/initializers/scheduler.rb
require 'rufus-scheduler'

# No ejecutar en la consola o durante migraciones
scheduler_skipped = defined?(Rails::Console) || Rails.env.test? || File.split($PROGRAM_NAME).last == 'rake'

unless scheduler_skipped
  Rails.logger.info "Iniciando Rufus Scheduler en #{Time.current}"
  
  scheduler = Rufus::Scheduler.new
  
  # Tarea principal cada 10 minutos
  scheduler.every '10m' do
    Rails.logger.info "Ejecutando tarea programada cada 5 minutos: #{Time.current}"
    UpdateProgramEstadosJob.perform_now  # Usar perform_now en lugar de perform_later
  end
  
  # Puedes eliminar la tarea de prueba ya que ya no es necesaria
  
  Rails.logger.info "Rufus Scheduler iniciado correctamente con #{scheduler.jobs.size} tareas"
else
  Rails.logger.info "Rufus Scheduler no iniciado (ejecución en consola, test o rake)"
end