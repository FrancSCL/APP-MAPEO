from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection

tipoplanta_bp = Blueprint('tipoplanta_bp', __name__)

# 🔹 Obtener todos los tipos de planta
@tipoplanta_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_tipos_planta():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre, factor_productivo, id_empresa
            FROM mapeo_dim_tipoplanta
            ORDER BY nombre ASC
        """)
        
        tipos = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(tipos), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener un tipo de planta específico por ID
@tipoplanta_bp.route('/<string:tipo_id>', methods=['GET'])
@jwt_required()
def obtener_tipo_planta(tipo_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre, factor_productivo, id_empresa
            FROM mapeo_dim_tipoplanta
            WHERE id = %s
        """, (tipo_id,))
        
        tipo = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not tipo:
            return jsonify({"error": "Tipo de planta no encontrado"}), 404
        
        return jsonify(tipo), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener tipos de planta por empresa
@tipoplanta_bp.route('/empresa/<int:empresa_id>', methods=['GET'])
@jwt_required()
def obtener_tipos_planta_por_empresa(empresa_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre, factor_productivo, id_empresa
            FROM mapeo_dim_tipoplanta
            WHERE id_empresa = %s
            ORDER BY nombre ASC
        """, (empresa_id,))
        
        tipos = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(tipos), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Buscar tipos de planta por nombre
@tipoplanta_bp.route('/buscar/<string:nombre>', methods=['GET'])
@jwt_required()
def buscar_tipos_planta_por_nombre(nombre):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, nombre, factor_productivo, id_empresa
            FROM mapeo_dim_tipoplanta
            WHERE nombre LIKE %s
            ORDER BY nombre ASC
        """, (f'%{nombre}%',))
        
        tipos = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(tipos), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 