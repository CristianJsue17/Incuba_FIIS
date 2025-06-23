# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_06_23_000457) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "beneficios", force: :cascade do |t|
    t.text "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "equipo_incubas", force: :cascade do |t|
    t.string "nombre"
    t.string "apellido"
    t.string "cargo"
    t.bigint "user_id", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_equipo_incubas_on_created_by_id"
    t.index ["updated_by_id"], name: "index_equipo_incubas_on_updated_by_id"
    t.index ["user_id"], name: "index_equipo_incubas_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "titulo"
    t.text "descripcion"
    t.string "encargado"
    t.datetime "fecha_publicacion", precision: nil
    t.datetime "fecha_vencimiento", precision: nil
    t.string "estado"
    t.string "archivo_bases_pitch"
    t.bigint "user_id", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_events_on_created_by_id"
    t.index ["updated_by_id"], name: "index_events_on_updated_by_id"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "events_patrocinadors", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "patrocinador_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_events_patrocinadors_on_event_id"
    t.index ["patrocinador_id"], name: "index_events_patrocinadors_on_patrocinador_id"
  end

  create_table "formulario_contactos", force: :cascade do |t|
    t.string "nombre"
    t.string "correo"
    t.string "asunto"
    t.text "mensaje"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "formulario_eventos", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.string "nombre_lider"
    t.string "apellidos_lider"
    t.string "dni_lider"
    t.string "correo_lider"
    t.string "telefono_lider"
    t.integer "numero_integrantes_equipo"
    t.string "nombre_emprendimiento"
    t.text "descripcion"
    t.text "cuentanos_proyecto"
    t.text "atributos_ventaja_diferenciacion"
    t.text "modelo_negocio"
    t.text "indicadores_metas_6meses"
    t.text "redes_sociales"
    t.string "web_startup"
    t.string "sector_economico"
    t.string "categoria"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "es_plantilla", default: false, null: false
    t.index ["es_plantilla"], name: "index_formulario_eventos_on_es_plantilla"
    t.index ["event_id"], name: "index_formulario_eventos_on_event_id"
  end

  create_table "formulario_programa_incubacions", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "nombre_lider"
    t.string "apellido_lider"
    t.string "dni_lider"
    t.string "telefono_lider"
    t.string "correo_lider"
    t.string "nombre_proyecto"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "es_plantilla", default: false, null: false
    t.index ["program_id", "es_plantilla"], name: "index_incubacion_program_plantilla"
    t.index ["program_id"], name: "index_formulario_programa_incubacions_on_program_id"
  end

  create_table "formulario_programa_innovacions", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "nombre_lider"
    t.string "apellido_lider"
    t.string "dni_lider"
    t.string "telefono_lider"
    t.string "correo_lider"
    t.string "nombre_proyecto"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "es_plantilla", default: false, null: false
    t.index ["program_id", "es_plantilla"], name: "index_innovacion_program_plantilla"
    t.index ["program_id"], name: "index_formulario_programa_innovacions_on_program_id"
  end

  create_table "formulario_programa_preincubacions", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.string "nombre_emprendimiento"
    t.text "descripcion"
    t.text "propuesta_valor"
    t.integer "numero_integrantes_equipo"
    t.string "nombre_lider"
    t.string "apellidos_lider"
    t.string "dni_lider"
    t.string "correo_lider"
    t.string "telefono_lider"
    t.string "ocupacion_lider"
    t.string "enteraste_programa"
    t.text "expectativas_programa"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "es_plantilla", default: false, null: false
    t.index ["program_id", "es_plantilla"], name: "index_preincubacion_program_plantilla"
    t.index ["program_id"], name: "index_formulario_programa_preincubacions_on_program_id"
  end

  create_table "ganadors", force: :cascade do |t|
    t.bigint "equipo_id"
    t.bigint "project_id", null: false
    t.bigint "program_id", null: false
    t.bigint "event_id", null: false
    t.decimal "monto_ganado"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipo_id"], name: "index_ganadors_on_equipo_id"
    t.index ["event_id"], name: "index_ganadors_on_event_id"
    t.index ["program_id"], name: "index_ganadors_on_program_id"
    t.index ["project_id"], name: "index_ganadors_on_project_id"
  end

  create_table "notificacions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "mensaje"
    t.boolean "leida"
    t.string "tipo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_notificacions_on_user_id"
  end

  create_table "objetivos", force: :cascade do |t|
    t.text "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "occupations", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "participacion_eventos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "event_id", null: false
    t.bigint "equipo_id"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipo_id"], name: "index_participacion_eventos_on_equipo_id"
    t.index ["event_id"], name: "index_participacion_eventos_on_event_id"
    t.index ["project_id"], name: "index_participacion_eventos_on_project_id"
    t.index ["user_id"], name: "index_participacion_eventos_on_user_id"
  end

  create_table "participacion_programas", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "program_id", null: false
    t.bigint "equipo_id"
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["equipo_id"], name: "index_participacion_programas_on_equipo_id"
    t.index ["program_id"], name: "index_participacion_programas_on_program_id"
    t.index ["project_id"], name: "index_participacion_programas_on_project_id"
    t.index ["user_id"], name: "index_participacion_programas_on_user_id"
  end

  create_table "patrocinadors", force: :cascade do |t|
    t.string "nombre"
    t.string "campo_laboral"
    t.text "mensaje"
    t.string "url"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_patrocinadors_on_created_by_id"
    t.index ["updated_by_id"], name: "index_patrocinadors_on_updated_by_id"
  end

  create_table "program_beneficios", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "beneficio_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["beneficio_id"], name: "index_program_beneficios_on_beneficio_id"
    t.index ["program_id"], name: "index_program_beneficios_on_program_id"
  end

  create_table "program_objetivos", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "objetivo_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["objetivo_id"], name: "index_program_objetivos_on_objetivo_id"
    t.index ["program_id"], name: "index_program_objetivos_on_program_id"
  end

  create_table "program_requisitos", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "requisito_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["program_id"], name: "index_program_requisitos_on_program_id"
    t.index ["requisito_id"], name: "index_program_requisitos_on_requisito_id"
  end

  create_table "programs", force: :cascade do |t|
    t.string "titulo"
    t.text "descripcion"
    t.string "encargado"
    t.string "tipo"
    t.datetime "fecha_publicacion", precision: nil
    t.datetime "fecha_vencimiento", precision: nil
    t.string "estado"
    t.bigint "user_id", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_programs_on_created_by_id"
    t.index ["updated_by_id"], name: "index_programs_on_updated_by_id"
    t.index ["user_id"], name: "index_programs_on_user_id"
  end

  create_table "programs_patrocinadors", force: :cascade do |t|
    t.bigint "program_id", null: false
    t.bigint "patrocinador_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patrocinador_id"], name: "index_programs_patrocinadors_on_patrocinador_id"
    t.index ["program_id"], name: "index_programs_patrocinadors_on_program_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "nombre"
    t.bigint "equipo_id", null: false
    t.bigint "lider_id", null: false
    t.string "tipo"
    t.boolean "gano"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_projects_on_created_by_id"
    t.index ["equipo_id"], name: "index_projects_on_equipo_id"
    t.index ["lider_id"], name: "index_projects_on_lider_id"
    t.index ["updated_by_id"], name: "index_projects_on_updated_by_id"
  end

  create_table "recurso_academicos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "titulo"
    t.text "descripcion"
    t.string "archivo"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_recurso_academicos_on_created_by_id"
    t.index ["updated_by_id"], name: "index_recurso_academicos_on_updated_by_id"
    t.index ["user_id"], name: "index_recurso_academicos_on_user_id"
  end

  create_table "requisitos", force: :cascade do |t|
    t.text "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "nombre_equipo"
    t.string "nombre_lider"
    t.integer "cantidad_miembros"
    t.text "lista_integrantes_equipo"
    t.bigint "mentor_id", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_teams_on_created_by_id"
    t.index ["mentor_id"], name: "index_teams_on_mentor_id"
    t.index ["updated_by_id"], name: "index_teams_on_updated_by_id"
  end

  create_table "testimonios", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "mensaje"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_testimonios_on_created_by_id"
    t.index ["updated_by_id"], name: "index_testimonios_on_updated_by_id"
    t.index ["user_id"], name: "index_testimonios_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "nombre"
    t.string "apellido"
    t.text "descripcion"
    t.string "telefono"
    t.datetime "ultimo_acceso", precision: nil
    t.string "facultad"
    t.string "estado"
    t.string "dni"
    t.integer "cantidad_miembros_equipo"
    t.string "nombre_proyectos"
    t.string "proviene"
    t.bigint "occupation_id", null: false
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.index ["created_by_id"], name: "index_users_on_created_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["occupation_id"], name: "index_users_on_occupation_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["updated_by_id"], name: "index_users_on_updated_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "equipo_incubas", "users"
  add_foreign_key "equipo_incubas", "users", column: "created_by_id"
  add_foreign_key "equipo_incubas", "users", column: "updated_by_id"
  add_foreign_key "events", "users"
  add_foreign_key "events", "users", column: "created_by_id"
  add_foreign_key "events", "users", column: "updated_by_id"
  add_foreign_key "events_patrocinadors", "events"
  add_foreign_key "events_patrocinadors", "patrocinadors"
  add_foreign_key "formulario_eventos", "events"
  add_foreign_key "formulario_programa_incubacions", "programs"
  add_foreign_key "formulario_programa_innovacions", "programs"
  add_foreign_key "formulario_programa_preincubacions", "programs"
  add_foreign_key "ganadors", "events"
  add_foreign_key "ganadors", "programs"
  add_foreign_key "ganadors", "projects"
  add_foreign_key "ganadors", "teams", column: "equipo_id"
  add_foreign_key "notificacions", "users"
  add_foreign_key "participacion_eventos", "events"
  add_foreign_key "participacion_eventos", "projects"
  add_foreign_key "participacion_eventos", "teams", column: "equipo_id"
  add_foreign_key "participacion_eventos", "users"
  add_foreign_key "participacion_programas", "programs"
  add_foreign_key "participacion_programas", "projects"
  add_foreign_key "participacion_programas", "teams", column: "equipo_id"
  add_foreign_key "participacion_programas", "users"
  add_foreign_key "patrocinadors", "users", column: "created_by_id"
  add_foreign_key "patrocinadors", "users", column: "updated_by_id"
  add_foreign_key "program_beneficios", "beneficios"
  add_foreign_key "program_beneficios", "programs"
  add_foreign_key "program_objetivos", "objetivos"
  add_foreign_key "program_objetivos", "programs"
  add_foreign_key "program_requisitos", "programs"
  add_foreign_key "program_requisitos", "requisitos"
  add_foreign_key "programs", "users"
  add_foreign_key "programs", "users", column: "created_by_id"
  add_foreign_key "programs", "users", column: "updated_by_id"
  add_foreign_key "programs_patrocinadors", "patrocinadors"
  add_foreign_key "programs_patrocinadors", "programs"
  add_foreign_key "projects", "teams", column: "equipo_id"
  add_foreign_key "projects", "users", column: "created_by_id"
  add_foreign_key "projects", "users", column: "lider_id"
  add_foreign_key "projects", "users", column: "updated_by_id"
  add_foreign_key "recurso_academicos", "users"
  add_foreign_key "recurso_academicos", "users", column: "created_by_id"
  add_foreign_key "recurso_academicos", "users", column: "updated_by_id"
  add_foreign_key "teams", "users", column: "created_by_id"
  add_foreign_key "teams", "users", column: "mentor_id"
  add_foreign_key "teams", "users", column: "updated_by_id"
  add_foreign_key "testimonios", "users"
  add_foreign_key "testimonios", "users", column: "created_by_id"
  add_foreign_key "testimonios", "users", column: "updated_by_id"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "users", "occupations"
  add_foreign_key "users", "users", column: "created_by_id"
  add_foreign_key "users", "users", column: "updated_by_id"
end
