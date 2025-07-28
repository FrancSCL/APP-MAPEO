from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from utils.db import get_db_connection

variedades_bp = Blueprint('variedades_bp', __name__)

# Obtener todas las variedades
@variedades_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_variedades():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, nombre, id_especie, id_forma, id_color
            FROM general_dim_variedad
            ORDER BY nombre ASC
        """)
        variedades = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(variedades), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Obtener variedad por ID
@variedades_bp.route('/<int:variedad_id>', methods=['GET'])
@jwt_required()
def obtener_variedad(variedad_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, nombre, id_especie, id_forma, id_color
            FROM general_dim_variedad
            WHERE id = %s
        """, (variedad_id,))
        variedad = cursor.fetchone()
        cursor.close()
        conn.close()
        if not variedad:
            return jsonify({"error": "Variedad no encontrada"}), 404
        return jsonify(variedad), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Crear variedad
@variedades_bp.route('/', methods=['POST'])
@jwt_required()
def crear_variedad():
    try:
        data = request.json
        if 'nombre' not in data or 'id_especie' not in data or 'id_forma' not in data or 'id_color' not in data:
            return jsonify({"error": "Faltan campos requeridos"}), 400
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            INSERT INTO general_dim_variedad (nombre, id_especie, id_forma, id_color)
            VALUES (%s, %s, %s, %s)
        """, (data['nombre'], data['id_especie'], data['id_forma'], data['id_color']))
        variedad_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Variedad creada exitosamente", "id": variedad_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Actualizar variedad
@variedades_bp.route('/<int:variedad_id>', methods=['PUT'])
@jwt_required()
def actualizar_variedad(variedad_id):
    try:
        data = request.json
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM general_dim_variedad WHERE id = %s", (variedad_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Variedad no encontrada"}), 404
        campos = []
        valores = []
        if 'nombre' in data:
            campos.append("nombre = %s")
            valores.append(data['nombre'])
        if 'id_especie' in data:
            campos.append("id_especie = %s")
            valores.append(data['id_especie'])
        if 'id_forma' in data:
            campos.append("id_forma = %s")
            valores.append(data['id_forma'])
        if 'id_color' in data:
            campos.append("id_color = %s")
            valores.append(data['id_color'])
        if not campos:
            cursor.close()
            conn.close()
            return jsonify({"error": "No hay campos para actualizar"}), 400
        valores.append(variedad_id)
        query = f"UPDATE general_dim_variedad SET {', '.join(campos)} WHERE id = %s"
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Variedad actualizada exitosamente", "id": variedad_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Eliminar variedad
@variedades_bp.route('/<int:variedad_id>', methods=['DELETE'])
@jwt_required()
def eliminar_variedad(variedad_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM general_dim_variedad WHERE id = %s", (variedad_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Variedad no encontrada"}), 404
        cursor.execute("DELETE FROM general_dim_variedad WHERE id = %s", (variedad_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Variedad eliminada exitosamente", "id": variedad_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 