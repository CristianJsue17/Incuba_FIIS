#!/bin/bash

echo "🎯 PRUEBAS DE CARGA ESPECÍFICAS - INCUBAUNAS"
echo "============================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para verificar que la aplicación esté corriendo
check_app_running() {
    echo -e "${BLUE}🔍 VERIFICANDO QUE LA APLICACIÓN ESTÉ CORRIENDO${NC}"
    echo "=============================================="
    
    if curl -s "http://localhost:3200" > /dev/null; then
        echo -e "${GREEN}✅ Aplicación corriendo en http://localhost:3200${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}❌ La aplicación no está corriendo${NC}"
        echo -e "${YELLOW}💡 Ejecuta: docker-compose up -d${NC}"
        echo ""
        return 1
    fi
}

# Test 1: Múltiples usuarios navegando simultáneamente
test_concurrent_users() {
    echo -e "${BLUE}👥 TEST 1: USUARIOS CONCURRENTES NAVEGANDO${NC}"
    echo "=========================================="
    
    echo "🚀 Simulando 20 usuarios navegando simultáneamente..."
    
    # Array de páginas principales de IncubaUNAS
    pages=(
        "http://localhost:3200/"
        "http://localhost:3200/programas"
        "http://localhost:3200/eventos" 
        "http://localhost:3200/servicios"
        "http://localhost:3200/mentores"
    )
    
    # Monitorear Docker durante la prueba
    echo "📊 Iniciando monitoreo de recursos..."
    docker stats incuba-fiis-web --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" > /tmp/before_load.txt
    
    echo "⏱️ Ejecutando carga de usuarios concurrentes..."
    
    # Crear múltiples requests concurrentes
    for i in {1..20}; do
        page=${pages[$((RANDOM % ${#pages[@]}))]}
        (
            start_time=$(date +%s%N)
            curl -s "$page" > /dev/null 2>&1
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            echo "Usuario $i: ${duration}ms - $page"
        ) &
        
        # Pequeño delay para simular llegada gradual
        sleep 0.1
    done
    
    # Esperar que terminen todas las requests
    wait
    
    # Monitorear Docker después de la carga
    docker stats incuba-fiis-web --no-stream --format "table {{.CPUPerc}}\t{{.MemUsage}}" > /tmp/after_load.txt
    
    echo ""
    echo "📊 Estadísticas de recursos:"
    echo "Antes: $(cat /tmp/before_load.txt)"
    echo "Después: $(cat /tmp/after_load.txt)"
    echo ""
}

# Test 2: Formularios pesados (registro de eventos/programas)
test_heavy_forms() {
    echo -e "${BLUE}📝 TEST 2: FORMULARIOS PESADOS${NC}"
    echo "=============================="
    
    echo "🧪 Simulando envío de múltiples formularios..."
    
    # Datos de prueba para formularios
    form_data=(
        "name=Evento+Test+1&description=Descripcion+larga+del+evento"
        "name=Programa+Test+2&type=incubacion&duration=6+meses"
        "name=Testimonio+Test+3&content=Un+testimonio+muy+largo"
    )
    
    for i in {1..10}; do
        data=${form_data[$((RANDOM % ${#form_data[@]}))]}
        (
            start_time=$(date +%s%N)
            # Simular POST request (ajusta la URL según tu aplicación)
            curl -s -X POST -d "$data" "http://localhost:3200/" > /dev/null 2>&1
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            echo "Formulario $i: ${duration}ms"
        ) &
        
        sleep 0.2
    done
    
    wait
    echo ""
}

# Test 3: Simulación de exports masivos (PDF/Excel)
test_export_stress() {
    echo -e "${BLUE}📊 TEST 3: EXPORTS MASIVOS${NC}"
    echo "=========================="
    
    echo "🗂️ Simulando múltiples exports simultáneos..."
    
    # Simular requests de export (ajusta URLs según tu app)
    export_urls=(
        "http://localhost:3200/programas.pdf"
        "http://localhost:3200/eventos.xlsx" 
        "http://localhost:3200/reportes/participantes.pdf"
    )
    
    for i in {1..5}; do
        url=${export_urls[$((RANDOM % ${#export_urls[@]}))]}
        (
            start_time=$(date +%s%N)
            curl -s "$url" > /dev/null 2>&1
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            echo "Export $i: ${duration}ms - $url"
        ) &
        
        sleep 0.5
    done
    
    wait
    echo ""
}

# Test 4: API DNI bajo carga
test_dni_api_load() {
    echo -e "${BLUE}🆔 TEST 4: API DNI BAJO CARGA${NC}"
    echo "============================"
    
    echo "📱 Simulando múltiples consultas DNI simultáneas..."
    
    # DNIs de prueba (usa números ficticios)
    test_dnis=(
        "12345678"
        "87654321" 
        "11111111"
        "22222222"
        "33333333"
    )
    
    for i in {1..15}; do
        dni=${test_dnis[$((RANDOM % ${#test_dnis[@]}))]}
        (
            start_time=$(date +%s%N)
            # Ajusta la URL según tu endpoint de DNI
            curl -s "http://localhost:3200/api/dni/$dni" > /dev/null 2>&1
            end_time=$(date +%s%N)
            duration=$(( (end_time - start_time) / 1000000 ))
            echo "DNI $i ($dni): ${duration}ms"
        ) &
        
        sleep 0.3
    done
    
    wait
    echo ""
}

# Test 5: Carga sostenida (simular día completo)
test_sustained_load() {
    echo -e "${BLUE}⏰ TEST 5: CARGA SOSTENIDA${NC}"
    echo "========================="
    
    echo "🕐 Simulando carga continua por 2 minutos..."
    echo "💡 Este test simula uso real durante un día completo"
    
    # Archivo para logs
    echo "timestamp,cpu,memory" > /tmp/sustained_load.csv
    
    end_time=$(($(date +%s) + 120)) # 2 minutos
    request_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        # Request random cada 2-5 segundos
        sleep $((2 + RANDOM % 4))
        
        # Request background
        (curl -s "http://localhost:3200/" > /dev/null 2>&1) &
        
        # Log recursos cada 10 requests
        if [ $((request_count % 10)) -eq 0 ]; then
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            stats=$(docker stats incuba-fiis-web --no-stream --format "{{.CPUPerc}},{{.MemUsage}}")
            echo "$timestamp,$stats" >> /tmp/sustained_load.csv
            echo "📊 $timestamp - Request #$request_count - Stats: $stats"
        fi
        
        request_count=$((request_count + 1))
    done
    
    echo ""
    echo "📊 Carga sostenida completada. Requests totales: $request_count"
    echo "📄 Log guardado en: /tmp/sustained_load.csv"
    echo ""
}

# Test 6: Stress test hasta el límite
echo "💥 STRESS TEST MEJORADO - MONITOREO DE RECURSOS"
echo "==============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para obtener estadísticas detalladas
get_detailed_stats() {
    local label="$1"
    
    echo -e "${CYAN}📊 [$label] RECURSOS DEL SISTEMA:${NC}"
    echo "=================================="
    
    # Stats de Docker
    DOCKER_STATS=$(docker stats incuba-fiis-web --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}")
    
    # Separar los valores
    CPU_PERC=$(echo $DOCKER_STATS | cut -d',' -f1)
    MEM_USAGE=$(echo $DOCKER_STATS | cut -d',' -f2)
    MEM_PERC=$(echo $DOCKER_STATS | cut -d',' -f3)
    NET_IO=$(echo $DOCKER_STATS | cut -d',' -f4)
    BLOCK_IO=$(echo $DOCKER_STATS | cut -d',' -f5)
    
    echo -e "🖥️  CPU Usage:      ${YELLOW}$CPU_PERC${NC}"
    echo -e "💾 Memory Usage:   ${YELLOW}$MEM_USAGE${NC} (${MEM_PERC})"
    echo -e "🌐 Network I/O:    ${BLUE}$NET_IO${NC}"
    echo -e "💿 Block I/O:      ${BLUE}$BLOCK_IO${NC}"
    
    # Stats adicionales del sistema
    echo ""
    echo -e "${PURPLE}🔧 DETALLES ADICIONALES:${NC}"
    echo "========================"
    
    # Procesos dentro del contenedor
    PROCESSES=$(docker exec incuba-fiis-web ps aux --no-headers | wc -l)
    echo -e "⚙️  Procesos activos: ${GREEN}$PROCESSES${NC}"
    
    # Conexiones de base de datos
    DB_CONNECTIONS=$(docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -t -c "SELECT count(*) FROM pg_stat_activity WHERE datname = 'incuba_fiis_development';" 2>/dev/null | tr -d ' ')
    echo -e "🗄️  Conexiones DB:   ${GREEN}$DB_CONNECTIONS${NC}"
    
    # Uso de disco
    DISK_USAGE=$(docker exec incuba-fiis-web df -h / | tail -1 | awk '{print $5}')
    echo -e "💾 Uso de disco:    ${GREEN}$DISK_USAGE${NC}"
    
    # Load average del contenedor (si está disponible)
    LOAD_AVG=$(docker exec incuba-fiis-web cat /proc/loadavg 2>/dev/null | awk '{print $1}' || echo "N/A")
    echo -e "📈 Load Average:    ${GREEN}$LOAD_AVG${NC}"
    
    echo ""
    
    # Guardar en CSV para análisis posterior
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$TIMESTAMP,$label,$CPU_PERC,$MEM_USAGE,$MEM_PERC,$NET_IO,$BLOCK_IO,$PROCESSES,$DB_CONNECTIONS,$DISK_USAGE,$LOAD_AVG" >> /tmp/stress_test_detailed.csv
}

# Función para crear header del CSV
create_csv_header() {
    echo "timestamp,test_phase,cpu_percent,memory_usage,memory_percent,network_io,block_io,processes,db_connections,disk_usage,load_average" > /tmp/stress_test_detailed.csv
    echo -e "${GREEN}📄 Log detallado creado: /tmp/stress_test_detailed.csv${NC}"
    echo ""
}

# Función de stress test mejorada
enhanced_stress_test() {
    echo -e "${RED}⚠️ ADVERTENCIA: Este test intentará sobrecargar el sistema${NC}"
    echo -e "${YELLOW}🤔 ¿Continuar? (y/n)${NC}"
    read -r response
    
    if [[ "$response" != "y" ]]; then
        echo "❌ Test cancelado"
        return
    fi
    
    # Crear CSV header
    create_csv_header
    
    echo -e "${BLUE}🚀 INICIANDO STRESS TEST CON MONITOREO DETALLADO${NC}"
    echo "=============================================="
    echo ""
    
    # Baseline - estado inicial
    echo -e "${CYAN}📊 BASELINE - ESTADO INICIAL${NC}"
    get_detailed_stats "BASELINE"
    
    # Array de niveles de concurrencia
    concurrent_levels=(10 25 50 100 200)
    
    for concurrent in "${concurrent_levels[@]}"; do
        echo ""
        echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
        echo -e "${YELLOW}🔥 PROBANDO CON $concurrent REQUESTS CONCURRENTES${NC}"
        echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
        echo ""
        
        # Estado PRE-test
        echo -e "${PURPLE}📋 ANTES DEL TEST $concurrent:${NC}"
        get_detailed_stats "PRE-$concurrent"
        
        echo -e "${BLUE}⏱️ Ejecutando $concurrent requests concurrentes...${NC}"
        
        start_time=$(date +%s)
        
        # Ejecutar requests concurrentes
        for i in $(seq 1 $concurrent); do
            curl -s "http://localhost:3200/" > /dev/null 2>&1 &
        done
        
        # Monitoreo DURANTE la ejecución
        echo -e "${GREEN}📊 DURANTE LA EJECUCIÓN:${NC}"
        sleep 2  # Dar tiempo para que se establezcan las conexiones
        get_detailed_stats "DURING-$concurrent"
        
        # Esperar a que terminen todas las requests
        wait
        
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        
        # Estado POST-test
        echo ""
        echo -e "${GREEN}✅ $concurrent requests completadas en ${duration}s${NC}"
        echo ""
        echo -e "${PURPLE}📋 DESPUÉS DEL TEST $concurrent:${NC}"
        get_detailed_stats "POST-$concurrent"
        
        # Verificar que el contenedor siga vivo
        if docker ps | grep -q "incuba-fiis-web"; then
            echo -e "${GREEN}✅ Contenedor estable después de $concurrent requests${NC}"
        else
            echo -e "${RED}❌ ¡CONTENEDOR FALLÓ con $concurrent requests!${NC}"
            echo -e "${RED}💥 Límite encontrado: $concurrent requests concurrentes${NC}"
            break
        fi
        
        # Pausa para recuperación
        echo ""
        echo -e "${YELLOW}⏳ Esperando 15s para recuperación del sistema...${NC}"
        for i in {15..1}; do
            echo -ne "\r⏱️  Recuperación: ${i}s restantes..."
            sleep 1
        done
        echo ""
        
        # Estado después de recuperación
        echo -e "${PURPLE}📋 DESPUÉS DE RECUPERACIÓN:${NC}"
        get_detailed_stats "RECOVERY-$concurrent"
        
    done
    
    echo ""
    echo -e "${GREEN}🏁 STRESS TEST COMPLETADO${NC}"
    echo "========================"
    
    # Estado final del sistema
    echo ""
    echo -e "${CYAN}📊 ESTADO FINAL DEL SISTEMA${NC}"
    get_detailed_stats "FINAL"
    
    # Resumen de archivos generados
    echo ""
    echo -e "${GREEN}📁 ARCHIVOS GENERADOS:${NC}"
    echo "- 📊 /tmp/stress_test_detailed.csv (log completo)"
    echo ""
    echo -e "${BLUE}💡 Para analizar los resultados:${NC}"
    echo "   cat /tmp/stress_test_detailed.csv | column -t -s','"
    echo ""
}

# Función para mostrar análisis del CSV
analyze_results() {
    if [[ ! -f /tmp/stress_test_detailed.csv ]]; then
        echo -e "${RED}❌ No se encontró archivo de resultados${NC}"
        echo "Ejecuta primero: $0 stress"
        return
    fi
    
    echo -e "${BLUE}📈 ANÁLISIS DE RESULTADOS DEL STRESS TEST${NC}"
    echo "========================================"
    echo ""
    
    echo -e "${YELLOW}📊 TABLA COMPLETA DE RESULTADOS:${NC}"
    cat /tmp/stress_test_detailed.csv | column -t -s','
    echo ""
    
    echo -e "${YELLOW}🎯 RESUMEN POR FASE:${NC}"
    echo "==================="
    
    # Extraer y mostrar solo las fases principales
    grep -E "(BASELINE|PRE-|DURING-|POST-)" /tmp/stress_test_detailed.csv | while IFS=',' read timestamp phase cpu mem mem_perc net block proc db disk load; do
        echo -e "${GREEN}$phase${NC}: CPU=$cpu, RAM=$mem, Proc=$proc, DB=$db"
    done
    
    echo ""
    echo -e "${PURPLE}💾 Archivo completo disponible en: /tmp/stress_test_detailed.csv${NC}"
}

# Función para limpiar logs anteriores
clean_logs() {
    rm -f /tmp/stress_test_detailed.csv
    echo -e "${GREEN}🧹 Logs de stress test limpiados${NC}"
}

# Menú principal
case "$1" in
    "stress")
        enhanced_stress_test
        ;;
    "analyze")
        analyze_results
        ;;
    "clean")
        clean_logs
        ;;
    *)
        echo -e "${BLUE}💥 STRESS TEST MEJORADO CON MONITOREO - INCUBAUNAS${NC}"
        echo "=============================================="
        echo ""
        echo "Uso: $0 [opción]"
        echo ""
        echo "Opciones disponibles:"
        echo "  stress   - 💥 Ejecutar stress test con monitoreo detallado"
        echo "  analyze  - 📈 Analizar resultados del último test"
        echo "  clean    - 🧹 Limpiar logs anteriores"
        echo ""
        echo "Ejemplos:"
        echo "  $0 stress"
        echo "  $0 analyze"
        echo ""
        echo -e "${YELLOW}💡 El test mostrará CPU, RAM, procesos, y conexiones DB en cada escalón${NC}"
        echo -e "${YELLOW}📊 Todos los datos se guardan en CSV para análisis posterior${NC}"
        ;;
esac


# Reporte final
generate_final_report() {
    echo -e "${BLUE}📋 REPORTE FINAL DE PRUEBAS${NC}"
    echo "=========================="
    
    echo "🗄️ Estado de la base de datos:"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            count(*) as conexiones_activas,
            now() as timestamp
        FROM pg_stat_activity 
        WHERE datname = 'incuba_fiis_development';
    " 2>/dev/null
    
    echo ""
    echo "🐳 Estado del contenedor:"
    docker stats incuba-fiis-web --no-stream
    
    echo ""
    echo "💾 Uso de disco:"
    docker exec incuba-fiis-web df -h | head -2
    
    echo ""
    echo -e "${GREEN}✅ TODAS LAS PRUEBAS COMPLETADAS${NC}"
    echo ""
    echo "📊 Archivos generados:"
    echo "- /tmp/sustained_load.csv (carga sostenida)"
    echo "- /tmp/before_load.txt y /tmp/after_load.txt (comparación recursos)"
    echo ""
}

# Menú principal
case "$1" in
    "users")
        check_app_running && test_concurrent_users
        ;;
    "forms")
        check_app_running && test_heavy_forms
        ;;
    "exports")
        check_app_running && test_export_stress
        ;;
    "dni")
        check_app_running && test_dni_api_load
        ;;
    "sustained")
        check_app_running && test_sustained_load
        ;;
    "stress")
        check_app_running && test_stress_breaking_point
        ;;
    "report")
        generate_final_report
        ;;
    "all")
        echo -e "${YELLOW}🎯 EJECUTANDO SUITE COMPLETA DE PRUEBAS${NC}"
        echo "======================================"
        if check_app_running; then
            test_concurrent_users
            test_heavy_forms
            test_export_stress
            test_dni_api_load
            test_sustained_load
            generate_final_report
        fi
        ;;
    *)
        echo -e "${BLUE}🚀 PRUEBAS DE CARGA ESPECÍFICAS - INCUBAUNAS${NC}"
        echo "==========================================="
        echo ""
        echo "Uso: $0 [opción]"
        echo ""
        echo "Opciones disponibles:"
        echo "  users      - 👥 Usuarios concurrentes navegando"
        echo "  forms      - 📝 Formularios pesados simultáneos"
        echo "  exports    - 📊 Exports masivos (PDF/Excel)"
        echo "  dni        - 🆔 API DNI bajo carga"
        echo "  sustained  - ⏰ Carga sostenida (2 minutos)"
        echo "  stress     - 💥 Punto de ruptura del sistema"
        echo "  report     - 📋 Reporte final del estado"
        echo "  all        - 🎯 Ejecutar todas las pruebas"
        echo ""
        echo "Ejemplos:"
        echo "  $0 users"
        echo "  $0 dni"
        echo "  $0 all"
        echo ""
        echo -e "${YELLOW}💡 Recomendación: Empieza con 'users' y luego 'dni'${NC}"
        ;;
esac