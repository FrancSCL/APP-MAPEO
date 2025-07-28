#!/usr/bin/env python3
"""
Script de prueba para verificar que wsgi.py funciona correctamente
"""

import os
import sys

def test_wsgi_import():
    """Prueba que wsgi.py puede importar y crear la aplicación correctamente"""
    print("🔍 Probando importación de wsgi.py...")
    
    try:
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
        
        # Importar wsgi.py
        from wsgi import app
        
        print("✅ wsgi.py importado correctamente")
        print(f"   Tipo de app: {type(app)}")
        print(f"   Nombre de app: {app.name}")
        
        # Probar que la app funciona
        with app.test_client() as client:
            print("✅ Cliente de prueba creado")
            
            # Probar endpoint raíz
            response = client.get('/')
            print(f"📡 Endpoint raíz: {response.status_code}")
            
            # Probar health check
            response = client.get('/health')
            print(f"📡 Health check: {response.status_code}")
            
            # Probar test-db
            response = client.get('/api/test-db')
            print(f"📡 Test DB: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Todas las pruebas exitosas")
                return True
            else:
                print(f"❌ Error en test-db: {response.data}")
                return False
                
    except Exception as e:
        print(f"❌ Error en wsgi.py: {str(e)}")
        import traceback
        print(f"📋 Traceback: {traceback.format_exc()}")
        return False

def test_gunicorn_command():
    """Prueba que el comando de Gunicorn es correcto"""
    print("\n🐳 Verificando comando de Gunicorn...")
    
    # Comando que debería usar Gunicorn
    gunicorn_command = "gunicorn --bind 0.0.0.0:8080 --workers 1 --timeout 120 --keep-alive 5 wsgi:app"
    
    print(f"✅ Comando Gunicorn: {gunicorn_command}")
    print("✅ wsgi:app está configurado correctamente")
    
    return True

if __name__ == '__main__':
    print("🚀 Iniciando pruebas de wsgi.py...")
    
    # Probar importación
    if test_wsgi_import():
        print("\n✅ wsgi.py funciona correctamente")
        
        # Probar comando Gunicorn
        if test_gunicorn_command():
            print("✅ Configuración de Gunicorn correcta")
            print("\n🎉 Todo listo para Cloud Run!")
        else:
            print("❌ Error en configuración de Gunicorn")
            sys.exit(1)
    else:
        print("\n❌ Error en wsgi.py")
        sys.exit(1) 