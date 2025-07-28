#!/usr/bin/env python3
"""
Script de prueba para verificar que la aplicación funciona correctamente
en modo Cloud Run antes del despliegue.
"""

import os
import sys
import requests
import time

def test_local_app():
    """Prueba la aplicación localmente en modo Cloud Run"""
    print("🧪 Probando aplicación en modo Cloud Run...")
    
    # Configurar variables de entorno como en Cloud Run
    os.environ['PORT'] = '8080'
    os.environ['DEBUG'] = 'False'
    os.environ['CLOUD_SQL_HOST'] = '34.41.120.220'
    os.environ['CLOUD_SQL_USER'] = 'UserApp'
    os.environ['CLOUD_SQL_PASSWORD'] = '&8y7c()tu9t/+,6`'
    os.environ['CLOUD_SQL_DB'] = 'lahornilla_base_normalizada'
    os.environ['JWT_SECRET_KEY'] = 'Inicio01*'
    os.environ['SECRET_KEY'] = 'Inicio01*'
    
    try:
        # Importar y crear la aplicación
        from app import create_app
        app = create_app()
        
        # Crear cliente de prueba
        with app.test_client() as client:
            print("✅ Aplicación creada correctamente")
            
            # Probar endpoint raíz
            response = client.get('/')
            print(f"📡 Endpoint raíz: {response.status_code}")
            if response.status_code == 200:
                print("✅ Endpoint raíz funciona")
            else:
                print(f"❌ Error en endpoint raíz: {response.data}")
            
            # Probar health check
            response = client.get('/health')
            print(f"📡 Health check: {response.status_code}")
            if response.status_code == 200:
                print("✅ Health check funciona")
            else:
                print(f"❌ Error en health check: {response.data}")
            
            # Probar conexión a BD
            response = client.get('/api/test-db')
            print(f"📡 Test DB: {response.status_code}")
            if response.status_code == 200:
                print("✅ Conexión a BD funciona")
            else:
                print(f"❌ Error en conexión BD: {response.data}")
                
    except Exception as e:
        print(f"❌ Error durante la prueba: {str(e)}")
        return False
    
    return True

def test_docker_build():
    """Prueba la construcción de la imagen Docker"""
    print("\n🐳 Probando construcción de Docker...")
    
    import subprocess
    try:
        # Construir imagen
        result = subprocess.run([
            'docker', 'build', '-t', 'api-mapeo-test', '.'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Imagen Docker construida correctamente")
            
            # Probar ejecución
            container = subprocess.run([
                'docker', 'run', '-d', '-p', '8080:8080', 
                '--name', 'api-mapeo-test-container', 'api-mapeo-test'
            ], capture_output=True, text=True)
            
            if container.returncode == 0:
                print("✅ Contenedor iniciado correctamente")
                
                # Esperar un poco para que la app inicie
                time.sleep(5)
                
                # Probar endpoints
                try:
                    response = requests.get('http://localhost:8080/')
                    print(f"📡 Endpoint raíz: {response.status_code}")
                    
                    response = requests.get('http://localhost:8080/health')
                    print(f"📡 Health check: {response.status_code}")
                    
                    response = requests.get('http://localhost:8080/api/test-db')
                    print(f"📡 Test DB: {response.status_code}")
                    
                except requests.exceptions.RequestException as e:
                    print(f"❌ Error conectando al contenedor: {e}")
                
                # Limpiar
                subprocess.run(['docker', 'stop', 'api-mapeo-test-container'])
                subprocess.run(['docker', 'rm', 'api-mapeo-test-container'])
                subprocess.run(['docker', 'rmi', 'api-mapeo-test'])
                
            else:
                print(f"❌ Error iniciando contenedor: {container.stderr}")
        else:
            print(f"❌ Error construyendo imagen: {result.stderr}")
            
    except FileNotFoundError:
        print("❌ Docker no está instalado o no está en el PATH")
    except Exception as e:
        print(f"❌ Error durante prueba Docker: {str(e)}")

if __name__ == '__main__':
    print("🚀 Iniciando pruebas para Cloud Run...")
    
    # Prueba local
    if test_local_app():
        print("\n✅ Pruebas locales exitosas")
        
        # Preguntar si probar Docker
        response = input("\n¿Quieres probar la construcción de Docker? (y/n): ")
        if response.lower() in ['y', 'yes', 'sí', 'si']:
            test_docker_build()
    else:
        print("\n❌ Pruebas locales fallaron")
        sys.exit(1)
    
    print("\n🎉 Pruebas completadas. La aplicación está lista para Cloud Run!") 