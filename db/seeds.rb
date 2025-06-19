# db/seeds.rb
puts "🌱 Iniciando Seed..."

# Crear roles base
puts "Creando Roles base..."
roles = ["Administrador", "Participante", "Mentor"]
roles.each do |role_name|
  Role.find_or_create_by!(nombre: role_name)
end
puts "Roles creados: #{roles.join(', ')}"

# Crear occupations base
puts "Creando Ocupaciones base..."
occupations = [
  "Estudiante Pregrado",
  "Estudiante Postgrado",
  "Egresado",
  "Docente",
  "Administrativo",
  "Otros"
]
occupations.each do |occupation_name|
  Occupation.find_or_create_by!(nombre: occupation_name)
end
puts "Ocupaciones creadas: #{occupations.join(', ')}"

# Crear o encontrar el Usuario Admin
puts "Creando Usuario Admin..."
admin = User.find_or_initialize_by(email: "admin@example.com")
admin.update!(
  nombre: "Cristian",
  apellido: "Developer",
  descripcion: "Administrador principal de Incuba UNAS",
  telefono: "987654321",
  ultimo_acceso: Time.now,
  facultad: "Ingeniería",
  estado: "activo",
  dni: "12345678",
  cantidad_miembros_equipo: 0,
  nombre_proyectos: "N/A",
  proviene: "IncubaUNAS",
  password: "12345678",
  password_confirmation: "12345678",
  occupation: Occupation.find_by(nombre: "Administrativo"),
  created_by: nil,
  updated_by: nil
)
puts "Usuario Admin creado: #{admin.nombre} #{admin.apellido}"

# Crear Usuario Participante
puts "Creando Usuario Participante..."
participante = User.find_or_initialize_by(email: "participante@example.com")
participante.update!(
  nombre: "María",
  apellido: "Emprendedora",
  descripcion: "Estudiante emprendedora con ideas innovadoras",
  telefono: "987654322",
  ultimo_acceso: Time.now,
  facultad: "Administración",
  estado: "activo",
  dni: "12345679",
  cantidad_miembros_equipo: 3,
  nombre_proyectos: "EcoApp, GreenTech",
  proviene: "Universidad",
  password: "12345678",
  password_confirmation: "12345678",
  occupation: Occupation.find_by(nombre: "Estudiante Pregrado"),
  created_by: admin,
  updated_by: admin
)
puts "Usuario Participante creado: #{participante.nombre} #{participante.apellido}"

# Crear Usuario Mentor
puts "Creando Usuario Mentor..."
mentor = User.find_or_initialize_by(email: "mentor@example.com")
mentor.update!(
  nombre: "Dr. Carlos",
  apellido: "Asesor",
  descripcion: "Mentor especialista en tecnología y negocios con 15 años de experiencia",
  telefono: "987654323",
  ultimo_acceso: Time.now,
  facultad: "Ingeniería de Sistemas",
  estado: "activo",
  dni: "12345680",
  cantidad_miembros_equipo: 0,
  nombre_proyectos: "TechCorp, InnovaSoft, DataSolutions",
  proviene: "Sector Empresarial",
  password: "12345678",
  password_confirmation: "12345678",
  occupation: Occupation.find_by(nombre: "Docente"),
  created_by: admin,
  updated_by: admin
)
puts "Usuario Mentor creado: #{mentor.nombre} #{mentor.apellido}"

# Asignar Rol de Administrador al Usuario Admin
puts "Asignando rol de Administrador al Admin..."
admin_role = Role.find_by(nombre: "Administrador")
UserRole.find_or_create_by!(user: admin, role: admin_role)

# Asignar Rol de Participante al Usuario Participante
puts "Asignando rol de Participante..."
participante_role = Role.find_by(nombre: "Participante")
UserRole.find_or_create_by!(user: participante, role: participante_role)

# Asignar Rol de Mentor al Usuario Mentor
puts "Asignando rol de Mentor..."
mentor_role = Role.find_by(nombre: "Mentor")
UserRole.find_or_create_by!(user: mentor, role: mentor_role)

# Crear Programas
puts "Creando Programas..."
2.times do |i|
  Program.find_or_create_by!(
    titulo: "Programa #{i + 1}",
    user_id: admin.id
  ) do |program|
    program.descripcion = "Descripción del Programa #{i + 1} para emprendedores innovadores."
    program.encargado = "Encargado #{i + 1}"
    program.tipo = ["preincubacion", "incubacion", "innovacion"].sample
    program.fecha_publicacion = Time.now - rand(1..10).days
    program.fecha_vencimiento = Time.now + rand(10..30).days
    program.estado = "activo"
    program.created_by = admin
    program.updated_by = admin
  end
end

# Crear Eventos
puts "Creando Eventos..."
2.times do |i|
  Event.find_or_create_by!(
    titulo: "Evento #{i + 1}",
    user_id: admin.id
  ) do |event|
    event.descripcion = "Evento imperdible sobre innovación y emprendimiento #{i + 1}."
    event.encargado = "Coordinador #{i + 1}"
    event.fecha_publicacion = Time.now - rand(1..10).days
    event.fecha_vencimiento = Time.now + rand(10..20).days
    event.estado = "activo"
    event.created_by = admin
    event.updated_by = admin
  end
end

# Crear Testimonios
puts "Creando Testimonios..."
testimonios_data = [
  {
    mensaje: "Gracias al programa de incubación, mi startup ahora tiene tracción real. ¡Totalmente recomendado!",
    user: participante
  },
  {
    mensaje: "Como mentor, es increíble ver cómo los emprendedores desarrollan sus ideas aquí.",
    user: mentor
  }
]

testimonios_data.each_with_index do |testimonio_data, i|
  Testimonio.find_or_create_by!(
    mensaje: testimonio_data[:mensaje],
    user_id: testimonio_data[:user].id
  ) do |testimonio|
    testimonio.created_by = admin
    testimonio.updated_by = admin
  end
end

# Crear Equipo Incuba
puts "Creando Miembros del Equipo..."
[
  ['Mg. Melisa', 'Zavala Guerrero', 'Directora de INCUBA UNAS'],
  ['Econ. Pedro', 'Pérez Pinedo', 'Coordinador de Programas'],
  ['Lic. Carlos', 'Hidalgo Gomez', 'Especialista en emprendimiento e innovación'],
  ['Lic.Adm. Steven', 'Nieto', 'Especialista en Marketing']
].each do |nombre, apellido, cargo|
  EquipoIncuba.find_or_create_by!(nombre: nombre, apellido: apellido) do |miembro|
    miembro.cargo = cargo
    miembro.user = admin
    miembro.created_by = admin
    miembro.updated_by = admin
  end
end

puts "✅ Seeds creados exitosamente."
puts "👤 Usuarios creados:"
puts "   🔧 Admin: admin@example.com (password: 12345678)"
puts "   🎯 Participante: participante@example.com (password: 12345678)"
puts "   🧑‍🏫 Mentor: mentor@example.com (password: 12345678)"