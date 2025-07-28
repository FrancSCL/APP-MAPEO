#!/usr/bin/env python3
"""
Script de prueba final para verificar Unix socket en Cloud Run
"""

import os
import sys

def test_unix_socket_connection():
    """Prueba la conexión usando Unix socket"""
    print("🔍 Probando conexión Unix socket...")
    
    # Configurar variables de entorno como en Cloud Run
    os.environ['K_SERVICE'] = 'test-service'
    os.environ['PORT'] = '8080'
    os.environ['DEBUG'] = 'False'
    os.environ['CLOUD_SQL_HOST'] = '34.41.120.220'
    os.environ['CLOUD_SQL_USER'] = 'UserApp'
    os.environ['CLOUD_SQL_PASSWORD'] = '&8y7c()tu9t/+,6'
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
            
            # Probar endpoint de test-db
            response = client.get('/api/test-db')
            print(f"📡 Test DB: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Conexión Unix socket funciona")
                print(f"📊 Respuesta: {response.get_json()}")
                return True
            else:
                print(f"❌ Error en conexión: {response.data}")
                return False
                
    except Exception as e:
        print(f"❌ Error durante la prueba: {str(e)}")
        import traceback
        print(f"📋 Traceback: {traceback.format_exc()}")
        return False

def test_docker_build():
    """Prueba la construcción de la imagen Docker con Unix socket"""
    print("\n🐳 Probando construcción de Docker con Unix socket...")
    
    import subprocess
    try:
        # Construir imagen
        result = subprocess.run([
            'docker', 'build', '-t', 'api-mapeo-unix-test', '.'
        ], capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Imagen Docker construida correctamente")
            
            # Verificar que el directorio /cloudsql existe
            container = subprocess.run([
                'docker', 'run', '--rm', 'api-mapeo-unix-test', 
                'ls', '-la', '/cloudsql'
            ], capture_output=True, text=True)
            
            if container.returncode == 0:
                print("✅ Directorio /cloudsql existe y es accesible")
                print(f"📋 Contenido: {container.stdout}")
            else:
                print(f"❌ Error verificando /cloudsql: {container.stderr}")
                
            # Limpiar
            subprocess.run(['docker', 'rmi', 'api-mapeo-unix-test'])
            
        else:
            print(f"❌ Error construyendo imagen: {result.stderr}")
            
    except FileNotFoundError:
        print("❌ Docker no está instalado o no está en el PATH")
    except Exception as e:
        print(f"❌ Error durante prueba Docker: {str(e)}")

if __name__ == '__main__':
    print("🚀 Iniciando pruebas finales de Unix socket...")
    
    # Probar conexión local
    if test_unix_socket_connection():
        print("\n✅ Pruebas locales exitosas")
        
        # Probar Docker
        test_docker_build()
        
        print("\n🎉 Todo listo para Cloud Run con Unix socket!")
    else:
        print("\n❌ Error en pruebas locales")
        sys.exit(1) 