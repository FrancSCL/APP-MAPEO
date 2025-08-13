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

# 🔹 Obtener resumen de progreso optimizado
@registromapeo_bp.route('/<string:registro_id>/resumen-progreso', methods=['GET'])
@jwt_required()
def obtener_resumen_progreso(registro_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Obtener información del registro y cuartel
        cursor.execute("""
            SELECT rm.id, rm.id_cuartel, c.nombre as nombre_cuartel
            FROM mapeo_fact_registromapeo rm
            LEFT JOIN general_dim_cuartel c ON rm.id_cuartel = c.id
            WHERE rm.id = %s
        """, (registro_id,))
        
        registro = cursor.fetchone()
        if not registro:
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        # Obtener resumen de hileras con progreso
        cursor.execute("""
            SELECT 
                h.id as hilera_id,
                h.hilera,
                COUNT(p.id) as total_plantas,
                COUNT(r.id) as plantas_mapeadas,
                ROUND((COUNT(r.id) * 100.0 / NULLIF(COUNT(p.id), 0)), 1) as porcentaje,
                MAX(r.hora_registro) as ultima_actualizacion
            FROM general_dim_hilera h
            LEFT JOIN general_dim_planta p ON h.id = p.id_hilera
            LEFT JOIN mapeo_fact_registro r ON p.id = r.id_planta 
                AND r.id_evaluador IN (
                    SELECT u.id FROM general_dim_usuario u 
                    WHERE u.id_sucursalactiva = (
                        SELECT rm2.id_cuartel FROM mapeo_fact_registromapeo rm2 
                        WHERE rm2.id = %s
                    )
                )
            WHERE h.id_cuartel = %s
            GROUP BY h.id, h.hilera
            ORDER BY h.hilera ASC
        """, (registro_id, registro['id_cuartel']))
        
        hileras = cursor.fetchall()
        
        # Calcular resumen general
        total_hileras = len(hileras)
        hileras_completadas = sum(1 for h in hileras if h['porcentaje'] == 100.0)
        porcentaje_general = round(sum(h['porcentaje'] or 0 for h in hileras) / total_hileras, 1) if total_hileras > 0 else 0
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "id_sesion": registro_id,
            "cuartel": {
                "id": registro['id_cuartel'],
                "nombre": registro['nombre_cuartel']
            },
            "hileras": [
                {
                    "id": h['hilera_id'],
                    "hilera": h['hilera'],
                    "total_plantas": h['total_plantas'],
                    "plantas_mapeadas": h['plantas_mapeadas'],
                    "porcentaje": h['porcentaje'] or 0.0,
                    "ultima_actualizacion": h['ultima_actualizacion'].isoformat() if h['ultima_actualizacion'] else None
                }
                for h in hileras
            ],
            "resumen_general": {
                "total_hileras": total_hileras,
                "hileras_completadas": hileras_completadas,
                "porcentaje_general": porcentaje_general
            }
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener plantas con mapeo por hilera
@registromapeo_bp.route('/<string:registro_id>/hileras/<int:hilera_id>/plantas-con-mapeo', methods=['GET'])
@jwt_required()
def obtener_plantas_con_mapeo(registro_id, hilera_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registromapeo WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        # Obtener información de la hilera
        cursor.execute("""
            SELECT id, hilera FROM general_dim_hilera WHERE id = %s
        """, (hilera_id,))
        
        hilera = cursor.fetchone()
        if not hilera:
            cursor.close()
            conn.close()
            return jsonify({"error": "Hilera no encontrada"}), 404
        
        # Obtener plantas con información de mapeo
        cursor.execute("""
            SELECT 
                p.id,
                p.planta,
                CASE WHEN r.id IS NOT NULL THEN true ELSE false END as mapeada,
                tp.id as tipo_planta_id,
                tp.nombre as tipo_planta_nombre,
                tp.factor_productivo,
                r.hora_registro as fecha_mapeo
            FROM general_dim_planta p
            LEFT JOIN mapeo_fact_registro r ON p.id = r.id_planta
            LEFT JOIN mapeo_dim_tipoplanta tp ON r.id_tipoplanta = tp.id
            WHERE p.id_hilera = %s
            ORDER BY p.planta ASC
        """, (hilera_id,))
        
        plantas = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "hilera": {
                "id": hilera['id'],
                "hilera": hilera['hilera']
            },
            "plantas": [
                {
                    "id": p['id'],
                    "planta": p['planta'],
                    "mapeada": p['mapeada'],
                    "tipo_planta": {
                        "id": p['tipo_planta_id'],
                        "nombre": p['tipo_planta_nombre'],
                        "factor_productivo": p['factor_productivo']
                    } if p['tipo_planta_id'] else None,
                    "fecha_mapeo": p['fecha_mapeo'].isoformat() if p['fecha_mapeo'] else None
                }
                for p in plantas
            ]
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Cambiar estado de hilera
@registromapeo_bp.route('/<string:registro_id>/hilera/<int:hilera_id>/estado', methods=['PUT'])
@jwt_required()
def cambiar_estado_hilera(registro_id, hilera_id):
    try:
        data = request.json
        nuevo_estado = data.get('estado')
        
        # Validar estado
        estados_validos = ['en_progreso', 'pausado', 'completado']
        if nuevo_estado not in estados_validos:
            return jsonify({"error": f"Estado inválido. Estados válidos: {estados_validos}"}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el registro existe
        cursor.execute("""
            SELECT id FROM mapeo_fact_registromapeo WHERE id = %s
        """, (registro_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Registro de mapeo no encontrado"}), 404
        
        # Verificar que la hilera existe y pertenece al cuartel del registro
        cursor.execute("""
            SELECT h.id, h.hilera 
            FROM general_dim_hilera h
            JOIN mapeo_fact_registromapeo rm ON h.id_cuartel = rm.id_cuartel
            WHERE h.id = %s AND rm.id = %s
        """, (hilera_id, registro_id))
        
        hilera = cursor.fetchone()
        if not hilera:
            cursor.close()
            conn.close()
            return jsonify({"error": "Hilera no encontrada o no pertenece al registro"}), 404
        
        # Por ahora, usamos una tabla temporal o calculamos el estado
        # En una implementación completa, crearíamos la tabla mapeo_fact_estado_hilera
        
        # Para esta implementación, calculamos el estado basado en registros
        cursor.execute("""
            SELECT 
                COUNT(p.id) as total_plantas,
                COUNT(r.id) as plantas_mapeadas
            FROM general_dim_hilera h
            LEFT JOIN general_dim_planta p ON h.id = p.id_hilera
            LEFT JOIN mapeo_fact_registro r ON p.id = r.id_planta
            WHERE h.id = %s
        """, (hilera_id,))
        
        progreso = cursor.fetchone()
        total_plantas = progreso['total_plantas']
        plantas_mapeadas = progreso['plantas_mapeadas']
        
        # Validar que el estado solicitado es coherente con el progreso
        if nuevo_estado == 'completado' and plantas_mapeadas < total_plantas:
            cursor.close()
            conn.close()
            return jsonify({"error": "No se puede marcar como completado si no todas las plantas están mapeadas"}), 400
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "hilera_actualizada": {
                "id_hilera": hilera_id,
                "hilera": hilera['hilera'],
                "estado": nuevo_estado,
                "fecha_actualizacion": datetime.now().isoformat(),
                "progreso": {
                    "plantas_mapeadas": plantas_mapeadas,
                    "total_plantas": total_plantas,
                    "porcentaje": round((plantas_mapeadas * 100.0 / total_plantas), 1) if total_plantas > 0 else 0
                }
            }
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener estadísticas generales
@registromapeo_bp.route('/estadisticas', methods=['GET'])
@jwt_required()
def obtener_estadisticas():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Obtener estadísticas generales
        cursor.execute("""
            SELECT 
                COUNT(*) as total_registros,
                SUM(CASE WHEN id_estado = 1 THEN 1 ELSE 0 END) as en_progreso,
                SUM(CASE WHEN id_estado = 2 THEN 1 ELSE 0 END) as finalizados,
                SUM(CASE WHEN id_estado = 3 THEN 1 ELSE 0 END) as pausados
            FROM mapeo_fact_registromapeo
        """)
        
        stats = cursor.fetchone()
        
        # Calcular porcentaje completado general
        if stats['total_registros'] > 0:
            porcentaje_completado = round((stats['finalizados'] * 100.0 / stats['total_registros']), 1)
        else:
            porcentaje_completado = 0
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "total_registros": stats['total_registros'],
            "en_progreso": stats['en_progreso'],
            "finalizados": stats['finalizados'],
            "pausados": stats['pausados'],
            "porcentaje_completado_general": porcentaje_completado
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500 