from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection
from datetime import datetime
import uuid

registros_bp = Blueprint('registros_bp', __name__)

# 🔹 Obtener todos los registros
@registros_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_registros():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_evaluador, hora_registro, id_planta, id_tipoplanta, imagen
            FROM mapeo_fact_registro
            ORDER BY hora_registro DESC
        """)
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener un registro específico por ID
@registros_bp.route('/<string:registro_id>', methods=['GET'])
@jwt_required()
def obtener_registro(registro_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_evaluador, hora_registro, id_planta, id_tipoplanta, imagen
            FROM mapeo_fact_registro
            WHERE id = %s
        """, (registro_id,))
        
        registro = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not registro:
            return jsonify({"error": "Registro no encontrado"}), 404
        
        return jsonify(registro), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Crear un nuevo registro
@registros_bp.route('/', methods=['POST'])
@jwt_required()
def crear_registro():
    try:
        data = request.json
        usuario_id = get_jwt_identity()
        
        # Logging para debug
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"📥 Datos recibidos: {data}")
        logger.info(f"🔍 id_planta recibido: {data.get('id_planta')} - Tipo: {type(data.get('id_planta'))}")
        
        # Validar campos requeridos
        campos_requeridos = ['id_planta', 'id_tipoplanta']
        for campo in campos_requeridos:
            if campo not in data:
                return jsonify({"error": f"Campo requerido: {campo}"}), 400
        
        # Validar que id_planta sea un número válido
        try:
            id_planta = int(data['id_planta'])
            logger.info(f"✅ id_planta convertido a int: {id_planta}")
        except (ValueError, TypeError) as e:
            logger.error(f"❌ Error convirtiendo id_planta: {e}")
            return jsonify({"error": f"id_planta debe ser un número válido: {data['id_planta']}"}), 400
        
        # Generar ID único
        registro_id = str(uuid.uuid4())
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Insertar el nuevo registro
        cursor.execute("""
            INSERT INTO mapeo_fact_registro 
            (id, id_evaluador, hora_registro, id_planta, id_tipoplanta, imagen)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            registro_id,
            usuario_id,
            datetime.now(),
            id_planta,  # Usar el valor convertido
            data['id_tipoplanta'],
            data.get('imagen', None)
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"✅ Registro creado exitosamente con id: {registro_id}")
        return jsonify({
            "message": "Registro creado exitosamente",
            "id": registro_id
        }), 201
    except Exception as e:
        logger.error(f"❌ Error creando registro: {str(e)}")
        return jsonify({"error": str(e)}), 500

# 🔹 Actualizar un registro existente
@registros_bp.route('/<string:registro_id>', methods=['PUT'])
@jwt_required()
def actualizar_registro(registro_id):
    try:
        data = request.json
        usuario_id = get_jwt_identity()
        
        # Logging para debug
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"📥 Datos de actualización recibidos: {data}")
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registro WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro no encontrado"}), 404
        
        # Construir la consulta de actualización dinámicamente
        campos_actualizables = ['id_planta', 'id_tipoplanta', 'imagen']
        campos_a_actualizar = []
        valores = []
        
        for campo in campos_actualizables:
            if campo in data:
                # Validar id_planta si está presente
                if campo == 'id_planta':
                    try:
                        id_planta = int(data[campo])
                        logger.info(f"✅ id_planta convertido a int: {id_planta}")
                        valores.append(id_planta)
                    except (ValueError, TypeError) as e:
                        logger.error(f"❌ Error convirtiendo id_planta: {e}")
                        return jsonify({"error": f"id_planta debe ser un número válido: {data[campo]}"}), 400
                else:
                    valores.append(data[campo])
                
                campos_a_actualizar.append(f"{campo} = %s")
        
        if not campos_a_actualizar:
            cursor.close()
            conn.close()
            return jsonify({"error": "No hay campos para actualizar"}), 400
        
        # Agregar el ID al final de los valores
        valores.append(registro_id)
        
        # Ejecutar la actualización
        query = f"""
            UPDATE mapeo_fact_registro 
            SET {', '.join(campos_a_actualizar)}
            WHERE id = %s
        """
        
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        
        logger.info(f"✅ Registro actualizado exitosamente: {registro_id}")
        return jsonify({
            "message": "Registro actualizado exitosamente",
            "id": registro_id
        }), 200
    except Exception as e:
        logger.error(f"❌ Error actualizando registro: {str(e)}")
        return jsonify({"error": str(e)}), 500

# 🔹 Eliminar un registro
@registros_bp.route('/<string:registro_id>', methods=['DELETE'])
@jwt_required()
def eliminar_registro(registro_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registro WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro no encontrado"}), 404
        
        # Eliminar el registro
        cursor.execute("""
            DELETE FROM mapeo_fact_registro WHERE id = %s
        """, (registro_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Registro eliminado exitosamente",
            "id": registro_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener registros por evaluador
@registros_bp.route('/evaluador/<string:evaluador_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_evaluador(evaluador_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_evaluador, hora_registro, id_planta, id_tipoplanta, imagen
            FROM mapeo_fact_registro
            WHERE id_evaluador = %s
            ORDER BY hora_registro DESC
        """, (evaluador_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener registros por planta
@registros_bp.route('/planta/<string:planta_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_planta(planta_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_evaluador, hora_registro, id_planta, id_tipoplanta, imagen
            FROM mapeo_fact_registro
            WHERE id_planta = %s
            ORDER BY hora_registro DESC
        """, (planta_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 NUEVO: Obtener registros por hilera
@registros_bp.route('/hilera/<int:hilera_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_hilera(hilera_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT r.id, r.id_evaluador, r.hora_registro, r.id_planta, r.id_tipoplanta, r.imagen,
                   p.planta as numero_planta, p.ubicacion, tp.nombre as tipo_planta_nombre
            FROM mapeo_fact_registro r
            INNER JOIN general_dim_planta p ON r.id_planta = p.id
            LEFT JOIN general_dim_tipoplanta tp ON r.id_tipoplanta = tp.id
            WHERE p.id_hilera = %s
            ORDER BY p.planta ASC, r.hora_registro DESC
        """, (hilera_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 