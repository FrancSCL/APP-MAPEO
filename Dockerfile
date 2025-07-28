FROM python:3.12-slim

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Crear directorio para Cloud SQL socket y asegurar permisos
RUN mkdir -p /cloudsql && \
    chmod 755 /cloudsql

# Copiar requirements primero para aprovechar cache de Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código
COPY . .

# Crear usuario no-root para seguridad
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app && \
    chown -R app:app /cloudsql && \
    chmod 755 /cloudsql

USER app

# Exponer puerto 8080 (requerido por Cloud Run)
EXPOSE 8080

# Comando para ejecutar la aplicación usando wsgi.py
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "1", "--timeout", "120", "--keep-alive", "5", "wsgi:app"] 