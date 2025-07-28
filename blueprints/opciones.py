from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from utils.db import get_db_connection
#from blueprints.auth import token_requerido
import uuid

opciones_bp = Blueprint('opciones_bp', __name__)

# Endpoint raíz para el blueprint
@opciones_bp.route('/', methods=['GET', 'OPTIONS'])
@jwt_required()
def opciones_root():
    if request.method == 'OPTIONS':
        return '', 200
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)

        cursor.execute("SELECT id, nombre FROM general_dim_labor ORDER BY nombre ASC")
        labores = cursor.fetchall() or []

        cursor.execute("SELECT id, nombre FROM tarja_dim_unidad WHERE id_estado = 1 ORDER BY nombre ASC")
        unidades = cursor.fetchall() or []

        cursor.execute("SELECT id, nombre FROM general_dim_cecotipo ORDER BY nombre ASC")
        tipoCecos = cursor.fetchall() or []

        cursor.close()
        conn.close()

        return jsonify({
            "labores": labores,
            "unidades": unidades,
            "tipoCecos": tipoCecos
        }), 200
    except Exception as e:
        return jsonify({
            "labores": [],
            "unidades": [],
            "tipoCecos": [],
            "error": str(e)
        }), 500


# Obtener sucursales del usuario logueado
@opciones_bp.route('/sucursales', methods=['GET', 'OPTIONS'])
@jwt_required()
def obtener_sucursales():
    if request.method == 'OPTIONS':
        return '', 200
    try:
        usuario_id = get_jwt_identity()
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Obtener sucursales permitidas para el usuario
        cursor.execute("""
            SELECT DISTINCT s.id, s.nombre, s.ubicacion
            FROM general_dim_sucursal s
            JOIN usuario_pivot_sucursal_usuario p ON s.id = p.id_sucursal
            WHERE p.id_usuario = %s
            ORDER BY s.nombre ASC
        """, (usuario_id,))

        sucursales = cursor.fetchall()
        cursor.close()
        conn.close()

        if not sucursales:
            return jsonify([]), 200

        return jsonify(sucursales), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Obtener empresas
@opciones_bp.route('/empresas', methods=['GET', 'OPTIONS'])
@jwt_required()
def obtener_empresas():
    if request.method == 'OPTIONS':
        return '', 200
    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Obtener todas las empresas ordenadas por nombre
        cursor.execute("""
            SELECT id, nombre, rut, codigo_verificador, fecha_suscripcion
            FROM general_dim_empresa
            ORDER BY nombre ASC
        """)

        empresas = cursor.fetchall()
        cursor.close()
        conn.close()

        if not empresas:
            return jsonify([]), 200

        return jsonify(empresas), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# Listar todas las rutas registradas
@opciones_bp.route('/rutas', methods=['GET'])
def listar_rutas():
    rutas = []
    for rule in opciones_bp.url_map.iter_rules():
        rutas.append({
            'endpoint': rule.endpoint,
            'methods': list(rule.methods),
            'route': str(rule)
        })
    return jsonify(rutas), 200
