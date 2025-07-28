from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection
from datetime import datetime
import uuid

registromapeo_bp = Blueprint('registromapeo_bp', __name__)

# 🔹 Obtener todos los registros de mapeo
@registromapeo_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_registros_mapeo():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado
            FROM mapeo_fact_registromapeo
            ORDER BY fecha_inicio DESC
        """)
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener un registro de mapeo específico por ID
@registromapeo_bp.route('/<string:registro_id>', methods=['GET'])
@jwt_required()
def obtener_registro_mapeo(registro_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado
            FROM mapeo_fact_registromapeo
            WHERE id = %s
        """, (registro_id,))
        
        registro = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not registro:
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        return jsonify(registro), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Crear un nuevo registro de mapeo
@registromapeo_bp.route('/', methods=['POST'])
@jwt_required()
def crear_registro_mapeo():
    try:
        data = request.json
        
        # Validar campos requeridos
        campos_requeridos = ['id_temporada', 'id_cuartel', 'fecha_inicio', 'id_estado']
        for campo in campos_requeridos:
            if campo not in data:
                return jsonify({"error": f"Campo requerido: {campo}"}), 400
        
        # Validar que los campos numéricos sean válidos
        try:
            id_temporada = int(data['id_temporada'])
            id_cuartel = int(data['id_cuartel'])
            id_estado = int(data['id_estado'])
        except (ValueError, TypeError) as e:
            return jsonify({"error": f"Los campos id_temporada, id_cuartel e id_estado deben ser números válidos"}), 400
        
        # Validar formato de fechas
        try:
            fecha_inicio = datetime.strptime(data['fecha_inicio'], '%Y-%m-%d').date()
            fecha_termino = None
            if 'fecha_termino' in data and data['fecha_termino']:
                fecha_termino = datetime.strptime(data['fecha_termino'], '%Y-%m-%d').date()
        except ValueError:
            return jsonify({"error": "Las fechas deben estar en formato YYYY-MM-DD"}), 400
        
        # Generar ID único
        registro_id = str(uuid.uuid4())
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Insertar el nuevo registro de mapeo
        cursor.execute("""
            INSERT INTO mapeo_fact_registromapeo 
            (id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (
            registro_id,
            id_temporada,
            id_cuartel,
            fecha_inicio,
            fecha_termino,
            id_estado
        ))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "mensaje": "Registro de mapeo creado exitosamente",
            "id": registro_id
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Actualizar un registro de mapeo
@registromapeo_bp.route('/<string:registro_id>', methods=['PUT'])
@jwt_required()
def actualizar_registro_mapeo(registro_id):
    try:
        data = request.json
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar si el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registromapeo WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        # Construir query de actualización dinámicamente
        campos_actualizables = ['id_temporada', 'id_cuartel', 'fecha_inicio', 'fecha_termino', 'id_estado']
        campos_a_actualizar = []
        valores = []
        
        for campo in campos_actualizables:
            if campo in data:
                if campo in ['fecha_inicio', 'fecha_termino']:
                    try:
                        fecha = datetime.strptime(data[campo], '%Y-%m-%d').date()
                        campos_a_actualizar.append(f"{campo} = %s")
                        valores.append(fecha)
                    except ValueError:
                        return jsonify({"error": f"La fecha {campo} debe estar en formato YYYY-MM-DD"}), 400
                elif campo in ['id_temporada', 'id_cuartel', 'id_estado']:
                    try:
                        valor = int(data[campo])
                        campos_a_actualizar.append(f"{campo} = %s")
                        valores.append(valor)
                    except (ValueError, TypeError):
                        return jsonify({"error": f"El campo {campo} debe ser un número válido"}), 400
        
        if not campos_a_actualizar:
            cursor.close()
            conn.close()
            return jsonify({"error": "No se proporcionaron campos válidos para actualizar"}), 400
        
        valores.append(registro_id)
        query = f"""
            UPDATE mapeo_fact_registromapeo 
            SET {', '.join(campos_a_actualizar)}
            WHERE id = %s
        """
        
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({"mensaje": "Registro de mapeo actualizado exitosamente"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Eliminar un registro de mapeo
@registromapeo_bp.route('/<string:registro_id>', methods=['DELETE'])
@jwt_required()
def eliminar_registro_mapeo(registro_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar si el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registromapeo WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        # Eliminar el registro
        cursor.execute("""
            DELETE FROM mapeo_fact_registromapeo WHERE id = %s
        """, (registro_id,))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({"mensaje": "Registro de mapeo eliminado exitosamente"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener registros de mapeo por temporada
@registromapeo_bp.route('/temporada/<int:temporada_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_temporada(temporada_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado
            FROM mapeo_fact_registromapeo
            WHERE id_temporada = %s
            ORDER BY fecha_inicio DESC
        """, (temporada_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener registros de mapeo por cuartel
@registromapeo_bp.route('/cuartel/<int:cuartel_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_cuartel(cuartel_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado
            FROM mapeo_fact_registromapeo
            WHERE id_cuartel = %s
            ORDER BY fecha_inicio DESC
        """, (cuartel_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener registros de mapeo por estado
@registromapeo_bp.route('/estado/<int:estado_id>', methods=['GET'])
@jwt_required()
def obtener_registros_por_estado(estado_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_temporada, id_cuartel, fecha_inicio, fecha_termino, id_estado
            FROM mapeo_fact_registromapeo
            WHERE id_estado = %s
            ORDER BY fecha_inicio DESC
        """, (estado_id,))
        
        registros = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(registros), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 