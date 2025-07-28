import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cuartel.dart';
import '../models/hilera.dart';
import '../models/planta.dart';
import '../models/tipo_planta.dart';
import '../models/registro_mapeo.dart';

import '../services/api_service.dart';
import '../utils/colors.dart';

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

class MapeoPlantasPage extends StatefulWidget {
  final Cuartel cuartel;
  final RegistroMapeoSesion? registroMapeoSesion; // 🆕 Nuevo parámetro opcional
  
  const MapeoPlantasPage({
    Key? key, 
    required this.cuartel,
    this.registroMapeoSesion, // 🆕 Nuevo parámetro
  }) : super(key: key);

  @override
  State<MapeoPlantasPage> createState() => _MapeoPlantasPageState();
}

class _MapeoPlantasPageState extends State<MapeoPlantasPage> {
  List<Hilera> _hileras = [];
  List<Planta> _plantas = [];
  List<TipoPlanta> _tiposPlanta = [];
  List<RegistroMapeo> _registrosExistentes = [];
  
  bool _isLoading = true;
  int _hileraActualIndex = 0;
  int _plantaActualIndex = 0;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _mostrarInfoSesionMapeo(); // 🆕 Mostrar información de la sesión
  }

  // 🆕 Método para mostrar información de la sesión de mapeo
  void _mostrarInfoSesionMapeo() {
    if (widget.registroMapeoSesion != null) {
      logInfo('🆕 Sesión de mapeo iniciada: ${widget.registroMapeoSesion!.id}');
      logInfo('📅 Fecha inicio: ${widget.registroMapeoSesion!.fechaInicio}');
      logInfo('🏁 Estado: ${widget.registroMapeoSesion!.idEstado}');
      
      // Mostrar mensaje informativo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Sesión de mapeo iniciada - ID: ${widget.registroMapeoSesion!.id}'),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      logInfo("🔄 Cargando datos para mapeo...");
      
      // Cargar hileras del cuartel
      final hileras = await _apiService.getHilerasPorCuartel(widget.cuartel.id!);
      logInfo("✅ Hileras cargadas: ${hileras.length}");
      
      // Cargar tipos de planta
      final tiposPlanta = await _apiService.getTiposPlanta();
      logInfo("✅ Tipos de planta cargados: ${tiposPlanta.length}");
      
      setState(() {
        _hileras = hileras;
        _tiposPlanta = tiposPlanta;
        _isLoading = false;
      });
      
      // Cargar plantas de la primera hilera si hay hileras
      if (_hileras.isNotEmpty) {
        await _cargarPlantasHilera(_hileras[0].id);
      } else {
        logInfo("⚠️ No hay hileras configuradas en este cuartel");
      }
      
      logInfo("✅ Datos cargados: hileras=${_hileras.length}, tipos=${_tiposPlanta.length}");
    } catch (e) {
      logError("❌ Error al cargar datos: $e");
      setState(() => _isLoading = false);
      
      if (mounted) {
        String mensajeError = 'Error al cargar datos';
        
        // Mensajes más específicos según el error
        if (e.toString().contains('tipos de planta')) {
          mensajeError = 'Error al cargar tipos de planta. Verifica la conexión con el servidor.';
        } else if (e.toString().contains('hileras')) {
          mensajeError = 'Error al cargar hileras. Verifica que el cuartel tenga hileras configuradas.';
        } else if (e.toString().contains('Failed to fetch')) {
          mensajeError = 'Error de conexión. Verifica que el servidor esté funcionando.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text(mensajeError)),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _cargarPlantasHilera(int hileraId) async {
    try {
      final plantas = await _apiService.getPlantasPorHilera(hileraId);
      
      // Por ahora, no cargar registros existentes hasta que el backend esté listo
      // final registros = await _apiService.getRegistrosMapeoPorHilera(hileraId);
      
      setState(() {
        _plantas = plantas;
        _registrosExistentes = []; // Lista vacía por ahora
        _plantaActualIndex = 0;
      });
      
      logInfo("✅ Plantas cargadas: ${_plantas.length}, registros existentes: ${_registrosExistentes.length}");
    } catch (e) {
      logError("❌ Error al cargar plantas: $e");
      // En caso de error, mostrar plantas vacías
      setState(() {
        _plantas = [];
        _registrosExistentes = [];
        _plantaActualIndex = 0;
      });
    }
  }

  void _siguientePlanta() {
    if (_plantaActualIndex < _plantas.length - 1) {
      setState(() {
        _plantaActualIndex++;
      });
    } else {
      _siguienteHilera();
    }
  }

  void _plantaAnterior() {
    if (_plantaActualIndex > 0) {
      setState(() {
        _plantaActualIndex--;
      });
    } else {
      _hileraAnterior();
    }
  }

  void _siguienteHilera() {
    if (_hileraActualIndex < _hileras.length - 1) {
      setState(() {
        _hileraActualIndex++;
        _plantaActualIndex = 0;
      });
      _cargarPlantasHilera(_hileras[_hileraActualIndex].id);
    } else {
      // Mapeo completado
      _mostrarMapeoCompletado();
    }
  }

  void _hileraAnterior() {
    if (_hileraActualIndex > 0) {
      setState(() {
        _hileraActualIndex--;
      });
      _cargarPlantasHilera(_hileras[_hileraActualIndex].id);
    }
  }

  void _mostrarMapeoCompletado() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Mapeo Completado'),
          ],
        ),
        content: Text(
          '¡Felicidades! Has completado el mapeo del cuartel "${widget.cuartel.nombre}".',
        ),
          actions: [
          ElevatedButton(
            child: Text('Finalizar'),
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Volver a la página anterior
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _plantaYaMapeada(Planta planta) {
    return _registrosExistentes.any((registro) => registro.idPlanta == planta.id.toString());
  }

  Future<void> _registrarPlanta(Planta planta, TipoPlanta tipoPlanta) async {
    try {
      // Obtener ID del evaluador (usuario logueado)
      final prefs = await SharedPreferences.getInstance();
      final evaluadorId = prefs.getString('user_id') ?? '1';
      
      // Validar datos antes de crear el registro
      logInfo('🔍 Validando datos para registro:');
      logInfo('  - Planta ID: ${planta.id} (tipo: ${planta.id.runtimeType})');
      logInfo('  - Tipo Planta ID: ${tipoPlanta.id} (tipo: ${tipoPlanta.id.runtimeType})');
      logInfo('  - Evaluador ID: $evaluadorId');
      
      // Verificar que el ID del tipo de planta sea válido
      int idTipoPlanta;
      try {
        idTipoPlanta = int.parse(tipoPlanta.id);
        logInfo('✅ ID tipo planta convertido correctamente: $idTipoPlanta');
      } catch (e) {
        logError('❌ Error al convertir ID tipo planta: $e');
        throw Exception('ID de tipo de planta inválido: ${tipoPlanta.id}');
      }
      
      // Crear registro de mapeo
      final registro = RegistroMapeo(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporal
        idEvaluador: evaluadorId,
        horaRegistro: DateTime.now().toIso8601String(),
        idPlanta: planta.id.toString(), // Convertir a String para manejar bigint
        idTipoPlanta: idTipoPlanta,
        imagen: null, // Por ahora sin imagen
      );
      
      logInfo('📤 Enviando registro de mapeo: ${registro.toJson()}');
      
      // Guardar registro
      await _apiService.crearRegistroMapeo(registro);
      
      // Actualizar lista de registros
      setState(() {
        _registrosExistentes.add(registro);
      });
      
      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Planta registrada: ${tipoPlanta.nombre}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Pasar a la siguiente planta
      _siguientePlanta();
      
    } catch (e) {
      logError("❌ Error al registrar planta: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar planta: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  void _mostrarDialogoTipoPlanta(Planta planta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_florist, color: Colors.green),
            SizedBox(width: 8),
            Text('Seleccionar Tipo de Planta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Planta ${planta.planta} - Hilera ${_hileras[_hileraActualIndex].nombre ?? _hileras[_hileraActualIndex].hilera}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ..._tiposPlanta.map((tipo) => ListTile(
              leading: Icon(
                tipo.factorProductivo == 1.0 ? Icons.check_circle : 
                tipo.factorProductivo == 0.0 ? Icons.cancel : 
                Icons.info,
                color: tipo.factorProductivo == 1.0 ? Colors.green :
                       tipo.factorProductivo == 0.0 ? Colors.red : Colors.orange,
              ),
              title: Text(tipo.nombre),
              subtitle: Text(tipo.descripcion ?? ''),
              onTap: () {
                Navigator.pop(context);
                _registrarPlanta(planta, tipo);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Mapeo de Plantas'),
          backgroundColor: primaryGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            // 🆕 Botón para finalizar mapeo
            if (widget.registroMapeoSesion != null)
              IconButton(
                icon: Icon(Icons.stop_circle, color: Colors.white),
                onPressed: () => _finalizarMapeo(),
                tooltip: 'Finalizar mapeo',
              ),
            // Botón de prueba para diagnosticar
            IconButton(
              icon: Icon(Icons.bug_report, color: Colors.white),
              onPressed: () async {
                try {
                  await _apiService.probarRegistroMapeo();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Prueba completada - Revisa los logs'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error en prueba: $e'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Probar registro de mapeo',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando datos...',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_hileras.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text('Mapeo de Plantas'),
          backgroundColor: primaryGreen,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          actions: [
            // 🆕 Botón para finalizar mapeo
            if (widget.registroMapeoSesion != null)
              IconButton(
                icon: Icon(Icons.stop_circle, color: Colors.white),
                onPressed: () => _finalizarMapeo(),
                tooltip: 'Finalizar mapeo',
              ),
            // Botón de prueba para diagnosticar
            IconButton(
              icon: Icon(Icons.bug_report, color: Colors.white),
              onPressed: () async {
                try {
                  await _apiService.probarRegistroMapeo();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Prueba completada - Revisa los logs'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error en prueba: $e'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                }
              },
              tooltip: 'Probar registro de mapeo',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning,
                size: 80,
                color: Colors.orange.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'No hay hileras disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textSecondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Este cuartel no tiene hileras configuradas',
                style: TextStyle(
                  fontSize: 14,
                  color: textLight,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '¿Qué hacer?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Regresa al catastro y agrega hileras a este cuartel\n'
                      '2. Asegúrate de que el catastro esté finalizado\n'
                      '3. Luego podrás iniciar el mapeo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_back),
                label: Text('Volver al Catastro'),
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hileraActual = _hileras[_hileraActualIndex];
    final plantaActual = _plantas.isNotEmpty && _plantaActualIndex < _plantas.length 
        ? _plantas[_plantaActualIndex] 
        : null;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Mapeo de Plantas'),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // 🆕 Botón para finalizar mapeo
          if (widget.registroMapeoSesion != null)
            IconButton(
              icon: Icon(Icons.stop_circle, color: Colors.white),
              onPressed: () => _finalizarMapeo(),
              tooltip: 'Finalizar mapeo',
            ),
          // Botón de prueba para diagnosticar
          IconButton(
            icon: Icon(Icons.bug_report, color: Colors.white),
            onPressed: () async {
              try {
                await _apiService.probarRegistroMapeo();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Prueba completada - Revisa los logs'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error en prueba: $e'),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              }
            },
            tooltip: 'Probar registro de mapeo',
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _mostrarInformacionMapeo(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
              children: [
            // Header con información del cuartel y progreso
                Container(
              padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
                  ),
              child: Column(
                    children: [
                  // Información del cuartel
                  Text(
                    widget.cuartel.nombre ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Progreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                        'Hilera ${_hileraActualIndex + 1} de ${_hileras.length}',
                              style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                              ),
                            ),
                      if (plantaActual != null)
                              Text(
                          'Planta ${_plantaActualIndex + 1} de ${_plantas.length}',
                                style: TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Barra de progreso
                  LinearProgressIndicator(
                    value: (_hileraActualIndex * _plantas.length + _plantaActualIndex) / 
                           (_hileras.length * _plantas.length),
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                ],
              ),
            ),
            
            // Contenido principal
            Expanded(
              child: plantaActual != null
                  ? _buildPlantaCard(plantaActual, hileraActual)
                  : _buildHileraVacia(hileraActual),
            ),
            
            // Controles de navegación
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Botón anterior
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.arrow_back),
                      label: Text('Anterior'),
                      onPressed: _plantaActualIndex > 0 || _hileraActualIndex > 0
                          ? _plantaAnterior
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Botón siguiente
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.arrow_forward),
                      label: Text('Siguiente'),
                      onPressed: _plantaActualIndex < _plantas.length - 1 || _hileraActualIndex < _hileras.length - 1
                          ? _siguientePlanta
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPlantaCard(Planta planta, Hilera hilera) {
    final yaMapeada = _plantaYaMapeada(planta);
    final registro = _registrosExistentes.firstWhere(
      (r) => r.idPlanta == planta.id,
      orElse: () => RegistroMapeo(
        id: '',
        idEvaluador: '',
        horaRegistro: '',
        idPlanta: '',
        idTipoPlanta: 0,
      ),
    );
    
    final tipoPlanta = yaMapeada 
        ? _tiposPlanta.firstWhere(
            (t) => int.parse(t.id) == registro.idTipoPlanta,
            orElse: () => TipoPlanta(id: '0', nombre: 'Desconocido', factorProductivo: 0, idEmpresa: 1),
          )
        : null;

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        children: [
          // Card de la planta
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
                          child: Column(
                            children: [
                // Icono y estado
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: yaMapeada 
                        ? (tipoPlanta?.factorProductivo == 1.0 ? Colors.green : 
                           tipoPlanta?.factorProductivo == 0.0 ? Colors.red : Colors.orange)
                        .withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    yaMapeada ? Icons.check_circle : Icons.local_florist,
                    size: 48,
                    color: yaMapeada 
                        ? (tipoPlanta?.factorProductivo == 1.0 ? Colors.green : 
                           tipoPlanta?.factorProductivo == 0.0 ? Colors.red : Colors.orange)
                        : Colors.grey,
                  ),
                ),
                              SizedBox(height: 16),
                
                // Información de la planta
                              Text(
                  'Planta ${planta.planta}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                              ),
                              SizedBox(height: 8),
                                Text(
                  'Hilera: ${hilera.nombre ?? hilera.hilera}',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                                Text(
                  'Ubicación: ${planta.ubicacion}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textLight,
                                ),
                ),
                
                // Estado del mapeo
                SizedBox(height: 16),
                if (yaMapeada) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (tipoPlanta?.factorProductivo == 1.0 ? Colors.green : 
                             tipoPlanta?.factorProductivo == 0.0 ? Colors.red : Colors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: tipoPlanta?.factorProductivo == 1.0 ? Colors.green : 
                               tipoPlanta?.factorProductivo == 0.0 ? Colors.red : Colors.orange,
                      ),
                    ),
                                  child: Text(
                      tipoPlanta?.nombre ?? 'Desconocido',
                                    style: TextStyle(
                        fontSize: 14,
                                      fontWeight: FontWeight.bold,
                        color: tipoPlanta?.factorProductivo == 1.0 ? Colors.green : 
                               tipoPlanta?.factorProductivo == 0.0 ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                ),
                  SizedBox(height: 8),
                  Text(
                    tipoPlanta?.descripcion ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Pendiente de mapeo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                                ),
                ],
              ],
            ),
          ),
          
          // Botón de acción
          SizedBox(height: 16),
          if (!yaMapeada)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Seleccionar Tipo'),
                onPressed: () => _mostrarDialogoTipoPlanta(planta),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
                                        ),
                                      ],
                                    ),
    );
  }

  Widget _buildHileraVacia(Hilera hilera) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
                                        ),
          SizedBox(height: 16),
          Text(
            'Hilera sin plantas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'La hilera "${hilera.nombre ?? hilera.hilera}" no tiene plantas configuradas',
            style: TextStyle(
              fontSize: 14,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _siguienteHilera,
            child: Text('Siguiente Hilera'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
                        ),
                ),
              ],
            ),
    );
  }

  void _mostrarInformacionMapeo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Información del Mapeo'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipos de Planta:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._tiposPlanta.map((tipo) => Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    tipo.factorProductivo == 1.0 ? Icons.check_circle : 
                    tipo.factorProductivo == 0.0 ? Icons.cancel : 
                    Icons.info,
                    color: tipo.factorProductivo == 1.0 ? Colors.green :
                           tipo.factorProductivo == 0.0 ? Colors.red : Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('${tipo.nombre}: ${tipo.descripcion ?? ''}'),
                  ),
                ],
            ),
            )),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizarMapeo() async {
    if (widget.registroMapeoSesion == null) {
      logError("❌ No hay sesión de mapeo activa para finalizar.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay sesión de mapeo activa para finalizar.'),
            backgroundColor: errorColor,
          ),
        );
      }
      return;
    }

    try {
      logInfo("🔄 Finalizando sesión de mapeo...");
      await _apiService.finalizarRegistroMapeoSesion(widget.registroMapeoSesion!.id);
      logInfo("✅ Sesión de mapeo finalizada: ${widget.registroMapeoSesion!.id}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesión de mapeo finalizada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      Navigator.pop(context); // Volver a la página anterior
    } catch (e) {
      logError("❌ Error al finalizar sesión de mapeo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar sesión de mapeo: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }
} 