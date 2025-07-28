from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection
from datetime import datetime, date
import uuid
import logging
import traceback

plantas_bp = Blueprint('plantas_bp', __name__)

# 🔹 Obtener todas las plantas
@plantas_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_plantas():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_hilera, planta, ubicacion, fecha_creacion
            FROM general_dim_planta
            ORDER BY planta ASC
        """)
        
        plantas = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(plantas), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener una planta específica por ID
@plantas_bp.route('/<string:planta_id>', methods=['GET'])
@jwt_required()
def obtener_planta(planta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_hilera, planta, ubicacion, fecha_creacion
            FROM general_dim_planta
            WHERE id = %s
        """, (planta_id,))
        
        planta = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not planta:
            return jsonify({"error": "Planta no encontrada"}), 404
        
        return jsonify(planta), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Crear una nueva planta
@plantas_bp.route('/', methods=['POST'])
@jwt_required()
def crear_planta():
    try:
        # Logging para debug
        import logging
        logger = logging.getLogger(__name__)
        logger.info("🌱 Iniciando creación de planta...")
        
        data = request.json
        logger.info(f"📥 Datos recibidos: {data}")
        
        # Validar campos requeridos
        campos_requeridos = ['id_hilera', 'planta', 'ubicacion']
        for campo in campos_requeridos:
            if campo not in data:
                logger.error(f"❌ Campo requerido faltante: {campo}")
                return jsonify({"error": f"Campo requerido: {campo}"}), 400
        
        logger.info("✅ Campos requeridos validados")
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que la hilera existe
        logger.info(f"🔍 Verificando hilera {data['id_hilera']}...")
        cursor.execute("""
            SELECT id FROM general_dim_hilera WHERE id = %s
        """, (data['id_hilera'],))
        
        if not cursor.fetchone():
            logger.error(f"❌ Hilera {data['id_hilera']} no encontrada")
            cursor.close()
            conn.close()
            return jsonify({"error": "Hilera no encontrada"}), 404
        
        logger.info("✅ Hilera encontrada")
        
        # Verificar que no existe una planta con el mismo número en la misma hilera
        logger.info(f"🔍 Verificando duplicado planta {data['planta']} en hilera {data['id_hilera']}...")
        cursor.execute("""
            SELECT id FROM general_dim_planta 
            WHERE id_hilera = %s AND planta = %s
        """, (data['id_hilera'], data['planta']))
        
        if cursor.fetchone():
            logger.error(f"❌ Ya existe planta {data['planta']} en hilera {data['id_hilera']}")
            cursor.close()
            conn.close()
            return jsonify({"error": "Ya existe una planta con ese número en esta hilera"}), 400
        
        logger.info("✅ No hay duplicados")
        
        # Insertar la nueva planta (sin especificar id, se genera automáticamente)
        logger.info("💾 Insertando nueva planta...")
        cursor.execute("""
            INSERT INTO general_dim_planta 
            (id_hilera, planta, ubicacion, fecha_creacion)
            VALUES (%s, %s, %s, %s)
        """, (
            data['id_hilera'],
            data['planta'],
            data['ubicacion'],
            date.today()
        ))
        
        # Obtener el ID de la planta recién creada
        planta_id = cursor.lastrowid
        logger.info(f"✅ Planta creada con ID: {planta_id}")
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Planta creada exitosamente",
            "id": planta_id
        }), 201
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"❌ Error en crear_planta: {str(e)}")
        logger.error(f"📋 Traceback: {traceback.format_exc()}")
        return jsonify({"error": str(e)}), 500

# 🔹 Actualizar una planta existente
@plantas_bp.route('/<string:planta_id>', methods=['PUT'])
@jwt_required()
def actualizar_planta(planta_id):
    try:
        data = request.json
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que la planta existe
        cursor.execute("""
            SELECT id FROM general_dim_planta WHERE id = %s
        """, (planta_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Planta no encontrada"}), 404
        
        # Construir la consulta de actualización dinámicamente
        campos_actualizables = ['id_hilera', 'planta', 'ubicacion']
        campos_a_actualizar = []
        valores = []
        
        for campo in campos_actualizables:
            if campo in data:
                campos_a_actualizar.append(f"{campo} = %s")
                valores.append(data[campo])
        
        if not campos_a_actualizar:
            cursor.close()
            conn.close()
            return jsonify({"error": "No hay campos para actualizar"}), 400
        
        # Agregar el ID al final de los valores
        valores.append(planta_id)
        
        # Ejecutar la actualización
        query = f"""
            UPDATE general_dim_planta 
            SET {', '.join(campos_a_actualizar)}
            WHERE id = %s
        """
        
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Planta actualizada exitosamente",
            "id": planta_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Eliminar una planta
@plantas_bp.route('/<string:planta_id>', methods=['DELETE'])
@jwt_required()
def eliminar_planta(planta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que la planta existe
        cursor.execute("""
            SELECT id FROM general_dim_planta WHERE id = %s
        """, (planta_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Planta no encontrada"}), 404
        
        # Eliminar la planta
        cursor.execute("""
            DELETE FROM general_dim_planta WHERE id = %s
        """, (planta_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Planta eliminada exitosamente",
            "id": planta_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener plantas por hilera
@plantas_bp.route('/hilera/<int:hilera_id>', methods=['GET'])
@jwt_required()
def obtener_plantas_por_hilera(hilera_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_hilera, planta, ubicacion, fecha_creacion
            FROM general_dim_planta
            WHERE id_hilera = %s
            ORDER BY planta ASC
        """, (hilera_id,))
        
        plantas = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(plantas), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Buscar plantas por ubicación
@plantas_bp.route('/ubicacion/<string:ubicacion>', methods=['GET'])
@jwt_required()
def buscar_plantas_por_ubicacion(ubicacion):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_hilera, planta, ubicacion, fecha_creacion
            FROM general_dim_planta
            WHERE ubicacion LIKE %s
            ORDER BY planta ASC
        """, (f'%{ubicacion}%',))
        
        plantas = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(plantas), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener plantas por número de planta
@plantas_bp.route('/numero/<int:numero_planta>', methods=['GET'])
@jwt_required()
def obtener_plantas_por_numero(numero_planta):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_hilera, planta, ubicacion, fecha_creacion
            FROM general_dim_planta
            WHERE planta = %s
            ORDER BY planta ASC
        """, (numero_planta,))
        
        plantas = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(plantas), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 