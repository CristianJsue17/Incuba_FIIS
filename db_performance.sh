#!/bin/bash

echo "🗄️ PRUEBAS DE RENDIMIENTO - BASE DE DATOS POSTGRESQL"
echo "================================================="
echo ""

# Crear directorio para logs de DB si no existe
mkdir -p performance_logs

# Función para verificar conexión a la base de datos
check_db_connection() {
    echo "🔌 VERIFICANDO CONEXIÓN A LA BASE DE DATOS"
    echo "=========================================="
    
    if docker exec incuba-fiis-db pg_isready -U cristian -d incuba_fiis_development; then
        echo "✅ Base de datos conectada correctamente"
        echo ""
    else
        echo "❌ Error de conexión a la base de datos"
        echo "💡 Verifica que el contenedor de PostgreSQL esté corriendo"
        exit 1
    fi
}

# Función para obtener información básica de la DB
db_basic_info() {
    echo "📊 INFORMACIÓN BÁSICA DE LA BASE DE DATOS"
    echo "========================================"
    
    echo "🔢 Versión de PostgreSQL:"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "SELECT version();" 2>/dev/null | grep PostgreSQL
    echo ""
    
    echo "📏 Tamaño de la base de datos:"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            pg_database.datname as \"Nombre DB\",
            pg_size_pretty(pg_database_size(pg_database.datname)) as \"Tamaño\"
        FROM pg_database 
        WHERE datname = 'incuba_fiis_development';
    " 2>/dev/null
    echo ""
    
    echo "📋 Tablas principales y sus tamaños:"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            schemaname as \"Schema\",
            tablename as \"Tabla\",
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as \"Tamaño\"
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
        LIMIT 10;
    " 2>/dev/null
    echo ""
}

# Función para verificar conexiones activas
check_active_connections() {
    echo "🔗 CONEXIONES ACTIVAS"
    echo "===================="
    
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            count(*) as \"Conexiones Totales\",
            count(*) FILTER (WHERE state = 'active') as \"Conexiones Activas\",
            count(*) FILTER (WHERE state = 'idle') as \"Conexiones Idle\"
        FROM pg_stat_activity 
        WHERE datname = 'incuba_fiis_development';
    " 2>/dev/null
    echo ""
}

# Función para analizar queries lentas
analyze_slow_queries() {
    echo "🐌 ANÁLISIS DE QUERIES (si pg_stat_statements está habilitado)"
    echo "=========================================================="
    
    # Verificar si pg_stat_statements está disponible
    EXTENSION_CHECK=$(docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -t -c "SELECT count(*) FROM pg_extension WHERE extname = 'pg_stat_statements';" 2>/dev/null)
    
    if [[ "$EXTENSION_CHECK" -gt 0 ]]; then
        echo "✅ pg_stat_statements disponible"
        docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
            SELECT 
                substring(query, 1, 60) as \"Query (primeros 60 chars)\",
                calls as \"Llamadas\",
                round(total_exec_time::numeric, 2) as \"Tiempo Total (ms)\",
                round(mean_exec_time::numeric, 2) as \"Tiempo Promedio (ms)\"
            FROM pg_stat_statements 
            ORDER BY mean_exec_time DESC 
            LIMIT 5;
        " 2>/dev/null
    else
        echo "⚠️ pg_stat_statements no está habilitado"
        echo "💡 Para análisis avanzado, considera habilitarlo en postgresql.conf"
    fi
    echo ""
}

# Función para probar rendimiento de queries básicas
test_basic_queries() {
    echo "⚡ PRUEBA DE RENDIMIENTO DE QUERIES BÁSICAS"
    echo "=========================================="
    
    echo "🕐 Midiendo tiempo de queries comunes..."
    
    # Test 1: SELECT simple
    echo "📝 Test 1: SELECT básico"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        \timing on
        SELECT count(*) FROM pg_tables;
    " 2>/dev/null | grep Time
    
    # Test 2: Query de metadatos
    echo "📝 Test 2: Query de información de esquema"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        \timing on
        SELECT table_name, column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        LIMIT 10;
    " 2>/dev/null | grep Time
    
    echo ""
}

# Función para análisis de índices
analyze_indexes() {
    echo "🔍 ANÁLISIS DE ÍNDICES"
    echo "===================="
    
    echo "📊 Índices existentes:"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            schemaname as \"Schema\",
            tablename as \"Tabla\",
            indexname as \"Índice\",
            indexdef as \"Definición\"
        FROM pg_indexes 
        WHERE schemaname = 'public'
        ORDER BY tablename;
    " 2>/dev/null
    echo ""
    
    echo "📈 Uso de índices (si hay estadísticas):"
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            schemaname as \"Schema\",
            tablename as \"Tabla\",
            indexname as \"Índice\",
            idx_scan as \"Usos del Índice\",
            idx_tup_read as \"Tuplas Leídas\"
        FROM pg_stat_user_indexes 
        ORDER BY idx_scan DESC;
    " 2>/dev/null
    echo ""
}

# Función para estadísticas de tablas
table_statistics() {
    echo "📊 ESTADÍSTICAS DE TABLAS"
    echo "========================"
    
    docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -c "
        SELECT 
            schemaname as \"Schema\",
            tablename as \"Tabla\",
            n_tup_ins as \"Inserciones\",
            n_tup_upd as \"Actualizaciones\",
            n_tup_del as \"Eliminaciones\",
            seq_scan as \"Scans Secuenciales\",
            idx_scan as \"Scans por Índice\"
        FROM pg_stat_user_tables 
        ORDER BY n_tup_ins DESC;
    " 2>/dev/null
    echo ""
}

# Función para prueba de carga en la base de datos
db_load_test() {
    echo "🚀 PRUEBA DE CARGA EN BASE DE DATOS"
    echo "=================================="
    
    echo "⏱️ Ejecutando múltiples queries concurrentes..."
    
    # Crear archivo temporal con queries de prueba
    cat > /tmp/test_queries.sql << EOF
SELECT count(*) FROM pg_tables;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
SELECT * FROM information_schema.columns WHERE table_schema = 'public' LIMIT 5;
EOF
    
    # Ejecutar queries múltiples veces
    for i in {1..10}; do
        docker exec incuba-fiis-db psql -U cristian -d incuba_fiis_development -f /tmp/test_queries.sql > /dev/null 2>&1 &
        if [ $((i % 3)) -eq 0 ]; then
            echo "📊 Ejecutadas $i iteraciones..."
        fi
    done
    
    wait
    echo "✅ Prueba de carga completada"
    echo ""
    
    # Mostrar estadísticas después de la carga
    echo "📈 Estadísticas después de la prueba:"
    check_active_connections
}

# Función para guardar reporte completo
generate_report() {
    echo "📄 GENERANDO REPORTE DE BASE DE DATOS..."
    
    REPORT_FILE="performance_logs/database_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "🗄️ REPORTE DE RENDIMIENTO - BASE DE DATOS POSTGRESQL"
        echo "Fecha: $(date)"
        echo "================================================="
        echo ""
        
        # Ejecutar todas las funciones y guardar salida
        db_basic_info
        check_active_connections
        analyze_indexes
        table_statistics
        test_basic_queries
        
    } > "$REPORT_FILE"
    
    echo "✅ Reporte guardado en: $REPORT_FILE"
}

# Menú principal
case "$1" in
    "info")
        check_db_connection
        db_basic_info
        ;;
    "connections")
        check_db_connection
        check_active_connections
        ;;
    "queries")
        check_db_connection
        analyze_slow_queries
        test_basic_queries
        ;;
    "indexes")
        check_db_connection
        analyze_indexes
        ;;
    "stats")
        check_db_connection
        table_statistics
        ;;
    "load")
        check_db_connection
        db_load_test
        ;;
    "report")
        check_db_connection
        generate_report
        ;;
    "all")
        echo "🎯 EJECUTANDO TODAS LAS PRUEBAS DE BASE DE DATOS"
        echo "=============================================="
        check_db_connection
        db_basic_info
        check_active_connections
        analyze_indexes
        table_statistics
        test_basic_queries
        analyze_slow_queries
        db_load_test
        generate_report
        ;;
    *)
        echo "🗄️ SCRIPT DE PRUEBAS DE BASE DE DATOS - INCUBAUNAS"
        echo "=============================================="
        echo ""
        echo "Uso: $0 [opción]"
        echo ""
        echo "Opciones disponibles:"
        echo "  info        - Información básica de la DB"
        echo "  connections - Verificar conexiones activas"
        echo "  queries     - Análisis de queries y rendimiento"
        echo "  indexes     - Análisis de índices"
        echo "  stats       - Estadísticas de tablas"
        echo "  load        - Prueba de carga en DB"
        echo "  report      - Generar reporte completo"
        echo "  all         - Ejecutar todas las pruebas"
        echo ""
        echo "Ejemplos:"
        echo "  $0 info"
        echo "  $0 queries"
        echo "  $0 all"
        ;;
esac