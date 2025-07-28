import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/cuartel.dart';
import '../models/variedad.dart';
import '../models/especie.dart';
import '../models/registro_mapeo.dart'; // 🆕 Importar para RegistroMapeoSesion
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'mapeo_plantas_page.dart';


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

class SeleccionarCuartelMapeoPage extends StatefulWidget {
  const SeleccionarCuartelMapeoPage({Key? key}) : super(key: key);

  @override
  State<SeleccionarCuartelMapeoPage> createState() => _SeleccionarCuartelMapeoPageState();
}

class _SeleccionarCuartelMapeoPageState extends State<SeleccionarCuartelMapeoPage> {
  List<Cuartel> _cuarteles = [];
  List<Cuartel> _cuartelesFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Variedad> _variedades = [];
  List<Especie> _especies = [];

  int? _especieSeleccionada;
  int? _variedadSeleccionada;
  int? _sucursalActivaId;

  int _paginaActual = 0;
  static const int _cuartelesPorPagina = 10;

  List<Cuartel> get _cuartelesPaginaActual {
    final inicio = _paginaActual * _cuartelesPorPagina;
    final fin = (inicio + _cuartelesPorPagina) > _cuartelesFiltrados.length
        ? _cuartelesFiltrados.length
        : (inicio + _cuartelesPorPagina);
    return _cuartelesFiltrados.sublist(inicio, fin);
  }

  void _cambiarPagina(int nuevaPagina) {
    setState(() {
      _paginaActual = nuevaPagina;
    });
  }

  // Cache para especies presentes
  List<Especie>? _especiesPresentesCache;
  
  // Devuelve solo las especies presentes en los cuarteles filtrados
  List<Especie> get _especiesPresentes {
    if (_especiesPresentesCache != null) return _especiesPresentesCache!;
    
    final idsEspecies = <int>{};
    for (final cuartel in _cuarteles) {
      final variedad = _variedades.firstWhere(
        (v) => v.id == (cuartel.idVariedad ?? 0), 
        orElse: () => Variedad(id: 0, nombre: '', idEspecie: 0, idForma: 0, idColor: 0)
      );
      if (variedad.idEspecie > 0) {
        idsEspecies.add(variedad.idEspecie);
      }
    }
    
    _especiesPresentesCache = _especies.where((e) => idsEspecies.contains(e.id)).toList();
    return _especiesPresentesCache!;
  }

  // Cache para variedades filtradas
  List<Variedad>? _variedadesFiltradasCache;
  
  // Devuelve solo las variedades presentes en los cuarteles filtrados y de la especie seleccionada
  List<Variedad> get _variedadesFiltradas {
    if (_variedadesFiltradasCache != null) return _variedadesFiltradasCache!;
    
    // Si no hay especie seleccionada, mostrar todas las variedades de los cuarteles actuales
    if (_especieSeleccionada == null) {
      final idsVariedades = <int>{};
      for (final cuartel in _cuarteles) {
        final idVariedad = cuartel.idVariedad ?? 0;
        if (idVariedad > 0) {
          idsVariedades.add(idVariedad);
        }
      }
      
      _variedadesFiltradasCache = _variedades
          .where((v) => idsVariedades.contains(v.id))
          .toList();
    } else {
      // Si hay especie seleccionada, filtrar por esa especie
      final idsVariedades = <int>{};
      for (final cuartel in _cuarteles) {
        final idVariedad = cuartel.idVariedad ?? 0;
        if (idVariedad > 0) {
          idsVariedades.add(idVariedad);
        }
      }
      
      _variedadesFiltradasCache = _variedades
          .where((v) => idsVariedades.contains(v.id) && v.idEspecie == _especieSeleccionada)
          .toList();
    }
    
    return _variedadesFiltradasCache!;
  }

  // Obtener solo cuarteles con catastro finalizado
  List<Cuartel> get _cuartelesFinalizados {
    return _cuarteles.where((cuartel) => 
      (cuartel.idEstadoCatastro ?? 0) == 3 // FINALIZADO
    ).toList();
  }

  // Cache para búsqueda
  Map<String, List<Cuartel>> _searchCache = {};
  
  void _filtrarCuarteles() {
    final searchText = _searchController.text.toLowerCase();
    final cacheKey = '${_especieSeleccionada}_${_variedadSeleccionada}_$searchText';
    
    // Verificar cache
    if (_searchCache.containsKey(cacheKey)) {
      setState(() {
        _cuartelesFiltrados = _searchCache[cacheKey]!;
        _paginaActual = 0;
      });
      return;
    }
    
    setState(() {
      _cuartelesFiltrados = _cuartelesFinalizados.where((cuartel) {
        // Filtro por nombre
        final coincideNombre = searchText.isEmpty ||
            (cuartel.nombre?.toLowerCase().contains(searchText) ?? false);
        
        // Filtro por especie
        bool coincideEspecie = true;
        if (_especieSeleccionada != null) {
          final variedad = _variedades.firstWhere(
            (v) => v.id == (cuartel.idVariedad ?? 0),
            orElse: () => Variedad(id: 0, nombre: '', idEspecie: 0, idForma: 0, idColor: 0),
          );
          coincideEspecie = variedad.idEspecie == _especieSeleccionada;
        }
        
        // Filtro por variedad
        final coincideVariedad = _variedadSeleccionada == null ||
            (cuartel.idVariedad ?? 0) == _variedadSeleccionada;
        
        return coincideNombre && coincideEspecie && coincideVariedad;
      }).toList();
      _paginaActual = 0;
      
      // Guardar en cache
      if (_searchCache.length > 20) {
        _searchCache.clear();
      }
      _searchCache[cacheKey] = _cuartelesFiltrados;
    });
  }

  void _aplicarFiltros() {
    _filtrarCuarteles();
  }

  void _limpiarFiltros() {
    _searchController.clear();
    _especieSeleccionada = null;
    _variedadSeleccionada = null;
    _variedadesFiltradasCache = null;
    _searchCache.clear();
    _aplicarFiltros();
  }

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      logInfo("🔄 Cargando datos para mapeo...");
      
      // Cargar todos los datos en paralelo
      final futures = await Future.wait([
        _apiService.getSucursalActiva(),
        _apiService.getCuartelesActivos(),
        _apiService.getVariedades(),
        _apiService.getEspecies(),
      ]);
      
      final sucursalActivaStr = futures[0] as String?;
      final cuarteles = futures[1] as List<Cuartel>;
      final variedades = futures[2] as List<Variedad>;
      final especies = futures[3] as List<Especie>;
      
      final sucursalActivaId = int.tryParse(sucursalActivaStr ?? '');
      
      setState(() {
        _sucursalActivaId = sucursalActivaId;
        _cuarteles = cuarteles.where((c) => c.idSucursal == _sucursalActivaId).toList();
        _variedades = variedades;
        _especies = especies;
        _isLoading = false;
      });
      
      _aplicarFiltros();
      
      logInfo("✅ Datos cargados para mapeo: cuarteles=${_cuarteles.length}, finalizados=${_cuartelesFinalizados.length}");
    } catch (e) {
      logError("❌ Error al cargar datos: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al cargar datos: $e')),
              ],
            ),
            backgroundColor: errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _seleccionarCuartel(Cuartel cuartel) async {
    try {
      // Verificar que el cuartel tenga catastro finalizado
      if (cuartel.idEstadoCatastro != 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Este cuartel no tiene catastro finalizado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 🆕 Mostrar diálogo de confirmación
      final bool? confirmarMapeo = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.map, color: Colors.blue),
                SizedBox(width: 8),
                Text('¿Comenzar mapeo?'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Quieres comenzar a mapear el cuartel:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuartel.nombre ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Estado: FINALIZADO',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Esto iniciará una nueva sesión de mapeo para este cuartel.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Comenzar Mapeo',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );

      // Si el usuario canceló, salir
      if (confirmarMapeo != true) {
        return;
      }

      // 🆕 Crear registro de mapeo antes de navegar
      try {
        logInfo('🆕 Creando registro de mapeo para cuartel: ${cuartel.nombre}');
        
        // Crear el registro de mapeo (asumiendo temporada 1 por defecto)
        final registroMapeo = RegistroMapeoSesion.crearParaIniciar(
          idTemporada: 1, // TODO: Obtener temporada actual del usuario
          idCuartel: cuartel.id ?? 0,
        );
        
        final registroCreado = await _apiService.crearRegistroMapeoSesion(registroMapeo);
        
        logInfo('✅ Registro de mapeo creado: ${registroCreado.id}');
        
        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sesión de mapeo iniciada correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        // Navegar a la página de mapeo con el registro creado
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapeoPlantasPage(
                cuartel: cuartel,
                registroMapeoSesion: registroCreado, // 🆕 Pasar el registro creado
              ),
            ),
          );
        }
        
      } catch (e) {
        logError('❌ Error al crear registro de mapeo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al iniciar sesión de mapeo: $e'),
              backgroundColor: errorColor,
            ),
          );
        }
      }
      
    } catch (e) {
      logError("❌ Error al seleccionar cuartel: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar cuartel: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Widget _buildCuartelCard(Cuartel cuartel) {
    final variedad = _variedades.firstWhere(
      (v) => v.id == (cuartel.idVariedad ?? 0),
      orElse: () => Variedad(id: 0, nombre: '', idEspecie: 0, idForma: 0, idColor: 0),
    );
    
    final especie = _especies.firstWhere(
      (e) => e.id == variedad.idEspecie,
      orElse: () => Especie(id: 0, nombre: '', cajaEquivalente: 0),
    );

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _seleccionarCuartel(cuartel),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cuartel.nombre ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'FINALIZADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Especie: ${especie.nombre}',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              Text(
                'Variedad: ${variedad.nombre}',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              if (cuartel.nHileras != null)
                Text(
                  'Hileras: ${cuartel.nHileras}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.map, color: Colors.orange, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Iniciar Mapeo',
                    style: TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Seleccionar Cuartel para Mapeo'),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando cuarteles finalizados...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _cuartelesFinalizados.isEmpty
              ? Center(
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
                        'No hay cuarteles disponibles para mapeo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Solo se muestran cuarteles con catastro finalizado',
                        style: TextStyle(
                          fontSize: 14,
                          color: textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filtros
                    Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Búsqueda
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Buscar cuartel...',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) => _aplicarFiltros(),
                          ),
                          SizedBox(height: 16),
                          // Filtros de especie y variedad
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _especieSeleccionada,
                                  decoration: InputDecoration(
                                    labelText: 'Especie',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: [
                                    DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('Todas las especies'),
                                    ),
                                    ..._especiesPresentes.map((especie) =>
                                      DropdownMenuItem<int>(
                                        value: especie.id,
                                        child: Text(especie.nombre),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _especieSeleccionada = value;
                                      _variedadSeleccionada = null;
                                    });
                                    _aplicarFiltros();
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _variedadSeleccionada,
                                  decoration: InputDecoration(
                                    labelText: 'Variedad',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  items: [
                                    DropdownMenuItem<int>(
                                      value: null,
                                      child: Text('Todas las variedades'),
                                    ),
                                    ..._variedadesFiltradas.map((variedad) =>
                                      DropdownMenuItem<int>(
                                        value: variedad.id,
                                        child: Text(variedad.nombre),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _variedadSeleccionada = value;
                                    });
                                    _aplicarFiltros();
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // Botón limpiar filtros
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(Icons.clear),
                                  label: Text('Limpiar Filtros'),
                                  onPressed: _limpiarFiltros,
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Lista de cuarteles
                    Expanded(
                      child: _cuartelesFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 80,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No se encontraron cuarteles',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Intenta con otros filtros',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textLight,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cuartelesPaginaActual.length,
                              itemBuilder: (context, index) {
                                return _buildCuartelCard(_cuartelesPaginaActual[index]);
                              },
                            ),
                    ),
                    // Paginación
                    if (_cuartelesFiltrados.length > _cuartelesPorPagina)
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left),
                              onPressed: _paginaActual > 0
                                  ? () => _cambiarPagina(_paginaActual - 1)
                                  : null,
                            ),
                            Text(
                              'Página ${_paginaActual + 1} de ${(_cuartelesFiltrados.length / _cuartelesPorPagina).ceil()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right),
                              onPressed: (_paginaActual + 1) * _cuartelesPorPagina < _cuartelesFiltrados.length
                                  ? () => _cambiarPagina(_paginaActual + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
    );
  }
} 