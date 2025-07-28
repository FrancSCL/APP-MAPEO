from flask import Flask, Blueprint, jsonify
from flask_jwt_extended import JWTManager
from config import Config
from flask_cors import CORS
from datetime import timedelta
import logging
import os
import traceback
import sys

# Configurar logging más detallado
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Crear la aplicación Flask
def create_app():
    app = Flask(__name__)
    
    # Configurar CORS para producción y desarrollo
    origins = [
        "http://localhost:*", 
        "http://127.0.0.1:*",
        "https://localhost:*",
        "https://127.0.0.1:*"
    ]
    
    # Agregar dominios de producción si están definidos
    if os.getenv('ALLOWED_ORIGINS'):
        origins.extend(os.getenv('ALLOWED_ORIGINS').split(','))
    
    CORS(app, resources={
        r"/*": {
            "origins": origins,
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
            "supports_credentials": True,
            "expose_headers": ["Content-Type", "Authorization"],
            "max_age": 3600
        }
    })

    # Configurar JWT
    app.config['JWT_SECRET_KEY'] = Config.JWT_SECRET_KEY
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=10)
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=7)
    app.config['JWT_TOKEN_LOCATION'] = ['headers']
    app.config['JWT_HEADER_NAME'] = 'Authorization'
    app.config['JWT_HEADER_TYPE'] = 'Bearer'

    jwt = JWTManager(app)

    # Manejo global de errores
    @app.errorhandler(Exception)
    def handle_exception(e):
        """Maneja todas las excepciones no capturadas"""
        logger.error(f"❌ Error no capturado: {str(e)}")
        logger.error(f"📋 Traceback: {traceback.format_exc()}")
        
        return jsonify({
            "error": "Internal Server Error",
            "message": str(e),
            "type": type(e).__name__
        }), 500

    @app.errorhandler(500)
    def handle_500(e):
        """Maneja errores 500 específicamente"""
        logger.error(f"❌ Error 500: {str(e)}")
        logger.error(f"📋 Traceback: {traceback.format_exc()}")
        
        return jsonify({
            "error": "Internal Server Error",
            "message": "Ha ocurrido un error interno del servidor"
        }), 500

    # Endpoint raíz para verificar que la API está funcionando
    @app.route('/', methods=['GET'])
    def root():
        try:
            logger.info("🌐 Endpoint raíz accedido")
            return jsonify({
                "message": "API de Mapeo Agrícola",
                "status": "running",
                "version": "1.0.0",
                "environment": "Cloud Run" if os.getenv('K_SERVICE') else "Local",
                "endpoints": {
                    "auth": "/api/auth",
                    "usuarios": "/api/usuarios",
                    "registros": "/api/registros",
                    "registromapeo": "/api/registromapeo",
                    "cuarteles": "/api/cuarteles",
                    "plantas": "/api/plantas",
                    "test_db": "/api/test-db"
                }
            }), 200
        except Exception as e:
            logger.error(f"❌ Error en endpoint raíz: {str(e)}")
            raise

    # Endpoint de health check para Cloud Run
    @app.route('/health', methods=['GET'])
    def health_check():
        try:
            logger.info("🏥 Health check accedido")
            return jsonify({"status": "healthy"}), 200
        except Exception as e:
            logger.error(f"❌ Error en health check: {str(e)}")
            raise

    # Registrar los blueprints
    try:
        from blueprints.auth import auth_bp
        from blueprints.opciones import opciones_bp
        from blueprints.usuarios import usuarios_bp 
        from blueprints.registros import registros_bp
        from blueprints.registromapeo import registromapeo_bp
        from blueprints.cuarteles import cuarteles_bp
        from blueprints.estadocatastro import estadocatastro_bp
        from blueprints.plantas import plantas_bp
        from blueprints.tipoplanta import tipoplanta_bp
        from blueprints.hileras import hileras_bp
        from blueprints.especies import especies_bp
        from blueprints.variedades import variedades_bp
        
        logger.info("📦 Importando blueprints...")
    
        # Registrar blueprints
        app.register_blueprint(opciones_bp, url_prefix="/api/opciones")
        app.register_blueprint(auth_bp, url_prefix="/api/auth")
        app.register_blueprint(usuarios_bp, url_prefix="/api/usuarios")
        app.register_blueprint(registros_bp, url_prefix="/api/registros")
        app.register_blueprint(registromapeo_bp, url_prefix="/api/registromapeo")
        app.register_blueprint(cuarteles_bp, url_prefix="/api/cuarteles")
        app.register_blueprint(estadocatastro_bp, url_prefix="/api/estadocatastro")
        app.register_blueprint(plantas_bp, url_prefix="/api/plantas")
        app.register_blueprint(tipoplanta_bp, url_prefix="/api/tipoplanta")
        app.register_blueprint(hileras_bp, url_prefix="/api/hileras")
        app.register_blueprint(especies_bp, url_prefix="/api/especies")
        app.register_blueprint(variedades_bp, url_prefix="/api/variedades")
        
        logger.info("✅ Blueprints registrados correctamente")
        
    except Exception as e:
        logger.error(f"❌ Error registrando blueprints: {str(e)}")
        logger.error(f"📋 Traceback: {traceback.format_exc()}")
        raise
    
    # Crear un nuevo blueprint para las rutas raíz
    root_bp = Blueprint('root_bp', __name__)
    
    # Importar y registrar las rutas raíz
    try:
        from blueprints.opciones import obtener_sucursales
        root_bp.add_url_rule('/sucursales/', 'obtener_sucursales', obtener_sucursales, methods=['GET', 'OPTIONS'])
        logger.info("✅ Rutas raíz registradas")
    except Exception as e:
        logger.error(f"❌ Error registrando rutas raíz: {str(e)}")
    
    # Registrar el blueprint raíz
    app.register_blueprint(root_bp, url_prefix="/api")

    # Endpoint de prueba de conexión a BD
    @app.route('/api/test-db', methods=['GET'])
    def test_database():
        """Endpoint para probar la conexión a la base de datos"""
        try:
            logger.info("🔍 Probando conexión a base de datos...")
            from utils.db import get_db_connection
            conn = get_db_connection()
            cursor = conn.cursor(dictionary=True)
            
            # Probar consulta simple
            cursor.execute("SELECT VERSION() as version, DATABASE() as database_name")
            result = cursor.fetchone()
            
            # Obtener información de tablas
            cursor.execute("SHOW TABLES")
            tables = cursor.fetchall()
            table_names = [list(table.values())[0] for table in tables]
            
            cursor.close()
            conn.close()
            
            logger.info("✅ Conexión a BD exitosa")
            return {
                "status": "success",
                "message": "Conexión exitosa a la base de datos",
                "mysql_version": result['version'],
                "database": result['database_name'],
                "tables_count": len(table_names),
                "tables": table_names[:10]  # Solo las primeras 10
            }, 200
            
        except Exception as e:
            logger.error(f"❌ Error en test-db: {str(e)}")
            logger.error(f"📋 Traceback: {traceback.format_exc()}")
            return {
                "status": "error",
                "message": f"Error de conexión: {str(e)}",
                "type": type(e).__name__
            }, 500

    logger.info("🚀 Aplicación Flask creada correctamente")
    return app

# Crear una única instancia de la aplicación
app = create_app()

if __name__ == '__main__':
    # Usar puerto 8080 para Cloud Run
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"🌐 Iniciando aplicación en puerto {port}")
    app.run(debug=False, host='0.0.0.0', port=port)

