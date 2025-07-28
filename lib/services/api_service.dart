import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'login_services.dart';
import '../pages/login_page.dart';
import '../models/cuartel.dart';
import '../models/especie.dart';
import '../models/variedad.dart';
import '../models/hilera.dart';
import '../models/planta.dart';
import '../models/tipo_planta.dart';
import '../models/registro_mapeo.dart';

// 🔧 Sistema de logging condicional
void logDebug(String message) {
  if (kDebugMode) {
    print(message);
  }
}

void logError(String message) {
  if (kDebugMode) {
    print("❌ $message");
  }
}

void logInfo(String message) {
  if (kDebugMode) {
    print("ℹ️ $message");
  }
}

class ApiService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  //final String baseUrl = 'https://apilhtarja.lahornilla.cl/api';
<<<<<<< HEAD
  //final String baseUrl = 'https://api-app-mapeo.onrender.com/api';
  final String baseUrl = 'https://apimapeo-927498545444.us-central1.run.app/api';
=======
  final String baseUrl = 'http://192.168.1.37:5000/api';
>>>>>>> 6242329353efdcc70be3637d201dea1775fbf32c

  /// 🔹 Método para manejar token expirado
  Future<void> manejarTokenExpirado() async {
    try {
      logDebug("🔄 Token expirado, limpiando datos y redirigiendo al login...");
      
      // Limpiar todas las preferencias almacenadas
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Mostrar mensaje de confirmación si hay contexto disponible
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión expirada. Por favor, inicia sesión nuevamente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Navegar al login y limpiar el stack de navegación
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      logError('Error al manejar token expirado: $e');
      // Si hay algún error, intentar navegar al login de todas formas
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  // Método para obtener el token almacenado en SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token'); // Obtener el token almacenado correctamente
  }

  // Método para obtener el refresh token almacenado en SharedPreferences
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token'); // Obtener el refresh token almacenado
  }

  // ✅ Obtener headers con token
  Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token == null) {
        logError("❌ No hay token de acceso");
        throw Exception('No hay token de acceso disponible');
      }

      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      logError("❌ Error al obtener headers: $e");
      throw Exception('Error al obtener headers: $e');
    }
  }

  Future<http.Response> _manejarRespuesta(http.Response response) async {
    // Solo manejar errores específicos de token expirado en el body
    if (response.statusCode != 401 && 
        response.body.isNotEmpty && 
        (response.body.toLowerCase().contains('token has expired') ||
         response.body.toLowerCase().contains('token expired') ||
         response.body.toLowerCase().contains('unauthorized'))) {
      await manejarTokenExpirado();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }
    return response;
  }

  /// 🔹 Método helper para hacer peticiones HTTP con manejo automático de tokens expirados
  Future<http.Response> _makeRequest(Future<http.Response> Function() requestFunction) async {
    try {
      final response = await requestFunction();
      
      logDebug("🔍 Response status: ${response.statusCode}");
      logDebug("🔍 Response headers: ${response.headers}");
      logDebug("🔍 Response body: ${response.body}");
      
      // Si la respuesta es una redirección (3xx)
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          logDebug("🔄 Siguiendo redirección a: $redirectUrl");
          final redirectResponse = await http.get(
            Uri.parse(redirectUrl),
            headers: await _getHeaders(),
          );
          return await _manejarRespuesta(redirectResponse);
        }
      }
      
      // Si la respuesta es 401, intentar refresh del token
      if (response.statusCode == 401) {
        logDebug("🔄 Detectado error 401, intentando refresh del token...");
        bool refreshed = await AuthService().refreshToken();
        
        if (refreshed) {
          logDebug("✅ Token refresh exitoso, reintentando petición original...");
          // Reintentar la petición original con el nuevo token
          final retryResponse = await requestFunction();
          return await _manejarRespuesta(retryResponse);
        } else {
          // Si el refresh falla, manejar como token expirado
          await manejarTokenExpirado();
          throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
        }
      }

      // Verificar si la respuesta es HTML en lugar de JSON
      if (response.headers['content-type']?.toLowerCase().contains('text/html') == true) {
        logError("❌ Error: Respuesta HTML recibida cuando se esperaba JSON");
        throw Exception('Error de servidor: Se recibió HTML cuando se esperaba JSON');
      }
      
      return await _manejarRespuesta(response);
    } catch (e) {
      logError("❌ Error en _makeRequest: $e");
      
      // Si es un error de red o conexión, no manejar como token expirado
      if (e.toString().contains('Sesión expirada')) {
        rethrow;
      }
      
      // Verificar si es un error de conexión
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Error de conexión. Verifica tu conexión a internet.');
      }
      
      throw Exception('Error de conexión: $e');
    }
  }

  /// 🔹 Método para verificar si el token está expirado
  Future<bool> verificarTokenValido() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/usuarios/sucursal-activa'), // Usar endpoint que existe
          headers: await _getHeaders(),
        );
      });
      return response.statusCode == 200;
    } catch (e) {
      // Si hay cualquier error, asumir que el token no es válido
      return false;
    }
  }

  /// 🔹 Método para cerrar sesión manualmente
  Future<void> cerrarSesion() async {
    try {
      // Limpiar todas las preferencias almacenadas
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Esto incluye token, refresh_token, y todos los demás datos

      // Mostrar mensaje de confirmación si hay contexto disponible
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión cerrada exitosamente.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navegar al login y limpiar el stack de navegación
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      logError('Error al cerrar sesión: $e');
      // Si hay algún error, intentar navegar al login de todas formas
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  /// 🔹 Método para reintentar la petición si el token expira
  Future<http.Response> _retryRequest(http.Request request) async {
    try {
      logDebug("🔄 Token expirado, intentando refresh...");
      bool refreshed = await AuthService().refreshToken();
      
      if (refreshed) {
        logDebug("✅ Token refresh exitoso, reintentando petición...");
        final newHeaders = await _getHeaders();
        request.headers.clear();
        request.headers.addAll(newHeaders);
        return await http.Response.fromStream(await request.send());
      } else {
        logError("❌ Falló el refresh del token");
        throw Exception('Sesión expirada, inicia sesión nuevamente.');
      }
    } catch (e) {
      logError("❌ Error en retry request: $e");
      throw Exception('Sesión expirada, inicia sesión nuevamente.');
    }
  }

  // 🔹 Obtener sucursal activa del usuario logueado
  Future<String?> getSucursalActiva() async {
    final response = await _makeRequest(() async {
      return await http.get(
        Uri.parse('$baseUrl/usuarios/sucursal-activa'), // ← este es el correcto
        headers: await _getHeaders(),
      );
    });

    logDebug("🔍 Respuesta API Sucursal Activa: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      logInfo("✅ Sucursal activa obtenida: ${data["sucursal_activa"]}");
      return data["sucursal_activa"].toString();
    } else {
      logError("❌ Error al obtener sucursal activa: ${response.body}");
      return null;
    }
  }

  //Metodo para actualizar la sucursal activa
  Future<bool> actualizarSucursalActiva(String nuevaSucursalId) async {
    final response = await _makeRequest(() async {
      return await http.post(
        Uri.parse('$baseUrl/usuarios/sucursal-activa'),
        headers: await _getHeaders(),
        body: jsonEncode({"id_sucursal": nuevaSucursalId}),
      );
    });

    return response.statusCode == 200;
  }

  //Metodo para cambiar la clave
  Future<Map<String, dynamic>> cambiarClave(
      String claveActual, String nuevaClave) async {
    final response = await _makeRequest(() async {
      return await http.post(
        Uri.parse("$baseUrl/auth/cambiar-clave"), // ✅ URL corregida
        headers: await _getHeaders(),
        body: jsonEncode({"clave_actual": claveActual, "nueva_clave": nuevaClave}),
      );
    });

    return jsonDecode(response.body);
  }

  /// Obtiene las sucursales disponibles
  Future<List<Map<String, dynamic>>> getSucursales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No se encontró el token');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/opciones/sucursales'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

    if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Si el backend devuelve un array directamente (caso especial)
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        
        // Manejar tanto boolean como string para el campo success
        final success = data['success'];
        if (success == true || success == "true" || success == 1) {
          return List<Map<String, dynamic>>.from(data['sucursales'] ?? []);
        } else {
          throw Exception(data['error'] ?? 'Error al obtener las sucursales');
        }
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Error al obtener las sucursales');
    }
    } catch (e) {
      logError('❌ Error al cargar sucursales disponibles: $e');
      throw Exception('Error al obtener las sucursales: $e');
    }
  }

  //Metodo para obtener las opciones
  Future<Map<String, dynamic>> getOpciones() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/opciones/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al obtener opciones');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener sucursales para usuarios (nuevo endpoint)
  Future<List<Map<String, dynamic>>> getSucursalesUsuarios() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/sucursales'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener las sucursales para usuarios');
    }
  }

  // Obtener sucursales permitidas de un usuario específico
  Future<List<Map<String, dynamic>>> getSucursalesPermitidasUsuario(String usuarioId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$usuarioId/sucursales-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener las sucursales permitidas del usuario');
    }
  }

  // Asignar sucursales permitidas a un usuario
  Future<void> asignarSucursalesPermitidas(String usuarioId, List<int> sucursalesIds) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$usuarioId/sucursales-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "sucursales_ids": sucursalesIds,
      }),
    );

    await _manejarRespuesta(response);

    if (response.statusCode != 200) {
      throw Exception('Error al asignar sucursales permitidas al usuario');
    }
  }

  // Eliminar todas las sucursales permitidas de un usuario
  Future<void> eliminarSucursalesPermitidas(String usuarioId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/$usuarioId/sucursales-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar las sucursales permitidas del usuario');
    }
  }

  // Obtener todas las aplicaciones disponibles
  Future<List<Map<String, dynamic>>> getAplicaciones() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/apps'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener las aplicaciones disponibles');
    }
  }

  // Obtener aplicaciones permitidas de un usuario específico
  Future<List<Map<String, dynamic>>> getAplicacionesPermitidasUsuario(String usuarioId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/usuarios/$usuarioId/apps-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Error al obtener las aplicaciones permitidas del usuario');
    }
  }

  // Asignar aplicaciones permitidas a un usuario
  Future<void> asignarAplicacionesPermitidas(String usuarioId, List<int> aplicacionesIds) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$usuarioId/apps-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "apps_ids": aplicacionesIds,
      }),
    );

    await _manejarRespuesta(response);

    if (response.statusCode != 200) {
      throw Exception('Error al asignar aplicaciones permitidas al usuario');
    }
  }

  // Eliminar todas las aplicaciones permitidas de un usuario
  Future<void> eliminarAplicacionesPermitidas(String usuarioId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No se encontró un token. Inicia sesión nuevamente.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/usuarios/$usuarioId/apps-permitidas'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    await _manejarRespuesta(response);

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar las aplicaciones permitidas del usuario');
    }
  }

  /// 🔹 Método para verificar si el token está próximo a expirar y hacer refresh proactivo
  Future<bool> verificarYRefreshToken() async {
    try {
      // Primero verificar si hay token
      final token = await getToken();
      if (token == null) {
        logError("❌ No hay token disponible");
        return false;
      }

      // Usar un endpoint simple para verificar si el token es válido
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/usuarios/sucursal-activa'),
          headers: await _getHeaders(),
        );
      });
      
      // Si la petición fue exitosa, el token es válido
      return response.statusCode == 200;
    } catch (e) {
      logError("🔄 Error al verificar token: $e");
      
      // Solo intentar refresh si el error es de autenticación
      if (e.toString().contains('401') || 
          e.toString().contains('token') || 
          e.toString().contains('Token')) {
        
        logDebug("🔄 Token puede estar expirado, intentando refresh proactivo...");
        try {
          bool refreshed = await AuthService().refreshToken();
          
          if (refreshed) {
            logDebug("✅ Refresh proactivo exitoso");
            return true;
          } else {
            logError("❌ Refresh proactivo falló");
            return false;
          }
        } catch (refreshError) {
          logError("❌ Error en refresh: $refreshError");
          return false;
        }
      }
      
      // Si no es un error de autenticación, asumir que el token es válido
      // (puede ser un error de red o servidor)
      logInfo("⚠️ Error no relacionado con autenticación, asumiendo token válido");
      return true;
    }
  }

  //Metodo para refrescar el token
  Future<void> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      
      if (refreshToken == null) {
        logError("❌ No hay refresh token almacenado");
        throw Exception('No hay refresh token disponible');
      }

      logDebug("🔄 Intentando refrescar token...");
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      logDebug("📡 Código de respuesta refresh: ${response.statusCode}");
      logDebug("📝 Respuesta del servidor refresh: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        logInfo("✅ Token refrescado exitosamente");
      } else {
        logError("❌ Error en refresh token - Código: ${response.statusCode}");
        logError("❌ Detalle del error refresh: ${response.body}");
        
        // Si el refresh token expiró, limpiar tokens y redirigir al login
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      }
    } catch (e) {
      logError("❌ Error en refreshToken: $e");
      throw Exception('Error al refrescar el token: $e');
    }
  }

  // 🔹 Métodos para cuarteles
  Future<List<Cuartel>> getCuarteles() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/cuarteles/'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Cuartel.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener cuarteles: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error al obtener cuarteles: $e");
      throw Exception('Error al obtener cuarteles: $e');
    }
  }

  Future<List<Cuartel>> getCuartelesActivos() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/cuarteles/activos'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Cuartel.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Cuartel.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener cuarteles activos: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error al obtener cuarteles activos: $e");
      throw Exception('Error al obtener cuarteles activos: $e');
    }
  }

  Future<Cuartel> getCuartelById(int cuartelId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/cuarteles/$cuartelId'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Cuartel.fromJson(data['data']);
        } else {
          throw Exception('Cuartel no encontrado');
        }
      } else {
        throw Exception('Error al obtener cuartel: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error al obtener cuartel: $e");
      throw Exception('Error al obtener cuartel: $e');
    }
  }

  // 🔹 Métodos para especies
  Future<List<Especie>> getEspecies() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/especies/'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Especie.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Especie.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener especies: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error al obtener especies: $e");
      throw Exception('Error al obtener especies: $e');
    }
  }

  // 🔹 Métodos para variedades
  Future<List<Variedad>> getVariedades() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/variedades/'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Variedad.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Variedad.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener variedades: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error al obtener variedades: $e");
      throw Exception('Error al obtener variedades: $e');
    }
  }

  // Obtener hileras por cuartel
  Future<List<Hilera>> getHilerasPorCuartel(int cuartelId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/hileras/cuartel/$cuartelId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Hilera.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => Hilera.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener hileras: ${response.statusCode}');
      }
    } catch (e) {
      // Solo logear errores críticos, no todos los errores
      if (kDebugMode) {
        print('Error al obtener hileras del cuartel $cuartelId: $e');
      }
      throw Exception('Error al obtener hileras: $e');
    }
  }

  // Obtener hilera por ID
  Future<Hilera> getHileraById(int hileraId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/hileras/$hileraId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Hilera.fromJson(data['data']);
        } else {
          throw Exception('Hilera no encontrada');
        }
      } else {
        throw Exception('Error al obtener hilera: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener hilera: $e');
      throw Exception('Error al obtener hilera: $e');
    }
  }

  // Crear hilera
  Future<void> crearHilera(CrearHileraRequest request) async {
    try {
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/hileras/'),
          headers: await _getHeaders(),
          body: jsonEncode(request.toJson()),
        );
      });
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error al crear hilera: ${response.statusCode}');
      }
      
      // Obtener el número actual de hileras del cuartel y actualizarlo
      final hileras = await getHilerasPorCuartel(request.idCuartel);
      final nuevoNumeroHileras = hileras.length;
      
      // Actualizar el campo n_hileras en el cuartel
      await actualizarCuartel(request.idCuartel, {'n_hileras': nuevoNumeroHileras});
      logInfo('✅ Campo n_hileras actualizado en cuartel ${request.idCuartel} a $nuevoNumeroHileras');
    } catch (e) {
      logError('❌ Error al crear hilera: $e');
      throw Exception('Error al crear hilera: $e');
    }
  }

  // Eliminar hilera
  Future<void> eliminarHilera(int hileraId) async {
    try {
      // Primero obtener la hilera para saber a qué cuartel pertenece
      final hilera = await getHileraById(hileraId);
      final cuartelId = hilera.idCuartel;
      
      final response = await _makeRequest(() async {
        return await http.delete(
          Uri.parse('$baseUrl/hileras/$hileraId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode != 200) {
        throw Exception('Error al eliminar hilera: ${response.statusCode}');
      }
      
      // Obtener el número actual de hileras del cuartel y actualizarlo
      final hileras = await getHilerasPorCuartel(cuartelId);
      final nuevoNumeroHileras = hileras.length;
      
      // Actualizar el campo n_hileras en el cuartel
      await actualizarCuartel(cuartelId, {'n_hileras': nuevoNumeroHileras});
      logInfo('✅ Campo n_hileras actualizado en cuartel $cuartelId a $nuevoNumeroHileras');
    } catch (e) {
      logError('❌ Error al eliminar hilera: $e');
      throw Exception('Error al eliminar hilera: $e');
    }
  }

  // Actualizar cuartel (por ejemplo, n_hileras)
  Future<void> actualizarCuartel(int cuartelId, Map<String, dynamic> data) async {
    try {
      final response = await _makeRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/cuarteles/$cuartelId'),
          headers: await _getHeaders(),
          body: jsonEncode(data),
        );
      });
      if (response.statusCode != 200) {
        throw Exception('Error al actualizar cuartel: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al actualizar cuartel: $e');
      throw Exception('Error al actualizar cuartel: $e');
    }
  }

  // Verificar si al menos una hilera tiene plantas
  Future<bool> alMenosUnaHileraTienePlantas(int cuartelId) async {
    try {
      final hileras = await getHilerasPorCuartel(cuartelId);
      
      for (final hilera in hileras) {
        final plantas = await getPlantasPorHilera(hilera.id);
        if (plantas.isNotEmpty) {
          return true;
        }
      }
      return false;
    } catch (e) {
      logError('❌ Error al verificar hileras con plantas: $e');
      return false;
    }
  }

  // Verificar si todas las hileras tienen al menos una planta
  Future<bool> todasLasHilerasTienenPlantas(int cuartelId) async {
    try {
      final hileras = await getHilerasPorCuartel(cuartelId);
      
      if (hileras.isEmpty) {
        return false;
      }
      
      for (final hilera in hileras) {
        final plantas = await getPlantasPorHilera(hilera.id);
        if (plantas.isEmpty) {
          return false;
        }
      }
      return true;
    } catch (e) {
      logError('❌ Error al verificar todas las hileras con plantas: $e');
      return false;
    }
  }

  // Actualizar estado del catastro del cuartel
  Future<void> actualizarEstadoCatastro(int cuartelId, int nuevoEstado) async {
    try {
      final response = await _makeRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/cuarteles/$cuartelId'),
          headers: await _getHeaders(),
          body: jsonEncode({'id_estadocatastro': nuevoEstado}),
        );
      });
      
      if (response.statusCode != 200) {
        throw Exception('Error al actualizar estado del catastro: ${response.statusCode}');
      }
      
      logInfo('✅ Estado del catastro actualizado a: $nuevoEstado');
    } catch (e) {
      logError('❌ Error al actualizar estado del catastro: $e');
      throw Exception('Error al actualizar estado del catastro: $e');
    }
  }

  // Agregar múltiples hileras a un cuartel
  Future<void> agregarMultiplesHileras(int cuartelId, int nHileras) async {
    try {
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/hileras/agregar-multiples'),
          headers: await _getHeaders(),
          body: jsonEncode({'id_cuartel': cuartelId, 'n_hileras': nHileras}),
        );
      });
      if (response.statusCode != 200) {
        throw Exception('Error al agregar hileras: ${response.statusCode}');
      }
      
      // Actualizar el campo n_hileras en el cuartel
      await actualizarCuartel(cuartelId, {'n_hileras': nHileras});
      logInfo('✅ Campo n_hileras actualizado en cuartel $cuartelId a $nHileras');
    } catch (e) {
      logError('❌ Error al agregar múltiples hileras: $e');
      throw Exception('Error al agregar múltiples hileras: $e');
    }
  }

  // 🔹 Métodos para plantas
  // Obtener todas las plantas
  Future<List<Planta>> getPlantas() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/plantas/'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Planta.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => Planta.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener plantas: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener plantas: $e');
      throw Exception('Error al obtener plantas: $e');
    }
  }

  // Obtener plantas por hilera
  Future<List<Planta>> getPlantasPorHilera(int hileraId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/plantas/hilera/$hileraId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Planta.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => Planta.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al obtener plantas por hilera: ${response.statusCode}');
      }
    } catch (e) {
      // Solo logear errores críticos, no todos los errores
      if (kDebugMode) {
        print('Error al obtener plantas por hilera $hileraId: $e');
      }
      throw Exception('Error al obtener plantas por hilera: $e');
    }
  }

  // Obtener planta por ID
  Future<Planta> getPlantaById(int plantaId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/plantas/$plantaId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return Planta.fromJson(data['data']);
        } else {
          throw Exception('Planta no encontrada');
        }
      } else {
        throw Exception('Error al obtener planta: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener planta: $e');
      throw Exception('Error al obtener planta: $e');
    }
  }

  // Actualizar planta
  Future<void> actualizarPlanta(int plantaId, ActualizarPlantaRequest request) async {
    try {
      final response = await _makeRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/plantas/$plantaId'),
          headers: await _getHeaders(),
          body: jsonEncode(request.toJson()),
        );
      });
      if (response.statusCode != 200) {
        throw Exception('Error al actualizar planta: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al actualizar planta: $e');
      throw Exception('Error al actualizar planta: $e');
    }
  }

  // Eliminar planta
  Future<void> eliminarPlanta(int plantaId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.delete(
          Uri.parse('$baseUrl/plantas/$plantaId'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode != 200) {
        throw Exception('Error al eliminar planta: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al eliminar planta: $e');
      throw Exception('Error al eliminar planta: $e');
    }
  }

  // Buscar plantas por ubicación
  Future<List<Planta>> buscarPlantasPorUbicacion(String ubicacion) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/plantas/ubicacion/$ubicacion'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Planta.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => Planta.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al buscar plantas por ubicación: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al buscar plantas por ubicación: $e');
      throw Exception('Error al buscar plantas por ubicación: $e');
    }
  }

  // Buscar plantas por número
  Future<List<Planta>> buscarPlantasPorNumero(int numeroPlanta) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/plantas/numero/$numeroPlanta'),
          headers: await _getHeaders(),
        );
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => Planta.fromJson(json)).toList();
        } else if (data['data'] != null) {
          return (data['data'] as List).map((json) => Planta.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al buscar plantas por número: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al buscar plantas por número: $e');
      throw Exception('Error al buscar plantas por número: $e');
    }
  }

  // Método para probar la conexión al servidor
  Future<bool> probarConexionServidor() async {
    try {
      logDebug("🔍 Probando conexión al servidor...");
      
      final response = await http.get(
        Uri.parse('$baseUrl/plantas/'),
        headers: await _getHeaders(),
      );
      
      logDebug("📡 Respuesta GET plantas: ${response.statusCode}");
      logDebug("📝 Body: ${response.body}");
      
      return response.statusCode == 200 || response.statusCode == 401; // 401 es normal si no hay token
    } catch (e) {
      logError("❌ Error probando conexión: $e");
      return false;
    }
  }

  // Método para verificar la estructura de la hilera
  Future<Map<String, dynamic>> verificarHilera(int hileraId) async {
    try {
      logDebug("🔍 Verificando hilera: $hileraId");
      
      final response = await http.get(
        Uri.parse('$baseUrl/hileras/$hileraId'),
        headers: await _getHeaders(),
      );
      
      logDebug("📡 Respuesta GET hilera: ${response.statusCode}");
      logDebug("📝 Body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Error al obtener hilera: ${response.statusCode}');
      }
    } catch (e) {
      logError("❌ Error verificando hilera: $e");
      throw Exception('Error al verificar hilera: $e');
    }
  }

  // Crear planta - método alternativo para diagnóstico
  Future<void> crearPlantaSimple(int idHilera, int planta, String ubicacion) async {
    try {
      final requestData = {
        'id_hilera': idHilera,
        'planta': planta,
        'ubicacion': ubicacion,
      };
      
      logDebug("🔄 Creando planta simple con datos: $requestData");
      logDebug("📡 URL: $baseUrl/plantas/");
      
      final headers = await _getHeaders();
      logDebug("📋 Headers: $headers");
      
      // Logging adicional para diagnóstico
      logDebug("🔍 Tipo de datos:");
      logDebug("  - id_hilera: ${idHilera.runtimeType} = $idHilera");
      logDebug("  - planta: ${planta.runtimeType} = $planta");
      logDebug("  - ubicacion: ${ubicacion.runtimeType} = '$ubicacion'");
      
      final jsonBody = jsonEncode(requestData);
      logDebug("📦 JSON enviado: $jsonBody");
      
      // Logging adicional para el equipo de backend
      print("🚨 === DATOS PARA BACKEND ===");
      print("URL: $baseUrl/plantas/");
      print("Method: POST");
      print("Headers: $headers");
      print("Body: $jsonBody");
      print("================================");
      
      final response = await http.post(
        Uri.parse('$baseUrl/plantas/'),
        headers: headers,
        body: jsonBody,
      );
      
      logDebug("📡 Respuesta crear planta simple: ${response.statusCode}");
      logDebug("📝 Body respuesta: ${response.body}");
      logDebug("📋 Headers respuesta: ${response.headers}");
      
      // Logging adicional para el equipo de backend
      print("🚨 === RESPUESTA DEL BACKEND ===");
      print("Status Code: ${response.statusCode}");
      print("Response Headers: ${response.headers}");
      print("Response Body: ${response.body}");
      print("=================================");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        logInfo("✅ Planta creada exitosamente");
        return;
      } else if (response.statusCode == 500) {
        logError("❌ Error 500 del servidor");
        logError("📝 Body del error: ${response.body}");
        
        // Intentar parsear el error para obtener más detalles
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Error interno del servidor';
          logError("🔍 Error parseado: $errorMessage");
          throw Exception('Error del servidor: $errorMessage');
        } catch (parseError) {
          logError("❌ No se pudo parsear el error: $parseError");
          throw Exception('Error interno del servidor (500). Contacte al administrador.');
        }
      } else {
        logError("❌ Error ${response.statusCode}: ${response.body}");
        throw Exception('Error al crear planta: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      logError('❌ Error al crear planta simple: $e');
      
      // Manejar errores específicos
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        throw Exception('Error de conexión al servidor. Verifique la conexión.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Tiempo de espera agotado. Intente nuevamente.');
      } else {
        throw Exception('Error al crear planta: $e');
      }
    }
  }

  // Crear planta
  Future<void> crearPlanta(CrearPlantaRequest request) async {
    try {
      final requestData = request.toJson();
      logDebug("🔄 Creando planta con datos: $requestData");
      logDebug("📡 URL: $baseUrl/plantas/");
      
      final headers = await _getHeaders();
      logDebug("📋 Headers: $headers");
      
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/plantas/'),
          headers: headers,
          body: jsonEncode(requestData),
        );
      });
      
      logDebug("📡 Respuesta crear planta: ${response.statusCode}");
      logDebug("📝 Body respuesta: ${response.body}");
      logDebug("📋 Headers respuesta: ${response.headers}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        logInfo("✅ Planta creada exitosamente");
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Datos inválidos';
        logError("❌ Error 400: $errorMessage");
        throw Exception(errorMessage);
      } else if (response.statusCode == 409) {
        logError("❌ Error 409: Ya existe una planta con ese número");
        throw Exception('Ya existe una planta con ese número');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Datos de validación incorrectos';
        logError("❌ Error 422: $errorMessage");
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        logError("❌ Error 500 del servidor");
        logError("📝 Body del error: ${response.body}");
        throw Exception('Error del servidor. Intente más tarde');
      } else {
        logError("❌ Error ${response.statusCode}: ${response.body}");
        throw Exception('Error al crear planta: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al crear planta: $e');
      throw Exception('Error al crear planta: $e');
    }
  }

  // Verificar y actualizar automáticamente el estado del catastro
  Future<void> verificarYActualizarEstadoCatastro(int cuartelId) async {
    try {
      // Primero, obtener el estado actual del cuartel
      final cuartel = await getCuartelById(cuartelId);
      final estadoActual = cuartel.idEstadoCatastro;
      
      logInfo('🔍 Verificando estado del catastro para cuartel $cuartelId');
      logInfo('📊 Estado actual: $estadoActual');
      
      // Si el cuartel ya está FINALIZADO (estado 3), NO cambiar automáticamente
      if (estadoActual == 3) {
        logInfo('✅ Cuartel ya está FINALIZADO (3) - No se cambia automáticamente');
        return;
      }
      
      final hileras = await getHilerasPorCuartel(cuartelId);
      
      if (hileras.isEmpty) {
        // No hay hileras, estado debe ser SIN CATASTRO (1)
        if (estadoActual != 1) {
          await actualizarEstadoCatastro(cuartelId, 1);
          logInfo('✅ Estado actualizado a SIN CATASTRO (1) - No hay hileras');
        } else {
          logInfo('ℹ️ Estado ya es SIN CATASTRO (1) - No se cambia');
        }
        return;
      }
      
      // Verificar si hay al menos una hilera con plantas
      bool hayHileraConPlantas = false;
      for (final hilera in hileras) {
        final plantas = await getPlantasPorHilera(hilera.id);
        if (plantas.isNotEmpty) {
          hayHileraConPlantas = true;
          break;
        }
      }
      
      if (hayHileraConPlantas) {
        // Hay al menos una hilera con plantas, estado debe ser INICIADO (2)
        if (estadoActual != 2) {
          await actualizarEstadoCatastro(cuartelId, 2);
          logInfo('✅ Estado actualizado a INICIADO (2) - Hay hileras con plantas');
        } else {
          logInfo('ℹ️ Estado ya es INICIADO (2) - No se cambia');
        }
      } else {
        // No hay hileras con plantas, estado debe ser SIN CATASTRO (1)
        if (estadoActual != 1) {
          await actualizarEstadoCatastro(cuartelId, 1);
          logInfo('✅ Estado actualizado a SIN CATASTRO (1) - No hay hileras con plantas');
        } else {
          logInfo('ℹ️ Estado ya es SIN CATASTRO (1) - No se cambia');
        }
      }
    } catch (e) {
      logError('❌ Error al verificar y actualizar estado del catastro: $e');
      throw Exception('Error al verificar estado del catastro: $e');
    }
  }

  // ===== MÉTODOS PARA MAPEO =====

  // Obtener tipos de planta
  Future<List<TipoPlanta>> getTiposPlanta() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/tipoplanta/'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Manejar diferentes formatos de respuesta
        List<dynamic> tiposData;
        
        if (data is List) {
          // Si la respuesta es directamente una lista
          tiposData = data;
        } else if (data['data'] != null) {
          // Si la respuesta tiene un campo 'data'
          tiposData = data['data'] as List<dynamic>;
        } else if (data['tipos'] != null) {
          // Si la respuesta tiene un campo 'tipos'
          tiposData = data['tipos'] as List<dynamic>;
        } else {
          // Si no hay datos, devolver lista vacía
          logInfo('⚠️ No se encontraron tipos de planta en la respuesta');
          return [];
        }
        
        return tiposData.map((json) => TipoPlanta.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tipos de planta: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener tipos de planta: $e');
      throw Exception('Error al obtener tipos de planta: $e');
    }
  }

  // Probar estructura de datos para registro de mapeo
  Future<void> probarRegistroMapeo() async {
    try {
      logInfo('🧪 Probando estructura de datos para registro de mapeo...');
      
      // Crear datos de prueba más realistas
      final datosPrueba = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'id_evaluador': '1',
        'hora_registro': DateTime.now().toIso8601String(),
        'id_planta': '123456789', // ID grande para simular bigint
        'id_tipoplanta': 1,
        'imagen': null,
      };
      
      logInfo('📤 Datos de prueba: $datosPrueba');
      logInfo('📡 URL: $baseUrl/registros/');
      
      final headers = await _getHeaders();
      logInfo('📋 Headers: $headers');
      
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/registros/'),
          headers: headers,
          body: jsonEncode(datosPrueba),
        );
      });
      
      logInfo('📡 Respuesta de prueba: ${response.statusCode}');
      logInfo('📝 Body de respuesta: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        logInfo('✅ Prueba exitosa - Estructura de datos correcta');
        logInfo('✅ El backend acepta bigint como String');
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        logError('❌ Error 400: ${errorData['error'] ?? 'Datos inválidos'}');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        logError('❌ Error 422: ${errorData['error'] ?? 'Validación incorrecta'}');
      } else if (response.statusCode == 500) {
        logError('❌ Error 500 del servidor');
        logError('📝 Body del error: ${response.body}');
      } else {
        logError('❌ Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      logError('❌ Error en prueba: $e');
    }
  }

  // Crear registro de mapeo
  Future<void> crearRegistroMapeo(RegistroMapeo registro) async {
    try {
      final requestData = registro.toJson();
      logInfo('📤 Creando registro de mapeo con datos: $requestData');
      logInfo('📡 URL: $baseUrl/registros/');
      
      final headers = await _getHeaders();
      logInfo('📋 Headers: $headers');
      
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/registros/'),
          headers: headers,
          body: jsonEncode(requestData),
        );
      });

      logInfo('📡 Respuesta crear registro: ${response.statusCode}');
      logInfo('📝 Body respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        logInfo('✅ Registro de mapeo creado exitosamente');
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Datos inválidos';
        logError('❌ Error 400: $errorMessage');
        throw Exception(errorMessage);
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? 'Datos de validación incorrectos';
        logError('❌ Error 422: $errorMessage');
        throw Exception(errorMessage);
      } else if (response.statusCode == 500) {
        logError('❌ Error 500 del servidor');
        logError('📝 Body del error: ${response.body}');
        throw Exception('Error del servidor. Intente más tarde');
      } else {
        logError('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al crear registro de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al crear registro de mapeo: $e');
      throw Exception('Error al crear registro de mapeo: $e');
    }
  }

  // Obtener registros de mapeo por hilera
  Future<List<RegistroMapeo>> getRegistrosMapeoPorHilera(int hileraId) async {
    try {
      // Por ahora, obtener todos los registros y filtrar por hilera
      // TODO: Implementar endpoint específico en el backend
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/registros/'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> registrosData;
        
        if (data is List) {
          registrosData = data;
        } else if (data['data'] != null) {
          registrosData = data['data'] as List<dynamic>;
        } else {
          return [];
        }
        
        // Filtrar registros que pertenezcan a plantas de esta hilera
        final registros = registrosData.map((json) => RegistroMapeo.fromJson(json)).toList();
        
        // TODO: Necesitamos obtener las plantas de la hilera para filtrar
        // Por ahora, devolver lista vacía hasta que implementemos el filtrado
        logInfo('⚠️ Filtrado de registros por hilera no implementado completamente');
        return [];
      } else {
        throw Exception('Error al obtener registros de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener registros de mapeo: $e');
      // Por ahora, devolver lista vacía en caso de error
      return [];
    }
  }

  // Verificar si un cuartel tiene catastro finalizado
  Future<bool> cuartelTieneCatastroFinalizado(int cuartelId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/cuarteles/$cuartelId'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          final cuartel = Cuartel.fromJson(data['data']);
          return cuartel.idEstadoCatastro == 3; // FINALIZADO
        }
        return false;
      } else {
        return false;
      }
    } catch (e) {
      logError('❌ Error al verificar catastro finalizado: $e');
      return false;
    }
  }

  // ===== MÉTODOS PARA REGISTRO MAPEO (NUEVA TABLA) =====

  // Obtener todos los registros de mapeo
  Future<List<RegistroMapeoSesion>> getRegistrosMapeo() async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/registromapeo/'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> registrosData;
        
        if (data is List) {
          registrosData = data;
        } else if (data['data'] != null) {
          registrosData = data['data'] as List<dynamic>;
        } else {
          return [];
        }
        
        return registrosData.map((json) => RegistroMapeoSesion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener registros de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener registros de mapeo: $e');
      throw Exception('Error al obtener registros de mapeo: $e');
    }
  }

  // Crear nuevo registro de mapeo (iniciar sesión de mapeo)
  Future<RegistroMapeoSesion> crearRegistroMapeoSesion(RegistroMapeoSesion registro) async {
    try {
      logInfo('📤 Creando registro de mapeo sesión...');
      
      // 🆕 Logging detallado de los datos que se van a enviar
      final datosAEnviar = registro.toJson();
      logInfo('📋 Datos a enviar: $datosAEnviar');
      logInfo('📋 JSON string: ${jsonEncode(datosAEnviar)}');
      
      final response = await _makeRequest(() async {
        return await http.post(
          Uri.parse('$baseUrl/registromapeo/'),
          headers: await _getHeaders(),
          body: jsonEncode(datosAEnviar),
        );
      });

      logInfo('📡 Respuesta crear registro mapeo: ${response.statusCode}');
      logInfo('📝 Body respuesta: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final registroCreado = RegistroMapeoSesion.fromJson(data);
        logInfo('✅ Registro de mapeo creado exitosamente: ${registroCreado.id}');
        return registroCreado;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        logError('❌ Error 400: ${errorData['error'] ?? 'Datos inválidos'}');
        throw Exception('Datos inválidos para crear registro de mapeo');
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        logError('❌ Error 422: ${errorData['error'] ?? 'Validación incorrecta'}');
        throw Exception('Validación incorrecta para crear registro de mapeo');
      } else if (response.statusCode == 500) {
        logError('❌ Error 500 del servidor al crear registro de mapeo');
        logError('📝 Body del error: ${response.body}');
        throw Exception('Error interno del servidor al crear registro de mapeo');
      } else {
        logError('❌ Error ${response.statusCode}: ${response.body}');
        throw Exception('Error al crear registro de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al crear registro de mapeo: $e');
      throw Exception('Error al crear registro de mapeo: $e');
    }
  }

  // Actualizar registro de mapeo
  Future<RegistroMapeoSesion> actualizarRegistroMapeoSesion(String id, RegistroMapeoSesion registro) async {
    try {
      logInfo('📤 Actualizando registro de mapeo $id...');
      
      final response = await _makeRequest(() async {
        return await http.put(
          Uri.parse('$baseUrl/registromapeo/$id'),
          headers: await _getHeaders(),
          body: jsonEncode(registro.toJson()),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final registroActualizado = RegistroMapeoSesion.fromJson(data);
        logInfo('✅ Registro de mapeo actualizado exitosamente');
        return registroActualizado;
      } else {
        throw Exception('Error al actualizar registro de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al actualizar registro de mapeo: $e');
      throw Exception('Error al actualizar registro de mapeo: $e');
    }
  }

  // Eliminar registro de mapeo
  Future<void> eliminarRegistroMapeoSesion(String id) async {
    try {
      logInfo('🗑️ Eliminando registro de mapeo $id...');
      
      final response = await _makeRequest(() async {
        return await http.delete(
          Uri.parse('$baseUrl/registromapeo/$id'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200 || response.statusCode == 204) {
        logInfo('✅ Registro de mapeo eliminado exitosamente');
      } else {
        throw Exception('Error al eliminar registro de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al eliminar registro de mapeo: $e');
      throw Exception('Error al eliminar registro de mapeo: $e');
    }
  }

  // Obtener registros de mapeo por cuartel
  Future<List<RegistroMapeoSesion>> getRegistrosMapeoPorCuartel(int cuartelId) async {
    try {
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/registromapeo/cuartel/$cuartelId'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> registrosData;
        
        if (data is List) {
          registrosData = data;
        } else if (data['data'] != null) {
          registrosData = data['data'] as List<dynamic>;
        } else {
          return [];
        }
        
        return registrosData.map((json) => RegistroMapeoSesion.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener registros de mapeo del cuartel: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al obtener registros de mapeo del cuartel: $e');
      throw Exception('Error al obtener registros de mapeo del cuartel: $e');
    }
  }

  // Finalizar registro de mapeo (actualizar estado a finalizado)
  Future<RegistroMapeoSesion> finalizarRegistroMapeoSesion(String id) async {
    try {
      logInfo('🏁 Finalizando registro de mapeo $id...');
      
      // Obtener el registro actual
      final response = await _makeRequest(() async {
        return await http.get(
          Uri.parse('$baseUrl/registromapeo/$id'),
          headers: await _getHeaders(),
        );
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final registroActual = RegistroMapeoSesion.fromJson(data);
        
        // 🆕 Corregir formato de fecha: YYYY-MM-DD en lugar de ISO 8601
        final now = DateTime.now();
        final fechaTermino = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        
        // Crear registro actualizado con fecha de término y estado finalizado
        final registroFinalizado = RegistroMapeoSesion(
          id: registroActual.id,
          idTemporada: registroActual.idTemporada,
          idCuartel: registroActual.idCuartel,
          fechaInicio: registroActual.fechaInicio,
          fechaTermino: fechaTermino, // 🆕 Formato YYYY-MM-DD
          idEstado: 4, // FINALIZADO
        );
        
        return await actualizarRegistroMapeoSesion(id, registroFinalizado);
      } else {
        throw Exception('Error al obtener registro de mapeo: ${response.statusCode}');
      }
    } catch (e) {
      logError('❌ Error al finalizar registro de mapeo: $e');
      throw Exception('Error al finalizar registro de mapeo: $e');
    }
  }
}
