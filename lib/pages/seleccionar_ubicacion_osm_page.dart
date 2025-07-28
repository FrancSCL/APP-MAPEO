import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/colors.dart';

class SeleccionarUbicacionOSMPage extends StatefulWidget {
  final String? ubicacionInicial;
  
  const SeleccionarUbicacionOSMPage({
    Key? key, 
    this.ubicacionInicial,
  }) : super(key: key);

  @override
  State<SeleccionarUbicacionOSMPage> createState() => _SeleccionarUbicacionOSMPageState();
}

class _SeleccionarUbicacionOSMPageState extends State<SeleccionarUbicacionOSMPage> {
  MapController? _mapController;
  LatLng _ubicacionActual = LatLng(-33.7837107, -70.739615); // Ubicación por defecto
  LatLng _ubicacionSeleccionada = LatLng(-33.7837107, -70.739615);
  List<Marker> _markers = [];
  bool _isLoading = true;
  final TextEditingController _coordenadasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _inicializarUbicacion();
  }

  Future<void> _inicializarUbicacion() async {
    try {
      // Si hay ubicación inicial, usarla
      if (widget.ubicacionInicial != null) {
        final coordenadas = _parsearCoordenadas(widget.ubicacionInicial!);
        if (coordenadas != null) {
          _ubicacionActual = coordenadas;
          _ubicacionSeleccionada = coordenadas;
        }
      } else {
        // Obtener ubicación actual del GPS
        await _obtenerUbicacionActual();
      }
      
      _actualizarMarcadores();
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

      setState(() {
        _ubicacionActual = LatLng(position.latitude, position.longitude);
        _ubicacionSeleccionada = _ubicacionActual;
      });

      // Mover mapa a la ubicación actual
      _mapController?.move(_ubicacionActual, 15);

    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

  LatLng? _parsearCoordenadas(String coordenadas) {
    try {
      final partes = coordenadas.split(',');
      if (partes.length != 2) return null;
      
      final lat = double.parse(partes[0].trim());
      final lng = double.parse(partes[1].trim());
      
      return LatLng(lat, lng);
    } catch (e) {
      return null;
    }
  }

  void _actualizarMarcadores() {
    setState(() {
      _markers = [
        Marker(
          point: _ubicacionSeleccionada,
          width: 80,
          height: 80,
          child: Column(
            children: [
              Icon(
                Icons.location_on,
                color: primaryGreen,
                size: 40,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Ubicación\nSeleccionada',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ];
    });
    
    // Actualizar el campo de texto
    _coordenadasController.text = '${_ubicacionSeleccionada.latitude.toStringAsFixed(7)}, ${_ubicacionSeleccionada.longitude.toStringAsFixed(7)}';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: errorColor,
      ),
    );
  }

  String _formatearCoordenadas(LatLng ubicacion) {
    return '${ubicacion.latitude.toStringAsFixed(7)},${ubicacion.longitude.toStringAsFixed(7)}';
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
          : Column(
              children: [
                // Mapa OpenStreetMap
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _ubicacionActual,
                          initialZoom: 15,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _ubicacionSeleccionada = point;
                            });
                            _actualizarMarcadores();
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app_mapeo',
                          ),
                          MarkerLayer(markers: _markers),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Panel de controles
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
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
                          final coordenadas = _parsearCoordenadas(value);
                          if (coordenadas != null) {
                            setState(() {
                              _ubicacionSeleccionada = coordenadas;
                            });
                            _actualizarMarcadores();
                            _mapController?.move(coordenadas, 15);
                          }
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
                              Row(
                                children: [
                                  Icon(Icons.map, color: primaryGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    'OpenStreetMap - 100% Gratuito',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Ubicación Seleccionada:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: primaryGreen),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lat: ${_ubicacionSeleccionada.latitude.toStringAsFixed(7)}',
                                      style: TextStyle(fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: primaryGreen),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lng: ${_ubicacionSeleccionada.longitude.toStringAsFixed(7)}',
                                      style: TextStyle(fontFamily: 'monospace'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
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
                              onPressed: () {
                                Navigator.pop(context, _formatearCoordenadas(_ubicacionSeleccionada));
                              },
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
              ],
            ),
    );
  }
} 