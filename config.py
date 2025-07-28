import os
from dotenv import load_dotenv

load_dotenv()  # Carga las variables del archivo .env

class Config:
    DEBUG = os.getenv("DEBUG", "False") == "True"
    
    # Configuración local (desarrollo)
    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_NAME = os.getenv("DB_NAME", "mapeo_db")
    DB_PORT = int(os.getenv("DB_PORT", 3306))
    
    # Configuración Cloud SQL (producción) - ACTIVADA POR DEFECTO
    CLOUD_SQL_HOST = os.getenv("CLOUD_SQL_HOST", "34.41.120.220")
    CLOUD_SQL_USER = os.getenv("CLOUD_SQL_USER", "UserApp")
    CLOUD_SQL_PASSWORD = os.getenv("CLOUD_SQL_PASSWORD", "&8y7c()tu9t/+,6`")
    CLOUD_SQL_DB = os.getenv("CLOUD_SQL_DB", "lahornilla_base_normalizada")
    CLOUD_SQL_PORT = int(os.getenv("CLOUD_SQL_PORT", 3306))
    
    # Configuración del proyecto
    GOOGLE_CLOUD_PROJECT = os.getenv("GOOGLE_CLOUD_PROJECT", "gestion-la-hornilla")
    CLOUD_SQL_CONNECTION_NAME = os.getenv("CLOUD_SQL_CONNECTION_NAME", "gestion-la-hornilla:us-central1:gestion-la-hornilla")
    
    # JWT y seguridad
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'Inicio01*')
    SECRET_KEY = os.getenv('SECRET_KEY', 'Inicio01*')
    
    # Configuración de CORS
    ALLOWED_ORIGINS = os.getenv('ALLOWED_ORIGINS', '')
    
    # Detectar si estamos en Cloud Run
    @classmethod
    def is_cloud_run(cls):
        return os.getenv('K_SERVICE') is not None
