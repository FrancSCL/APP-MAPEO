from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection

estadocatastro_bp = Blueprint('estadocatastro_bp', __name__)

# 🔹 Obtener todos los estados de catastro
@estadocatastro_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_estados_catastro():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre
            FROM mapeo_dim_estadocatastro
            ORDER BY nombre ASC
        """)
        
        estados = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(estados), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener un estado de catastro específico por ID
@estadocatastro_bp.route('/<int:estado_id>', methods=['GET'])
@jwt_required()
def obtener_estado_catastro(estado_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre
            FROM mapeo_dim_estadocatastro
            WHERE id = %s
        """, (estado_id,))
        
        estado = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not estado:
            return jsonify({"error": "Estado de catastro no encontrado"}), 404
        
        return jsonify(estado), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Buscar estados de catastro por nombre
@estadocatastro_bp.route('/buscar/<string:nombre>', methods=['GET'])
@jwt_required()
def buscar_estados_catastro_por_nombre(nombre):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre
            FROM mapeo_dim_estadocatastro
            WHERE nombre LIKE %s
            ORDER BY nombre ASC
        """, (f'%{nombre}%',))
        
        estados = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(estados), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 