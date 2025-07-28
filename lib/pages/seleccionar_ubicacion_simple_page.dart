import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/colors.dart';

class SeleccionarUbicacionSimplePage extends StatefulWidget {
  final String? ubicacionInicial;
  
  const SeleccionarUbicacionSimplePage({
    Key? key, 
    this.ubicacionInicial,
  }) : super(key: key);

  @override
  State<SeleccionarUbicacionSimplePage> createState() => _SeleccionarUbicacionSimplePageState();
}

class _SeleccionarUbicacionSimplePageState extends State<SeleccionarUbicacionSimplePage> {
  String _ubicacionSeleccionada = '';
  bool _isLoading = true;
  final TextEditingController _coordenadasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _inicializarUbicacion();
  }

  Future<void> _inicializarUbicacion() async {
    try {
      if (widget.ubicacionInicial != null) {
        _ubicacionSeleccionada = widget.ubicacionInicial!;
        _coordenadasController.text = widget.ubicacionInicial!;
      } else {
        await _obtenerUbicacionActual();
      }
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error inicializando ubicación: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _obtenerUbicacionActual() async {
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

      final ubicacion = '${position.latitude},${position.longitude}';
      setState(() {
        _ubicacionSeleccionada = ubicacion;
        _coordenadasController.text = ubicacion;
      });

    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

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
      return false;
    }
  }

  String _formatearCoordenadas(String coordenadas) {
    try {
      final partes = coordenadas.split(',');
      if (partes.length != 2) {
        throw Exception('Formato de coordenadas inválido');
      }
      
      final lat = double.parse(partes[0].trim());
      final lng = double.parse(partes[1].trim());
      
      return '${lat.toStringAsFixed(7)},${lng.toStringAsFixed(7)}';
    } catch (e) {
      return coordenadas;
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

  @override
  void dispose() {
    _coordenadasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar Ubicación'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _obtenerUbicacionActual,
            tooltip: 'Mi ubicación actual',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Simulación de mapa
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 64,
                            color: primaryGreen,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Mapa de Google Maps',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Para usar el mapa interactivo,\nnecesitas configurar la API key de Google Maps',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.my_location),
                            label: Text('Obtener Mi Ubicación'),
                            onPressed: _obtenerUbicacionActual,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Campo de coordenadas
                  TextField(
                    controller: _coordenadasController,
                    decoration: InputDecoration(
                      labelText: 'Coordenadas GPS',
                      hintText: 'latitud,longitud',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.gps_fixed),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.content_paste),
                        onPressed: () {
                          // Aquí se podría implementar pegar desde portapapeles
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _ubicacionSeleccionada = value;
                      });
                    },
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Información de la ubicación
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicación Seleccionada:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          if (_ubicacionSeleccionada.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(Icons.location_on, color: primaryGreen),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _ubicacionSeleccionada,
                                    style: TextStyle(fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            if (_validarCoordenadas(_ubicacionSeleccionada))
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: successColor, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Formato válido',
                                    style: TextStyle(color: successColor),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.error, color: errorColor, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Formato inválido',
                                    style: TextStyle(color: errorColor),
                                  ),
                                ],
                              ),
                          ] else
                            Text(
                              'No se ha seleccionado ubicación',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.my_location),
                          label: Text('Mi Ubicación'),
                          onPressed: _obtenerUbicacionActual,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.check),
                          label: Text('Confirmar'),
                          onPressed: _ubicacionSeleccionada.isNotEmpty && _validarCoordenadas(_ubicacionSeleccionada)
                              ? () {
                                  Navigator.pop(context, _formatearCoordenadas(_ubicacionSeleccionada));
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: successColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
} 