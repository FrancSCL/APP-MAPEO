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

# 🔹 NUEVO: Obtener progreso en tiempo real de un registro de mapeo
@registromapeo_bp.route('/<string:registro_id>/progreso', methods=['GET'])
@jwt_required()
def obtener_progreso_registro(registro_id):
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
        
        # Obtener todas las hileras del cuartel
        cursor.execute("""
            SELECT id, nombre, id_cuartel
            FROM general_dim_hilera
            WHERE id_cuartel = %s
            ORDER BY nombre ASC
        """, (registro['id_cuartel'],))
        
        hileras = cursor.fetchall()
        total_hileras = len(hileras)
        hileras_completadas = 0
        
        # Calcular progreso por hilera
        hileras_con_progreso = []
        for hilera in hileras:
            # Obtener total de plantas en la hilera
            cursor.execute("""
                SELECT COUNT(*) as total_plantas
                FROM general_dim_planta
                WHERE id_hilera = %s
            """, (hilera['id'],))
            
            total_plantas_result = cursor.fetchone()
            total_plantas = total_plantas_result['total_plantas'] if total_plantas_result else 0
            
            # Obtener plantas mapeadas en esta hilera para este registro
            cursor.execute("""
                SELECT COUNT(*) as plantas_mapeadas
                FROM mapeo_fact_registro r
                INNER JOIN general_dim_planta p ON r.id_planta = p.id
                WHERE p.id_hilera = %s AND r.id_evaluador IN (
                    SELECT id_evaluador FROM mapeo_fact_registromapeo WHERE id = %s
                )
            """, (hilera['id'], registro_id))
            
            plantas_mapeadas_result = cursor.fetchone()
            plantas_mapeadas = plantas_mapeadas_result['plantas_mapeadas'] if plantas_mapeadas_result else 0
            
            # Calcular porcentaje
            porcentaje = (plantas_mapeadas / total_plantas * 100) if total_plantas > 0 else 0
            
            # Obtener estado de hilera desde la tabla de estados
            cursor.execute("""
                SELECT estado FROM mapeo_fact_estado_hilera 
                WHERE id_registro_mapeo = %s AND id_hilera = %s
            """, (registro_id, hilera['id']))
            
            estado_result = cursor.fetchone()
            if estado_result:
                estado = estado_result['estado']
            else:
                # Si no hay estado definido, calcularlo basado en plantas mapeadas
                if plantas_mapeadas == 0:
                    estado = "pendiente"
                elif plantas_mapeadas == total_plantas:
                    estado = "completado"
                else:
                    estado = "en_progreso"
            
            # Contar hileras completadas
            if estado == "completado":
                hileras_completadas += 1
            
            hileras_con_progreso.append({
                "id_hilera": hilera['id'],
                "nombre": hilera['nombre'],
                "total_plantas": total_plantas,
                "plantas_mapeadas": plantas_mapeadas,
                "porcentaje": round(porcentaje, 2),
                "estado": estado
            })
        
        # Calcular porcentaje general
        porcentaje_general = (hileras_completadas / total_hileras * 100) if total_hileras > 0 else 0
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "id_registro": registro_id,
            "cuartel": registro['nombre_cuartel'],
            "total_hileras": total_hileras,
            "hileras_completadas": hileras_completadas,
            "porcentaje_general": round(porcentaje_general, 2),
            "hileras": hileras_con_progreso
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 NUEVO: Obtener estadísticas generales de registros de mapeo
@registromapeo_bp.route('/estadisticas', methods=['GET'])
@jwt_required()
def obtener_estadisticas():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Obtener total de registros
        cursor.execute("SELECT COUNT(*) as total FROM mapeo_fact_registromapeo")
        total_registros = cursor.fetchone()['total']
        
        # Obtener registros por estado
        cursor.execute("""
            SELECT id_estado, COUNT(*) as cantidad
            FROM mapeo_fact_registromapeo
            GROUP BY id_estado
        """)
        
        estados = cursor.fetchall()
        en_progreso = 0
        finalizados = 0
        pausados = 0
        
        for estado in estados:
            if estado['id_estado'] == 1:  # En progreso
                en_progreso = estado['cantidad']
            elif estado['id_estado'] == 2:  # Finalizado
                finalizados = estado['cantidad']
            elif estado['id_estado'] == 3:  # Pausado
                pausados = estado['cantidad']
        
        # Calcular porcentaje completado general
        porcentaje_completado = (finalizados / total_registros * 100) if total_registros > 0 else 0
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "total_registros": total_registros,
            "en_progreso": en_progreso,
            "finalizados": finalizados,
            "pausados": pausados,
            "porcentaje_completado_general": round(porcentaje_completado, 2)
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 NUEVO: Actualizar estado de una hilera específica
@registromapeo_bp.route('/<string:registro_id>/hilera/<int:hilera_id>/estado', methods=['PUT'])
@jwt_required()
def actualizar_estado_hilera(registro_id, hilera_id):
    try:
        data = request.json
        estado = data.get('estado')
        usuario_id = get_jwt_identity()
        
        if not estado or estado not in ['en_progreso', 'pausado', 'completado']:
            return jsonify({"error": "Estado debe ser: en_progreso, pausado o completado"}), 400
        
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
        
        # Verificar que la hilera existe
        cursor.execute("""
            SELECT id FROM general_dim_hilera WHERE id = %s
        """, (hilera_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Hilera no encontrada"}), 404
        
        # Verificar si ya existe un estado para esta hilera en este registro
        cursor.execute("""
            SELECT id FROM mapeo_fact_estado_hilera 
            WHERE id_registro_mapeo = %s AND id_hilera = %s
        """, (registro_id, hilera_id))
        
        estado_existente = cursor.fetchone()
        
        if estado_existente:
            # Actualizar estado existente
            cursor.execute("""
                UPDATE mapeo_fact_estado_hilera 
                SET estado = %s, id_usuario = %s, fecha_actualizacion = NOW()
                WHERE id_registro_mapeo = %s AND id_hilera = %s
            """, (estado, usuario_id, registro_id, hilera_id))
        else:
            # Crear nuevo estado
            estado_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO mapeo_fact_estado_hilera 
                (id, id_registro_mapeo, id_hilera, estado, id_usuario)
                VALUES (%s, %s, %s, %s, %s)
            """, (estado_id, registro_id, hilera_id, estado, usuario_id))
        
        conn.commit()
        
        # Obtener el estado actualizado
        cursor.execute("""
            SELECT eh.estado, eh.fecha_actualizacion, h.nombre as nombre_hilera
            FROM mapeo_fact_estado_hilera eh
            INNER JOIN general_dim_hilera h ON eh.id_hilera = h.id
            WHERE eh.id_registro_mapeo = %s AND eh.id_hilera = %s
        """, (registro_id, hilera_id))
        
        estado_actualizado = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "success": True,
            "hilera_actualizada": {
                "id_hilera": hilera_id,
                "nombre_hilera": estado_actualizado['nombre_hilera'],
                "estado": estado_actualizado['estado'],
                "fecha_actualizacion": estado_actualizado['fecha_actualizacion'].isoformat()
            }
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500 