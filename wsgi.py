#!/usr/bin/env python3
"""
WSGI entry point for Gunicorn
"""

from app import create_app

# Crear la instancia de la aplicación Flask
app = create_app()

if __name__ == "__main__":
    app.run() 