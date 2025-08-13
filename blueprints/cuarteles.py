from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection
from datetime import datetime, date
import uuid

cuarteles_bp = Blueprint('cuarteles_bp', __name__)

# 🔹 Obtener todos los cuarteles
@cuarteles_bp.route('/', methods=['GET'])
@jwt_required()
def obtener_cuarteles():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            ORDER BY nombre ASC
        """)
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener un cuartel específico por ID
@cuarteles_bp.route('/<int:cuartel_id>', methods=['GET'])
@jwt_required()
def obtener_cuartel(cuartel_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            WHERE id = %s
        """, (cuartel_id,))
        
        cuartel = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if not cuartel:
            return jsonify({"error": "Cuartel no encontrado"}), 404
        
        return jsonify(cuartel), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Crear un nuevo cuartel
@cuarteles_bp.route('/', methods=['POST'])
@jwt_required()
def crear_cuartel():
    try:
        data = request.json
        
        # Validar campos requeridos
        campos_requeridos = ['id_ceco', 'nombre', 'id_variedad', 'superficie', 'ano_plantacion']
        for campo in campos_requeridos:
            if campo not in data:
                return jsonify({"error": f"Campo requerido: {campo}"}), 400
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Insertar el nuevo cuartel
        cursor.execute("""
            INSERT INTO general_dim_cuartel 
            (id_ceco, nombre, id_variedad, superficie, ano_plantacion, dsh, deh, 
             id_propiedad, id_portainjerto, brazos_ejes, id_estado, fecha_baja, 
             id_estadoproductivo, n_hileras, id_estadocatastro)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            data['id_ceco'],
            data['nombre'],
            data['id_variedad'],
            data['superficie'],
            data['ano_plantacion'],
            data.get('dsh'),
            data.get('deh'),
            data.get('id_propiedad'),
            data.get('id_portainjerto'),
            data.get('brazos_ejes'),
            data.get('id_estado', 1),  # Por defecto activo
            data.get('fecha_baja'),
            data.get('id_estadoproductivo'),
            data.get('n_hileras'),
            data.get('id_estadocatastro')
        ))
        
        # Obtener el ID del cuartel recién creado
        cuartel_id = cursor.lastrowid
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Cuartel creado exitosamente",
            "id": cuartel_id
        }), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Actualizar un cuartel existente
@cuarteles_bp.route('/<int:cuartel_id>', methods=['PUT'])
@jwt_required()
def actualizar_cuartel(cuartel_id):
    try:
        data = request.json
        
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el cuartel existe
        cursor.execute("""
            SELECT id FROM general_dim_cuartel WHERE id = %s
        """, (cuartel_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Cuartel no encontrado"}), 404
        
        # Construir la consulta de actualización dinámicamente
        campos_actualizables = [
            'id_ceco', 'nombre', 'id_variedad', 'superficie', 'ano_plantacion',
            'dsh', 'deh', 'id_propiedad', 'id_portainjerto', 'brazos_ejes',
            'id_estado', 'fecha_baja', 'id_estadoproductivo', 'n_hileras', 'id_estadocatastro'
        ]
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
        valores.append(cuartel_id)
        
        # Ejecutar la actualización
        query = f"""
            UPDATE general_dim_cuartel 
            SET {', '.join(campos_a_actualizar)}
            WHERE id = %s
        """
        
        cursor.execute(query, valores)
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Cuartel actualizado exitosamente",
            "id": cuartel_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Eliminar un cuartel (borrado lógico)
@cuarteles_bp.route('/<int:cuartel_id>', methods=['DELETE'])
@jwt_required()
def eliminar_cuartel(cuartel_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Verificar que el cuartel existe
        cursor.execute("""
            SELECT id FROM general_dim_cuartel WHERE id = %s
        """, (cuartel_id,))
        
        if not cursor.fetchone():
            cursor.close()
            conn.close()
            return jsonify({"error": "Cuartel no encontrado"}), 404
        
        # Realizar borrado lógico (marcar como inactivo)
        cursor.execute("""
            UPDATE general_dim_cuartel 
            SET id_estado = 0, fecha_baja = %s
            WHERE id = %s
        """, (date.today(), cuartel_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        return jsonify({
            "message": "Cuartel eliminado exitosamente",
            "id": cuartel_id
        }), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener cuarteles por ceco
@cuarteles_bp.route('/ceco/<int:ceco_id>', methods=['GET'])
@jwt_required()
def obtener_cuarteles_por_ceco(ceco_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            WHERE id_ceco = %s
            ORDER BY nombre ASC
        """, (ceco_id,))
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener cuarteles por variedad
@cuarteles_bp.route('/variedad/<int:variedad_id>', methods=['GET'])
@jwt_required()
def obtener_cuarteles_por_variedad(variedad_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            WHERE id_variedad = %s
            ORDER BY nombre ASC
        """, (variedad_id,))
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener cuarteles activos
@cuarteles_bp.route('/activos', methods=['GET'])
@jwt_required()
def obtener_cuarteles_activos():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT 
                c.id, c.id_ceco, c.nombre, c.id_variedad, c.superficie, c.ano_plantacion, 
                c.dsh, c.deh, c.id_propiedad, c.id_portainjerto, c.brazos_ejes, c.id_estado, 
                c.fecha_baja, c.id_estadoproductivo, c.n_hileras, c.id_estadocatastro,
                ce.id_sucursal, s.nombre AS nombre_sucursal
            FROM general_dim_cuartel c
            LEFT JOIN general_dim_ceco ce ON c.id_ceco = ce.id
            LEFT JOIN general_dim_sucursal s ON ce.id_sucursal = s.id
            WHERE c.id_estado = 1
            ORDER BY c.nombre ASC
        """)
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Obtener cuarteles por propiedad
@cuarteles_bp.route('/propiedad/<int:propiedad_id>', methods=['GET'])
@jwt_required()
def obtener_cuarteles_por_propiedad(propiedad_id):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            WHERE id_propiedad = %s
            ORDER BY nombre ASC
        """, (propiedad_id,))
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 Buscar cuarteles por nombre
@cuarteles_bp.route('/buscar/<string:nombre>', methods=['GET'])
@jwt_required()
def buscar_cuarteles_por_nombre(nombre):
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT id, id_ceco, nombre, id_variedad, superficie, ano_plantacion, 
                   dsh, deh, id_propiedad, id_portainjerto, brazos_ejes, id_estado, 
                   fecha_baja, id_estadoproductivo, n_hileras, id_estadocatastro
            FROM general_dim_cuartel
            WHERE nombre LIKE %s
            ORDER BY nombre ASC
        """, (f'%{nombre}%',))
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# 🔹 NUEVO: Obtener cuarteles con catastro finalizado
@cuarteles_bp.route('/catastro-finalizado', methods=['GET'])
@jwt_required()
def obtener_cuarteles_catastro_finalizado():
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        cursor.execute("""
            SELECT c.id, c.id_ceco, c.nombre, c.id_variedad, c.superficie, c.ano_plantacion, 
                   c.dsh, c.deh, c.id_propiedad, c.id_portainjerto, c.brazos_ejes, c.id_estado, 
                   c.fecha_baja, c.id_estadoproductivo, c.n_hileras, c.id_estadocatastro,
                   ce.id_sucursal, s.nombre AS nombre_sucursal
            FROM general_dim_cuartel c
            LEFT JOIN general_dim_ceco ce ON c.id_ceco = ce.id
            LEFT JOIN general_dim_sucursal s ON ce.id_sucursal = s.id
            WHERE c.id_estadocatastro = 2  -- Asumiendo que 2 = finalizado
            AND c.id_estado = 1  -- Solo cuarteles activos
            ORDER BY c.nombre ASC
        """)
        
        cuarteles = cursor.fetchall()
        cursor.close()
        conn.close()
        
        return jsonify(cuarteles), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500 