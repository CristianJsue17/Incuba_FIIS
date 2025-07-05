# Script para monitorear CPU y RAM del contenedor Rails
# Guarda este archivo como: monitor_docker.sh

#!/bin/bash

echo "🎯 INICIANDO MONITOREO DE RENDIMIENTO "
echo "=================================================="
echo ""

# Crear directorio para logs si no existe
mkdir -p performance_logs

# Función para obtener estadísticas del contenedor
get_container_stats() {
    echo "📊 $(date '+%Y-%m-%d %H:%M:%S') - Estadísticas del contenedor:"
    docker stats incuba-fiis-web --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
}

# Función para monitoreo continuo
continuous_monitoring() {
    echo "🔄 Iniciando monitoreo continuo (presiona Ctrl+C para detener)..."
    echo "Timestamp,CPU%,Memory_Usage,Memory%,Network_In,Network_Out,Block_Read,Block_Write" > performance_logs/docker_stats.csv
    
    while true; do
        # Obtener estadísticas en formato CSV
        STATS=$(docker stats incuba-fiis-web --no-stream --format "{{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}")
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "$TIMESTAMP,$STATS" >> performance_logs/docker_stats.csv
        echo "📈 $TIMESTAMP - CPU: $(echo $STATS | cut -d',' -f1) | RAM: $(echo $STATS | cut -d',' -f2)"
        sleep 5
    done
}

# Función para prueba de carga básica
load_test_basic() {
    echo "⚡ EJECUTANDO PRUEBA DE CARGA BÁSICA"
    echo "===================================="
    
    # Verificar que el contenedor esté corriendo
    if ! docker ps | grep -q "incuba-fiis-web"; then
        echo "❌ El contenedor incuba-fiis-web no está corriendo"
        echo "💡 Ejecuta: docker-compose up -d"
        exit 1
    fi
    
    echo "📊 Estado inicial del contenedor:"
    get_container_stats
    
    echo "🚀 Realizando peticiones HTTP para generar carga..."
    
    # Hacer peticiones concurrentes (ajusta la URL según tu aplicación)
    for i in {1..50}; do
        curl -s "http://localhost:3200/" > /dev/null &
        if [ $((i % 10)) -eq 0 ]; then
            echo "📡 Enviadas $i peticiones..."
            get_container_stats
        fi
    done
    
    wait # Esperar a que terminen todas las peticiones
    
    echo "📊 Estado final del contenedor:"
    get_container_stats
}

# Función para mostrar uso de disco del contenedor
disk_usage() {
    echo "💾 USO DE DISCO DEL CONTENEDOR"
    echo "=============================="
    
    echo "📦 Tamaño del contenedor:"
    docker system df
    echo ""
    
    echo "📁 Uso de disco dentro del contenedor:"
    docker exec incuba-fiis-web df -h
    echo ""
    
    echo "📊 Uso específico de directorios de Rails:"
    docker exec incuba-fiis-web du -sh /app/log /app/tmp /app/public 2>/dev/null || echo "Algunos directorios no encontrados"
}

# Menú principal
case "$1" in
    "stats")
        get_container_stats
        ;;
    "continuous")
        continuous_monitoring
        ;;
    "load")
        load_test_basic
        ;;
    "disk")
        disk_usage
        ;;
    "all")
        echo "🎯 EJECUTANDO TODAS LAS PRUEBAS DE RENDIMIENTO"
        echo "=============================================="
        get_container_stats
        disk_usage
        load_test_basic
        ;;
    *)
        echo "🚀 SCRIPT DE MONITOREO DOCKER - INCUBAUNAS"
        echo "=========================================="
        echo ""
        echo "Uso: $0 [opción]"
        echo ""
        echo "Opciones disponibles:"
        echo "  stats      - Mostrar estadísticas actuales del contenedor"
        echo "  continuous - Monitoreo continuo (guarda en CSV)"
        echo "  load       - Ejecutar prueba de carga básica"
        echo "  disk       - Mostrar uso de disco"
        echo "  all        - Ejecutar todas las pruebas"
        echo ""
        echo "Ejemplos:"
        echo "  $0 stats"
        echo "  $0 continuous"
        echo "  $0 load"
        ;;
esac