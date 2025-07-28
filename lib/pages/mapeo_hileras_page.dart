import 'package:flutter/material.dart';
import '../models/hilera.dart';
import '../models/cuartel.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'plantas_hilera_page.dart';

class MapeoHilerasPage extends StatefulWidget {
  final Cuartel cuartel;
  const MapeoHilerasPage({Key? key, required this.cuartel}) : super(key: key);

  @override
  State<MapeoHilerasPage> createState() => _MapeoHilerasPageState();
}

class _MapeoHilerasPageState extends State<MapeoHilerasPage> {
  List<Hilera> _hileras = [];
  bool _isLoading = true;
  bool _hilerasRecienCreadas = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _cargarHileras();
  }

  // Verificar si se pueden modificar hileras según el estado del catastro
  bool _puedeModificarHileras() {
    final estadoCatastro = widget.cuartel.idEstadoCatastro ?? 0;
    return estadoCatastro == 1 || estadoCatastro == 2; // Sin catastro o Iniciado
  }

  Future<void> _cargarHileras() async {
    setState(() => _isLoading = true);
    try {
      final hileras = await _apiService.getHilerasPorCuartel(widget.cuartel.id ?? 0);
      setState(() {
        _hileras = hileras;
        _isLoading = false;
      });
      if (hileras.isEmpty && (widget.cuartel.nHileras == null || widget.cuartel.nHileras == 0)) {
        _preguntarCantidadHileras();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar hileras: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _preguntarCantidadHileras() async {
    // Verificar si se pueden modificar hileras
    if (!_puedeModificarHileras()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pueden agregar hileras en un catastro finalizado'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    
    int? cantidad;
    final controller = TextEditingController();
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Hileras del Cuartel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'El cuartel "${widget.cuartel.nombre}" no tiene hileras registradas.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '¿Cuántas hileras tiene este cuartel?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                controller: controller,
            keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ej: 10, 20, 50...',
                  labelText: 'Cantidad de hileras',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.list_alt),
                ),
            onChanged: (value) => cantidad = int.tryParse(value),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se crearán hileras numeradas del 1 al $cantidad',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Crear Hileras'),
              onPressed: () async {
                if (cantidad != null && cantidad! > 0) {
                  Navigator.pop(context);
                  await _guardarCantidadHileras(cantidad!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor ingresa una cantidad válida'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarCantidadHileras(int cantidad) async {
    // Verificar si se pueden modificar hileras
    if (!_puedeModificarHileras()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pueden agregar hileras en un catastro finalizado'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _apiService.agregarMultiplesHileras(widget.cuartel.id ?? 0, cantidad);
      
      // Verificar si son las primeras hileras del cuartel
      final hilerasCuartel = await _apiService.getHilerasPorCuartel(widget.cuartel.id ?? 0);
      if (hilerasCuartel.length == cantidad) {
        // Son las primeras hileras del cuartel, verificar si el estado es SIN CATASTRO (1)
        final estadoActual = widget.cuartel.idEstadoCatastro ?? 0;
        if (estadoActual == 1) {
          // Mantener en estado SIN CATASTRO hasta que se agregue la primera planta
          print('✅ Primeras hileras agregadas, manteniendo estado SIN CATASTRO (1)');
        }
      }
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Se crearon $cantidad hileras correctamente'),
          backgroundColor: successColor,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Refrescar la lista de hileras para mostrar las nuevas hileras
      await _cargarHileras();
      
      // Marcar que las hileras fueron recién creadas para mostrar indicador visual
      setState(() {
        _hilerasRecienCreadas = true;
      });
      
      // Ocultar el indicador después de 5 segundos
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _hilerasRecienCreadas = false;
          });
        }
      });
      
      // NO cerrar la página automáticamente, dejar que el usuario vea las hileras creadas
      // if (mounted) Navigator.of(context).pop();
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar hileras: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  Future<void> _agregarHilera() async {
    // Verificar si se pueden modificar hileras
    if (!_puedeModificarHileras()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pueden agregar hileras en un catastro finalizado'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    
    // Buscar el siguiente número de hilera disponible
    int siguienteNumero = 1;
    if (_hileras.isNotEmpty) {
      siguienteNumero = _hileras.map((h) => h.hilera).reduce((a, b) => a > b ? a : b) + 1;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar nueva hilera'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Siguiente número sugerido: $siguienteNumero'),
              SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Número de hilera',
                  labelText: 'Número de hilera',
                ),
                onChanged: (value) => siguienteNumero = int.tryParse(value) ?? siguienteNumero,
                controller: TextEditingController(text: siguienteNumero.toString()),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text('Agregar'),
              onPressed: () async {
                if (siguienteNumero > 0) {
                  try {
                    final request = CrearHileraRequest(
                      hilera: siguienteNumero,
                      idCuartel: widget.cuartel.id ?? 0,
                    );
                    await _apiService.crearHilera(request);
                    
                    // Verificar si es la primera hilera del cuartel
                    final hilerasCuartel = await _apiService.getHilerasPorCuartel(widget.cuartel.id ?? 0);
                    if (hilerasCuartel.length == 1) {
                      // Es la primera hilera del cuartel, verificar si el estado es SIN CATASTRO (1)
                      final estadoActual = widget.cuartel.idEstadoCatastro ?? 0;
                      if (estadoActual == 1) {
                        // Mantener en estado SIN CATASTRO hasta que se agregue la primera planta
                        print('✅ Primera hilera agregada, manteniendo estado SIN CATASTRO (1)');
                      }
                    }
                    
                    Navigator.pop(context);
                    await _cargarHileras();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hilera $siguienteNumero agregada correctamente'),
                        backgroundColor: successColor,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al agregar hilera: $e'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarUltimaHilera() async {
    // Verificar si se pueden modificar hileras
    if (!_puedeModificarHileras()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pueden eliminar hileras en un catastro finalizado'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }
    
    if (_hileras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay hileras para eliminar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Confirmar eliminación
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que quieres eliminar la última hilera (Hilera ${_hileras.last.hilera})? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        // Verificar si la hilera a eliminar tiene plantas
        final plantasHilera = await _apiService.getPlantasPorHilera(_hileras.last.id);
        final teniaPlantas = plantasHilera.isNotEmpty;
        
        await _apiService.eliminarHilera(_hileras.last.id);
        
        // Verificar y actualizar automáticamente el estado del catastro
        await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Última hilera eliminada correctamente'),
            backgroundColor: successColor,
          ),
        );
        await _cargarHileras();
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar hilera: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('Hileras de ${widget.cuartel.nombre ?? 'Cuartel'}'),
            if (_hilerasRecienCreadas) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Nuevas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: primaryGreen,
        actions: [
          // Botón para agregar hilera (solo si se pueden modificar hileras)
          if (_puedeModificarHileras())
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _agregarHilera,
            tooltip: 'Agregar hilera',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hileras.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay hileras registradas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _puedeModificarHileras()
                            ? 'Usa el botón + para agregar la primera hilera'
                            : 'Catastro finalizado - No se pueden agregar hileras',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Mensaje informativo cuando las hileras fueron recién creadas
                    if (_hilerasRecienCreadas)
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Se crearon ${_hileras.length} hileras correctamente. Puedes comenzar a mapear las plantas.',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Mensaje informativo cuando el catastro está finalizado
                    if (!_puedeModificarHileras())
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Catastro finalizado. No se pueden agregar ni eliminar hileras.',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                  itemCount: _hileras.length,
                  itemBuilder: (context, index) {
                    final hilera = _hileras[index];
                    final esUltimaHilera = index == _hileras.length - 1;
                    
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: esUltimaHilera ? Colors.orange[50] : 
                             (_hilerasRecienCreadas && index < _hileras.length) ? Colors.green[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: esUltimaHilera ? Colors.orange : 
                                         (_hilerasRecienCreadas && index < _hileras.length) ? Colors.green : primaryGreen,
                          child: Text(
                            '${hilera.hilera}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Hilera ${hilera.hilera}',
                          style: TextStyle(
                            fontWeight: esUltimaHilera ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: esUltimaHilera 
                            ? Text('Última hilera', style: TextStyle(color: Colors.orange[700]))
                            : (_hilerasRecienCreadas && index < _hileras.length)
                                ? Text('Recién creada', style: TextStyle(color: Colors.green[700]))
                            : null,
                        trailing: esUltimaHilera
                            ? (_puedeModificarHileras()
                            ? IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 28,
                                ),
                                onPressed: _eliminarUltimaHilera,
                              )
                                : Icon(
                                    Icons.lock,
                                    color: Colors.red[400],
                                    size: 20,
                                  ))
                            : Icon(
                                Icons.lock,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                        onTap: () async {
                          final resultado = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlantasHileraPage(
                                cuartel: widget.cuartel,
                                hilera: hilera,
                              ),
                            ),
                          );
                          // Si se modificaron plantas, verificar estado del catastro
                          if (resultado == true) {
                            await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
                          }
                        },
                      ),
                    );
                  },
                ),
                      ),
                  ],
                ),
    );
  }
} 