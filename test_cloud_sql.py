#!/usr/bin/env python3
"""
Script de prueba para verificar conexión a Cloud SQL
"""

import os
import sys
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

def test_cloud_sql_connection():
    """Prueba la conexión a Cloud SQL"""
    try:
        from utils.db import get_db_connection
        
        print("🔌 Probando conexión a Cloud SQL...")
        
        # Intentar conectar
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Probar consulta simple
        cursor.execute("SELECT VERSION() as version, DATABASE() as database_name")
        result = cursor.fetchone()
        
        print("✅ Conexión exitosa!")
        print(f"   MySQL Version: {result['version']}")
        print(f"   Database: {result['database_name']}")
        
        # Probar consulta a una tabla existente
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        
        print(f"   Tablas disponibles: {len(tables)}")
        for table in tables[:5]:  # Mostrar solo las primeras 5
            print(f"   - {list(table.values())[0]}")
        
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error de conexión: {str(e)}")
        print("\n🔧 Solución de problemas:")
        print("1. Verifica que la IP esté autorizada en Cloud SQL")
        print("2. Verifica las credenciales en .env")
        print("3. Verifica que la instancia esté activa")
        return False

def test_local_connection():
    """Prueba la conexión local"""
    try:
        from utils.db import get_db_connection
        
        print("\n🔌 Probando conexión local...")
        
        # Forzar conexión local
        os.environ['K_SERVICE'] = ''  # Simular entorno local
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("SELECT VERSION() as version")
        result = cursor.fetchone()
        
        print("✅ Conexión local exitosa!")
        print(f"   MySQL Version: {result['version']}")
        
        cursor.close()
        conn.close()
        
        return True
        
    except Exception as e:
        print(f"❌ Error de conexión local: {str(e)}")
        return False

if __name__ == "__main__":
    print("🚀 Iniciando pruebas de conexión...\n")
    
    # Probar conexión local
    local_success = test_local_connection()
    
    # Probar conexión Cloud SQL
    cloud_success = test_cloud_sql_connection()
    
    print("\n" + "="*50)
    if local_success and cloud_success:
        print("🎉 Todas las conexiones funcionan correctamente!")
    elif local_success:
        print("⚠️  Solo la conexión local funciona")
    elif cloud_success:
        print("⚠️  Solo la conexión Cloud SQL funciona")
    else:
        print("❌ Ninguna conexión funciona")
    
    print("="*50) 