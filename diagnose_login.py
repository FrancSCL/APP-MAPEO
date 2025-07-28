#!/usr/bin/env python3
"""
Script de diagnóstico para el endpoint de login
"""

import os
import sys
import json
import requests

def test_login_endpoint():
    """Prueba el endpoint de login específicamente"""
    print("🔍 Diagnóstico del endpoint de login...")
    
    # URL del servicio
    base_url = "https://apimapeo-927498545444.us-central1.run.app"
    
    # Datos de prueba (ajusta según tus datos reales)
    test_data = {
        "usuario": "admin",  # Cambia por un usuario real
        "clave": "admin123"   # Cambia por una clave real
    }
    
    try:
        # Probar endpoint raíz primero
        print("📡 Probando endpoint raíz...")
        response = requests.get(f"{base_url}/")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   ✅ Endpoint raíz funciona")
        else:
            print(f"   ❌ Error en endpoint raíz: {response.text}")
        
        # Probar health check
        print("📡 Probando health check...")
        response = requests.get(f"{base_url}/health")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   ✅ Health check funciona")
        else:
            print(f"   ❌ Error en health check: {response.text}")
        
        # Probar test-db
        print("📡 Probando conexión a BD...")
        response = requests.get(f"{base_url}/api/test-db")
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   ✅ Conexión a BD funciona")
            print(f"   📊 Respuesta: {response.json()}")
        else:
            print(f"   ❌ Error en conexión BD: {response.text}")
        
        # Probar login
        print("📡 Probando endpoint de login...")
        response = requests.post(
            f"{base_url}/api/auth/login",
            headers={"Content-Type": "application/json"},
            json=test_data
        )
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            print("   ✅ Login exitoso")
            print(f"   📊 Respuesta: {response.json()}")
        elif response.status_code == 401:
            print("   ⚠️  Credenciales incorrectas (esperado si no son válidas)")
            print(f"   📊 Respuesta: {response.json()}")
        elif response.status_code == 500:
            print("   ❌ Error interno del servidor")
            print(f"   📊 Respuesta: {response.text}")
        else:
            print(f"   ❌ Error inesperado: {response.status_code}")
            print(f"   📊 Respuesta: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Error de conexión: {e}")
    except Exception as e:
        print(f"❌ Error general: {e}")

def test_local_app():
    """Prueba la aplicación localmente"""
    print("\n🧪 Probando aplicación localmente...")
    
    # Configurar variables de entorno
    os.environ['K_SERVICE'] = 'test-service'
    os.environ['PORT'] = '8080'
    os.environ['DEBUG'] = 'False'
    
    try:
        from app import create_app
        app = create_app()
        
        with app.test_client() as client:
            print("✅ Aplicación creada correctamente")
            
            # Probar login localmente
            test_data = {
                "usuario": "admin",
                "clave": "admin123"
            }
            
            response = client.post(
                '/api/auth/login',
                headers={"Content-Type": "application/json"},
                json=test_data
            )
            
            print(f"📡 Login local: {response.status_code}")
            if response.status_code in [200, 401]:
                print("✅ Login funciona localmente")
                print(f"📊 Respuesta: {response.get_json()}")
            else:
                print(f"❌ Error en login local: {response.data}")
                
    except Exception as e:
        print(f"❌ Error en prueba local: {str(e)}")
        import traceback
        print(f"📋 Traceback: {traceback.format_exc()}")

if __name__ == '__main__':
    print("🚀 Iniciando diagnóstico del login...")
    
    # Probar endpoint remoto
    test_login_endpoint()
    
    # Probar localmente
    test_local_app()
    
    print("\n🎉 Diagnóstico completado!") 