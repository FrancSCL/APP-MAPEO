from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from utils.db import get_db_connection

especies_bp = Blueprint('especies_bp', __name__)

# Obtener todas las especies
@especies_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_especies():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, nombre, caja_equivalente
            FROM general_dim_especie
            ORDER BY nombre ASC
        """)
        especies = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(especies), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Obtener especie por ID
@especies_bp.route('/<int:especie_id>', methods=['GET'])
@jwt_required()
def obtener_especie(especie_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, nombre, caja_equivalente
            FROM general_dim_especie
            WHERE id = %s
        """, (especie_id,))
        especie = cursor.fetchone()
        cursor.close()
        conn.close()
        if not especie:
            return jsonify({"error": "Especie no encontrada"}), 404
        return jsonify(especie), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Crear especie
@especies_bp.route('/', methods=['POST'])
@jwt_required()
def crear_especie():
    try:
        data = request.json
        if 'nombre' not in data or 'caja_equivalente' not in data:
            return jsonify({"error": "Faltan campos requeridos"}), 400
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            INSERT INTO general_dim_especie (nombre, caja_equivalente)
            VALUES (%s, %s)
        """, (data['nombre'], data['caja_equivalente']))
        especie_id = cursor.lastrowid
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Especie creada exitosamente", "id": especie_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Actualizar especie
@especies_bp.route('/<int:especie_id>', methods=['PUT'])
@jwt_required()
def actualizar_especie(especie_id):
    try:
        data = request.json
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM general_dim_especie WHERE id = %s", (especie_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Especie no encontrada"}), 404
        campos = []
        valores = []
        if 'nombre' in data:
            campos.append("nombre = %s")
            valores.append(data['nombre'])
        if 'caja_equivalente' in data:
            campos.append("caja_equivalente = %s")
            valores.append(data['caja_equivalente'])
        if not campos:
            cursor.close()
            conn.close()
            return jsonify({"error": "No hay campos para actualizar"}), 400
        valores.append(especie_id)
        query = f"UPDATE general_dim_especie SET {', '.join(campos)} WHERE id = %s"
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Especie actualizada exitosamente", "id": especie_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Eliminar especie
@especies_bp.route('/<int:especie_id>', methods=['DELETE'])
@jwt_required()
def eliminar_especie(especie_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT id FROM general_dim_especie WHERE id = %s", (especie_id,))
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Especie no encontrada"}), 404
        cursor.execute("DELETE FROM general_dim_especie WHERE id = %s", (especie_id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Especie eliminada exitosamente", "id": especie_id}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 