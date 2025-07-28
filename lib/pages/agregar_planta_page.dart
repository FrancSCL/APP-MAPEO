import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/hilera.dart';
import '../models/planta.dart';
import '../models/cuartel.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'seleccionar_ubicacion_osm_page.dart';

class AgregarPlantaPage extends StatefulWidget {
  final Hilera hilera;
  final Cuartel cuartel;
  
  const AgregarPlantaPage({
    Key? key, 
    required this.hilera, 
    required this.cuartel,
  }) : super(key: key);

  @override
  State<AgregarPlantaPage> createState() => _AgregarPlantaPageState();
}

class _AgregarPlantaPageState extends State<AgregarPlantaPage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String? _ubicacionGPS;
  String? _ubicacionSeleccionada;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _obtenerUbicacionActual();
    _sugerirSiguienteNumero();
  }

  // Sugerir el siguiente número de planta disponible
  Future<void> _sugerirSiguienteNumero() async {
    try {
      final plantas = await _apiService.getPlantasPorHilera(widget.hilera.id);
      int siguienteNumero = 1;
      
      if (plantas.isNotEmpty) {
        final maxNumero = plantas.map((p) => p.planta).reduce((a, b) => a > b ? a : b);
        siguienteNumero = maxNumero + 1;
      }
      
      if (mounted) {
        setState(() {
          _numeroController.text = siguienteNumero.toString();
        });
      }
    } catch (e) {
      // Si hay error, usar número 1 por defecto
      if (mounted) {
        setState(() {
          _numeroController.text = '1';
        });
      }
    }
  }

  // Validar formato de coordenadas
  bool _validarCoordenadas(String coordenadas) {
    try {
      final partes = coordenadas.split(',');
      if (partes.length != 2) return false;
      
      final lat = double.parse(partes[0].trim());
      final lng = double.parse(partes[1].trim());
      
      // Validar rangos de latitud y longitud
      if (lat < -90 || lat > 90) return false;
      if (lng < -180 || lng > 180) return false;
      
      return true;
    } catch (e) {
      print('❌ Error validando coordenadas: $e');
      return false;
    }
  }

  // Formatear coordenadas para el backend
  String _formatearCoordenadas(String coordenadas) {
    try {
      final partes = coordenadas.split(',');
      if (partes.length != 2) {
        throw Exception('Formato de coordenadas inválido');
      }
      
      final lat = double.parse(partes[0].trim());
      final lng = double.parse(partes[1].trim());
      
      // Formatear con 7 decimales máximo (precisión GPS)
      return '${lat.toStringAsFixed(7)},${lng.toStringAsFixed(7)}';
    } catch (e) {
      print('❌ Error formateando coordenadas: $e');
      return coordenadas; // Devolver original si hay error
    }
  }

  // Verificar si el número de planta ya existe
  Future<bool> _verificarNumeroExistente(int numero) async {
    try {
      final plantas = await _apiService.getPlantasPorHilera(widget.hilera.id);
      return plantas.any((p) => p.planta == numero);
    } catch (e) {
      return false; // Si hay error, permitir continuar
    }
  }

  // Verificar si la hilera es válida
  Future<bool> _verificarHileraValida() async {
    try {
      // Intentar obtener las plantas de la hilera para verificar que existe
      await _apiService.getPlantasPorHilera(widget.hilera.id);
      return true;
    } catch (e) {
      print('❌ Error verificando hilera: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  // Verificar si se puede agregar plantas según el estado del catastro
  bool _puedeAgregarPlantas() {
    final estadoCatastro = widget.cuartel.idEstadoCatastro ?? 0;
    return estadoCatastro == 1 || estadoCatastro == 2; // Sin catastro o Iniciado
  }

  // Obtener ubicación GPS actual
  Future<void> _obtenerUbicacionActual() async {
    setState(() => _isGettingLocation = true);
    
    try {
      // Verificar permisos
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _mostrarError('Los servicios de ubicación están deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarError('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarError('Permisos de ubicación permanentemente denegados');
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _ubicacionGPS = '${position.latitude},${position.longitude}';
        _ubicacionSeleccionada = _ubicacionGPS;
        _isGettingLocation = false;
      });

    } catch (e) {
      setState(() => _isGettingLocation = false);
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

  // Mostrar selector de ubicación en mapa
  Future<void> _mostrarSelectorUbicacion() async {
    final ubicacionSeleccionada = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarUbicacionOSMPage(
          ubicacionInicial: _ubicacionGPS,
        ),
      ),
    );
    
    if (ubicacionSeleccionada != null && mounted) {
      setState(() {
        _ubicacionSeleccionada = ubicacionSeleccionada;
      });
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: errorColor,
      ),
    );
  }

  Future<void> _agregarPlanta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ubicacionSeleccionada == null) {
      _mostrarError('Debe seleccionar una ubicación');
      return;
    }

    final numeroPlanta = int.parse(_numeroController.text);
    setState(() => _isLoading = true);

    try {
      // Mostrar progreso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              SizedBox(width: 8),
              Text('Agregando planta...'),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );

      final request = CrearPlantaRequest(
        idHilera: widget.hilera.id,
        planta: numeroPlanta,
        ubicacion: _formatearCoordenadas(_ubicacionSeleccionada!),
      );

      print('📤 Enviando request: ${request.toJson()}');

      // Usar método simple para diagnóstico
      await _apiService.crearPlantaSimple(
        widget.hilera.id,
        numeroPlanta,
        _formatearCoordenadas(_ubicacionSeleccionada!),
      );

      // Verificar y actualizar automáticamente el estado del catastro
      await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);

      if (!mounted) return;

      // Cerrar el snackbar de progreso
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Planta $numeroPlanta agregada correctamente'),
            ],
          ),
          backgroundColor: successColor,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // true indica que se agregó una planta

    } catch (e) {
      if (!mounted) return;
      
      // Cerrar el snackbar de progreso
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      print('❌ Error completo: $e');
      
      // Manejar errores específicos
      String mensajeError = 'Error al agregar planta';
      if (e.toString().contains('400')) {
        mensajeError = 'Datos inválidos. Verifique la información';
      } else if (e.toString().contains('409')) {
        mensajeError = 'Ya existe una planta con ese número';
      } else if (e.toString().contains('500')) {
        mensajeError = 'Error del servidor. Intente más tarde';
      } else if (e.toString().contains('conexión')) {
        mensajeError = 'Error de conexión. Verifique su internet';
      }
      
      _mostrarError('$mensajeError: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoCatastro = widget.cuartel.idEstadoCatastro ?? 0;
    final nombreEstado = _getNombreEstadoCatastro(estadoCatastro);
    final colorEstado = _getColorEstadoCatastro(estadoCatastro);

    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Planta - Hilera ${widget.hilera.hilera}'),
        backgroundColor: primaryGreen,
      ),
      body: !_puedeAgregarPlantas()
          ? _buildEstadoFinalizado()
          : _buildFormularioAgregarPlanta(nombreEstado, colorEstado),
    );
  }

  Widget _buildEstadoFinalizado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Catastro Finalizado',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'No se pueden agregar más plantas\na este cuartel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioAgregarPlanta(String nombreEstado, Color colorEstado) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado del catastro
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorEstado),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorEstado),
                  SizedBox(width: 8),
                  Text(
                    'Estado: $nombreEstado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorEstado,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Información del cuartel y hilera
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información del Cuartel',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Cuartel: ${widget.cuartel.nombre}'),
                    Text('Hilera: ${widget.hilera.hilera}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Número de planta
            TextFormField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Número de Planta',
                hintText: 'Ej: 1, 2, 3...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese el número de planta';
                }
                if (int.tryParse(value) == null) {
                  return 'Debe ser un número válido';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Ubicación GPS
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'Ubicación GPS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (_isGettingLocation)
                      Row(
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(width: 8),
                          Text('Obteniendo ubicación...'),
                        ],
                      )
                    else if (_ubicacionGPS != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación actual:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            _ubicacionGPS!,
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                          if (_ubicacionSeleccionada != _ubicacionGPS)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_location, color: primaryGreen, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Ubicación seleccionada manualmente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.refresh),
                                label: Text('Actualizar'),
                                onPressed: _obtenerUbicacionActual,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[300],
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              ElevatedButton.icon(
                                icon: Icon(Icons.map),
                                label: Text('Seleccionar en Mapa'),
                                onPressed: _mostrarSelectorUbicacion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        icon: Icon(Icons.location_on),
                        label: Text('Obtener ubicación'),
                        onPressed: _obtenerUbicacionActual,
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Botón agregar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isLoading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.add),
                label: Text(_isLoading ? 'Agregando...' : 'Agregar Planta'),
                onPressed: _isLoading ? null : _agregarPlanta,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getNombreEstadoCatastro(int estado) {
    switch (estado) {
      case 1:
        return 'Sin Catastro';
      case 2:
        return 'Iniciado';
      case 3:
        return 'Finalizado';
      default:
        return 'Desconocido';
    }
  }

  Color _getColorEstadoCatastro(int estado) {
    switch (estado) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
} 