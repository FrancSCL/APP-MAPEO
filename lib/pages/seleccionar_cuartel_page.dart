import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/cuartel.dart';
import '../models/variedad.dart';
import '../models/especie.dart';
import '../models/hilera.dart';
import '../models/planta.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'mapeo_hileras_page.dart';

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

class SeleccionarCuartelPage extends StatefulWidget {
  const SeleccionarCuartelPage({Key? key}) : super(key: key);

  @override
  State<SeleccionarCuartelPage> createState() => _SeleccionarCuartelPageState();
}

class _SeleccionarCuartelPageState extends State<SeleccionarCuartelPage> with SingleTickerProviderStateMixin {
  List<Cuartel> _cuarteles = [];
  List<Cuartel> _cuartelesFiltrados = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();

  List<Variedad> _variedades = [];
  List<Especie> _especies = [];

  int? _especieSeleccionada;
  int? _variedadSeleccionada;
  int? _sucursalActivaId;

  int _paginaActual = 0;
  static const int _cuartelesPorPagina = 10;
  
  // Mapa para almacenar qué cuarteles tienen todas las hileras con plantas
  Map<int, bool> _cuartelesConTodasHilerasCompletas = {};
  
  // Controlador para las tabs
  late TabController _tabController;
  int _tabSeleccionada = 0;

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
  
  // Cache persistente para verificación de cuarteles completos
  Map<int, bool> _cuartelesCompletosCache = {};
  DateTime? _lastVerificacionCompletos;
  static const Duration _cacheValidity = Duration(minutes: 5); // Cache válido por 5 minutos

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
  int? _lastEspecieSeleccionada;
  int? _lastTabSeleccionada;

  // Devuelve solo las variedades presentes en los cuarteles filtrados y de la especie seleccionada
  List<Variedad> get _variedadesFiltradas {
    // Verificar si el cache es válido
    if (_variedadesFiltradasCache != null && 
        _lastEspecieSeleccionada == _especieSeleccionada &&
        _lastTabSeleccionada == _tabSeleccionada) {
      return _variedadesFiltradasCache!;
    }
    
    // Si no hay especie seleccionada, mostrar todas las variedades de los cuarteles actuales
    if (_especieSeleccionada == null) {
      final idsVariedades = <int>{};
      for (final cuartel in _cuartelesTabActual) {
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
      for (final cuartel in _cuartelesTabActual) {
        final idVariedad = cuartel.idVariedad ?? 0;
        if (idVariedad > 0) {
          idsVariedades.add(idVariedad);
        }
      }
      
      _variedadesFiltradasCache = _variedades
          .where((v) => idsVariedades.contains(v.id) && v.idEspecie == _especieSeleccionada)
          .toList();
    }
    
    // Actualizar cache keys
    _lastEspecieSeleccionada = _especieSeleccionada;
    _lastTabSeleccionada = _tabSeleccionada;
    
    // Si la variedad seleccionada ya no está disponible, limpiarla
    if (_variedadSeleccionada != null && !_variedadesFiltradasCache!.any((v) => v.id == _variedadSeleccionada)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _variedadSeleccionada = null;
        });
      });
    }
    
    return _variedadesFiltradasCache!;
  }

  // Verificar cuarteles completos en background (no bloquea la UI)
  void _verificarCuartelesCompletosEnBackground() {
    // Ejecutar en background sin bloquear la UI
    Future.microtask(() async {
      try {
        // Verificar si el cache es válido
        if (_lastVerificacionCompletos != null && 
            DateTime.now().difference(_lastVerificacionCompletos!) < _cacheValidity) {
          logInfo("✅ Usando cache de verificación de cuarteles completos");
          if (mounted) {
            setState(() {
              _cuartelesConTodasHilerasCompletas = Map.from(_cuartelesCompletosCache);
            });
          }
          return;
        }
        
        logInfo("🔄 Verificando cuarteles completos en background...");
        final Map<int, bool> cuartelesCompletos = {};
        
        // Cache para evitar llamadas repetidas
        final Map<int, List<Hilera>> hilerasCache = {};
        final Map<int, List<Planta>> plantasCache = {};
        
        for (final cuartel in _cuarteles) {
          if (cuartel.id != null) {
            try {
              // Obtener hileras del cuartel (usar cache si está disponible)
              List<Hilera> hileras;
              if (hilerasCache.containsKey(cuartel.id)) {
                hileras = hilerasCache[cuartel.id]!;
              } else {
                hileras = await _apiService.getHilerasPorCuartel(cuartel.id!);
                hilerasCache[cuartel.id!] = hileras;
              }
              
              if (hileras.isEmpty) {
                cuartelesCompletos[cuartel.id!] = false;
                continue;
              }
              
              // Verificar si todas las hileras tienen plantas
              bool todasTienenPlantas = true;
              for (final hilera in hileras) {
                List<Planta> plantas;
                if (plantasCache.containsKey(hilera.id)) {
                  plantas = plantasCache[hilera.id]!;
                } else {
                  plantas = await _apiService.getPlantasPorHilera(hilera.id);
                  plantasCache[hilera.id] = plantas;
                }
                
                if (plantas.isEmpty) {
                  todasTienenPlantas = false;
                  break;
                }
              }
              
              cuartelesCompletos[cuartel.id!] = todasTienenPlantas;
            } catch (e) {
              logError("❌ Error verificando cuartel ${cuartel.id}: $e");
              cuartelesCompletos[cuartel.id!] = false;
            }
          }
        }
        
        // Actualizar cache persistente
        _cuartelesCompletosCache = Map.from(cuartelesCompletos);
        _lastVerificacionCompletos = DateTime.now();
        
        // Actualizar UI solo si el widget sigue montado
        if (mounted) {
          setState(() {
            _cuartelesConTodasHilerasCompletas = cuartelesCompletos;
          });
        }
        
        logInfo("✅ Verificación completada en background: ${cuartelesCompletos.length} cuarteles procesados");
      } catch (e) {
        logError("❌ Error al verificar cuarteles completos en background: $e");
      }
    });
  }

  // Obtener cuarteles por estado de catastro
  List<Cuartel> _getCuartelesPorEstado(int estadoCatastro) {
    return _cuarteles.where((cuartel) => 
      (cuartel.idEstadoCatastro ?? 0) == estadoCatastro
    ).toList();
  }

  // Obtener cuarteles para la tab actual
  List<Cuartel> get _cuartelesTabActual {
    switch (_tabSeleccionada) {
      case 0: // TODOS - Ordenar: Iniciado, Sin catastro, Finalizado
        return _cuarteles.where((cuartel) {
          final estado = cuartel.idEstadoCatastro ?? 1;
          return estado == 2; // Solo iniciados
        }).toList()
          ..addAll(_cuarteles.where((cuartel) {
            final estado = cuartel.idEstadoCatastro ?? 1;
            return estado == 1; // Solo sin catastro
          }))
          ..addAll(_cuarteles.where((cuartel) {
            final estado = cuartel.idEstadoCatastro ?? 1;
            return estado == 3; // Solo finalizados
          }));
      case 1: // SIN CATASTRO
        return _getCuartelesPorEstado(1);
      case 2: // INICIADO
        return _getCuartelesPorEstado(2);
      case 3: // FINALIZADO
        return _getCuartelesPorEstado(3);
      default:
        return _cuarteles;
    }
  }

  // Cache para búsqueda
  String _lastSearchText = '';
  Map<String, List<Cuartel>> _searchCache = {};

  void _filtrarCuartelesAvanzado() {
    final searchText = _searchController.text.toLowerCase();
    final cacheKey = '${_tabSeleccionada}_${_especieSeleccionada}_${_variedadSeleccionada}_$searchText';
    
    // Verificar cache
    if (_searchCache.containsKey(cacheKey)) {
    setState(() {
        _cuartelesFiltrados = _searchCache[cacheKey]!;
        _paginaActual = 0;
      });
      return;
    }
    
    setState(() {
      _cuartelesFiltrados = _cuartelesTabActual.where((cuartel) {
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
      _paginaActual = 0; // Reiniciar a la primera página al filtrar
      
      // Guardar en cache (limitar tamaño del cache)
      if (_searchCache.length > 20) {
        _searchCache.clear();
      }
      _searchCache[cacheKey] = _cuartelesFiltrados;
    });
  }

  void _aplicarFiltros() {
    // Limpiar filtros cuando se cambia de tab
    if (_tabSeleccionada != _tabController.index) {
      _limpiarFiltros();
    }
    _filtrarCuartelesAvanzado();
  }

  void _limpiarFiltros() {
    _searchController.clear();
    _especieSeleccionada = null;
    _variedadSeleccionada = null;
    
    // Limpiar caches relacionados
    _variedadesFiltradasCache = null;
    _searchCache.clear();
  }

  Especie? _especiePorId(int? id) {
    return _especies.firstWhere((e) => e.id == id, orElse: () => Especie(id: 0, nombre: '', cajaEquivalente: 0));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabSeleccionada = _tabController.index;
        });
        _aplicarFiltros();
      }
    });
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Verificar qué cuarteles tienen todas las hileras con plantas
  Future<void> _verificarCuartelesCompletos() async {
    try {
      // Verificar si el cache es válido
      if (_lastVerificacionCompletos != null && 
          DateTime.now().difference(_lastVerificacionCompletos!) < _cacheValidity) {
        logInfo("✅ Usando cache de verificación de cuarteles completos");
      setState(() {
          _cuartelesConTodasHilerasCompletas = Map.from(_cuartelesCompletosCache);
        });
        return;
      }
      
      logInfo("🔄 Verificando cuarteles completos...");
      final Map<int, bool> cuartelesCompletos = {};
      
      // Cache para evitar llamadas repetidas
      final Map<int, List<Hilera>> hilerasCache = {};
      final Map<int, List<Planta>> plantasCache = {};
      
      for (final cuartel in _cuarteles) {
        if (cuartel.id != null) {
          try {
            // Obtener hileras del cuartel (usar cache si está disponible)
            List<Hilera> hileras;
            if (hilerasCache.containsKey(cuartel.id)) {
              hileras = hilerasCache[cuartel.id]!;
            } else {
              hileras = await _apiService.getHilerasPorCuartel(cuartel.id!);
              hilerasCache[cuartel.id!] = hileras;
            }
            
            if (hileras.isEmpty) {
              cuartelesCompletos[cuartel.id!] = false;
              continue;
            }
            
            // Verificar si todas las hileras tienen plantas
            bool todasTienenPlantas = true;
            for (final hilera in hileras) {
              List<Planta> plantas;
              if (plantasCache.containsKey(hilera.id)) {
                plantas = plantasCache[hilera.id]!;
              } else {
                plantas = await _apiService.getPlantasPorHilera(hilera.id);
                plantasCache[hilera.id] = plantas;
              }
              
              if (plantas.isEmpty) {
                todasTienenPlantas = false;
                break;
              }
            }
            
            cuartelesCompletos[cuartel.id!] = todasTienenPlantas;
    } catch (e) {
            logError("❌ Error verificando cuartel ${cuartel.id}: $e");
            cuartelesCompletos[cuartel.id!] = false;
          }
        }
      }
      
      // Actualizar cache persistente
      _cuartelesCompletosCache = Map.from(cuartelesCompletos);
      _lastVerificacionCompletos = DateTime.now();
      
      setState(() {
        _cuartelesConTodasHilerasCompletas = cuartelesCompletos;
      });
      
      logInfo("✅ Verificación completada: ${cuartelesCompletos.length} cuarteles procesados");
    } catch (e) {
      logError("❌ Error al verificar cuarteles completos: $e");
    }
  }

  // Limpiar todos los caches
  void _limpiarTodosLosCaches() {
    _especiesPresentesCache = null;
    _variedadesFiltradasCache = null;
    _searchCache.clear();
    _nombreVariedadCache.clear();
    _nombreEspecieCache.clear();
    _invalidarCacheCompletos();
  }
  
  // Invalidar cache de cuarteles completos
  void _invalidarCacheCompletos() {
    _cuartelesCompletosCache.clear();
    _lastVerificacionCompletos = null;
  }
  
  // Finalizar catastro de un cuartel
  Future<void> _verificarYFinalizarCatastro(Cuartel cuartel) async {
    try {
      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Finalizar Catastro'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres finalizar el catastro del cuartel "${cuartel.nombre}"?',
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se verificará que todas las hileras tengan al menos una planta antes de finalizar.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                '⚠️ Una vez finalizado, no se podrán agregar más plantas.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            ElevatedButton(
              child: Text('Verificar y Finalizar'),
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (confirmar != true) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Verificando hileras...'),
            ],
          ),
        ),
      );

      // Verificar si todas las hileras tienen plantas
      final todasTienenPlantas = await _apiService.todasLasHilerasTienenPlantas(cuartel.id ?? 0);
      
      // Cerrar diálogo de carga
      Navigator.pop(context);

      if (todasTienenPlantas) {
        // Finalizar el catastro
        await _apiService.actualizarEstadoCatastro(cuartel.id ?? 0, 3);
        
        // Invalidar cache y recargar los datos
        _invalidarCacheCompletos();
        await _cargarDatos();
        
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                  Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                  Text('¡Catastro finalizado exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning, color: Colors.white),
                  SizedBox(width: 8),
                  Text('No se puede finalizar. Algunas hileras no tienen plantas.'),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al finalizar catastro: $e'),
            backgroundColor: errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cargarCuarteles() async {
    // Evitar múltiples recargas simultáneas
    if (_isLoading) return;
    
    // Guardar el estado actual de los filtros
    final searchText = _searchController.text;
    final especieSeleccionada = _especieSeleccionada;
    final variedadSeleccionada = _variedadSeleccionada;
    final tabSeleccionada = _tabSeleccionada;
    
    try {
      // Recargar datos sin verificar cuarteles completos para mayor velocidad
      await _cargarDatos(verificarCompletos: false);
      
      // Restaurar el estado de los filtros después de la recarga
      if (mounted) {
        setState(() {
          _searchController.text = searchText;
          _especieSeleccionada = especieSeleccionada;
          _variedadSeleccionada = variedadSeleccionada;
          _tabSeleccionada = tabSeleccionada;
          
          // Asegurar que el TabController esté sincronizado
          if (_tabController.index != tabSeleccionada) {
            _tabController.animateTo(tabSeleccionada);
          }
        });
        
        // Aplicar filtros con el estado restaurado
        _filtrarCuartelesAvanzado();
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Datos actualizados correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      logError("❌ Error al recargar cuarteles: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Error al actualizar datos: $e')),
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

  void _filtrarCuarteles(String query) {
    setState(() {
      if (query.isEmpty) {
        _cuartelesFiltrados = _cuarteles;
      } else {
        _cuartelesFiltrados = _cuarteles
            .where((cuartel) =>
                (cuartel.nombre?.toLowerCase().contains(query.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  void _seleccionarCuartel(Cuartel cuartel) {
    logInfo("🎯 Cuartel seleccionado: ${cuartel.nombre ?? 'Sin nombre'}");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapeoHilerasPage(cuartel: cuartel),
      ),
    ).then((_) async {
      // Al regresar de mapear hileras, verificar si se completaron cuarteles
      if (mounted) {
        await _verificarCuartelesCompletos();
        // También verificar y actualizar el estado del catastro
        await _apiService.verificarYActualizarEstadoCatastro(cuartel.id ?? 0);
        // Recargar los datos para mostrar el estado actualizado
        await _cargarDatos();
      }
    });
  }

  String _nombreEstadoCatastro(int? id) {
    switch (id) {
      case 1:
        return 'Sin catastro';
      case 2:
        return 'Catastro iniciado';
      case 3:
        return 'Catastro finalizado';
      default:
        return 'Desconocido';
    }
  }

  Color _colorEstadoCatastro(int? id) {
    switch (id) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.blueAccent;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Cache para nombres
  Map<int, String> _nombreVariedadCache = {};
  Map<int, String> _nombreEspecieCache = {};

  String _nombreVariedad(int idVariedad) {
    if (_nombreVariedadCache.containsKey(idVariedad)) {
      return _nombreVariedadCache[idVariedad]!;
    }
    
    final variedad = _variedades.firstWhere(
      (v) => v.id == idVariedad,
      orElse: () => Variedad(id: 0, nombre: 'Desconocida', idEspecie: 0, idForma: 0, idColor: 0),
    );
    
    _nombreVariedadCache[idVariedad] = variedad.nombre;
    return variedad.nombre;
  }

  String _nombreEspecie(int idVariedad) {
    if (_nombreEspecieCache.containsKey(idVariedad)) {
      return _nombreEspecieCache[idVariedad]!;
    }
    
    final variedad = _variedades.firstWhere(
      (v) => v.id == idVariedad,
      orElse: () => Variedad(id: 0, nombre: '', idEspecie: 0, idForma: 0, idColor: 0),
    );
    final especie = _especies.firstWhere(
      (e) => e.id == variedad.idEspecie,
      orElse: () => Especie(id: 0, nombre: 'Desconocida', cajaEquivalente: 0),
    );
    
    _nombreEspecieCache[idVariedad] = especie.nombre;
    return especie.nombre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Seleccionar Cuartel',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: _isLoading ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ) : Icon(Icons.refresh),
            onPressed: _isLoading ? null : _cargarCuarteles,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          tabs: [
            Tab(
              child: Text('TODOS\n(${_cuarteles.length})', textAlign: TextAlign.center),
            ),
            Tab(
              child: Text('SIN CAT.\n(${_getCuartelesPorEstado(1).length})', textAlign: TextAlign.center),
            ),
            Tab(
              child: Text('INICIADO\n(${_getCuartelesPorEstado(2).length})', textAlign: TextAlign.center),
            ),
            Tab(
              child: Text('FINALIZ.\n(${_getCuartelesPorEstado(3).length})', textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Filtros avanzados
            Container(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Filtros en una sola fila para móviles pequeños
                  Row(
              children: [
                // Filtro especie
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _especieSeleccionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Especie',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text('Todas las especies'),
                      ),
                      ..._especiesPresentes.map((e) => DropdownMenuItem<int>(
                            value: e.id,
                            child: Text(e.nombre),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _especieSeleccionada = value;
                        _variedadSeleccionada = null;
                      });
                      _filtrarCuartelesAvanzado();
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Filtro variedad
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _variedadSeleccionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Variedad',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                    ),
                    items: [
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text('Todas las variedades'),
                      ),
                      ..._variedadesFiltradas.map((v) => DropdownMenuItem<int>(
                            value: v.id,
                            child: Text(v.nombre),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _variedadSeleccionada = value;
                      });
                      _filtrarCuartelesAvanzado();
                    },
                  ),
                ),
              ],
            ),
                  SizedBox(height: 8),
          // Barra de búsqueda
                  TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cuartel...',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarCuartelesAvanzado();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: backgroundColor,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      isDense: true,
              ),
              onChanged: (value) => _filtrarCuartelesAvanzado(),
                  ),
                ],
            ),
          ),
          // Contenido principal
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _cuartelesFiltrados.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          Expanded(child: _buildCuartelesList()),
                          _buildPaginacion(),
                        ],
                      ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
          ),
          SizedBox(height: 16),
          Text(
            'Cargando cuarteles...',
            style: TextStyle(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String titulo;
    String subtitulo;
    IconData icono;
    Color colorIcono;

    if (_searchController.text.isNotEmpty) {
      titulo = 'No se encontraron cuarteles';
      subtitulo = 'Intenta con otro término de búsqueda';
      icono = Icons.search_off;
      colorIcono = Colors.grey;
    } else {
      switch (_tabSeleccionada) {
        case 0: // TODOS
          titulo = 'No hay cuarteles disponibles';
          subtitulo = 'Contacta al administrador para agregar cuarteles';
          icono = Icons.agriculture;
          colorIcono = Colors.grey;
          break;
        case 1: // SIN CATASTRO
          titulo = 'No hay cuarteles sin catastro';
          subtitulo = 'Todos los cuarteles tienen catastro iniciado o finalizado';
          icono = Icons.pending;
          colorIcono = Colors.orange;
          break;
        case 2: // INICIADO
          titulo = 'No hay cuarteles con catastro iniciado';
          subtitulo = 'Los cuarteles están sin catastro o ya finalizados';
          icono = Icons.play_circle;
          colorIcono = Colors.blue;
          break;
        case 3: // FINALIZADO
          titulo = 'No hay cuarteles finalizados';
          subtitulo = 'Ningún cuartel ha completado su catastro';
          icono = Icons.check_circle;
          colorIcono = Colors.green;
          break;
        default:
          titulo = 'No hay cuarteles disponibles';
          subtitulo = 'Contacta al administrador para agregar cuarteles';
          icono = Icons.agriculture;
          colorIcono = Colors.grey;
      }
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icono,
            size: 80,
            color: colorIcono.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 14,
              color: textLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty) ...[
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _filtrarCuartelesAvanzado();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Limpiar búsqueda'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCuartelesList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _cuartelesPaginaActual.length,
      itemBuilder: (context, index) {
        final cuartel = _cuartelesPaginaActual[index];
        return _buildCuartelCard(cuartel);
      },
      // Optimización: mantener widgets en memoria
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
    );
  }

  Widget _buildCuartelCard(Cuartel cuartel) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
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
      // Optimización: evitar reconstrucciones innecesarias
      key: ValueKey(cuartel.id),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _seleccionarCuartel(cuartel),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre grande
                Text(
                  cuartel.nombre ?? 'Sin nombre',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                // Variedad y especie
                Text(
                  'Variedad: ${_nombreVariedad(cuartel.idVariedad ?? 0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  'Especie: ${_nombreEspecie(cuartel.idVariedad ?? 0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Número de hileras o mensaje si no hay
                    _buildInfoChip(
                      icon: Icons.straighten,
                      label: cuartel.nHileras != null
                          ? '${cuartel.nHileras} hileras'
                          : 'Sin hileras asignadas',
                      color: Colors.orange,
                    ),
                    SizedBox(width: 8),
                    // Estado catastro
                    _buildInfoChip(
                      icon: Icons.info_outline,
                      label: _nombreEstadoCatastro(cuartel.idEstadoCatastro ?? 0),
                      color: _colorEstadoCatastro(cuartel.idEstadoCatastro ?? 0),
                    ),
                  ],
                ),
                // Indicador de progreso de hileras (solo si está iniciado)
                if (cuartel.idEstadoCatastro == 2 && cuartel.id != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          _cuartelesConTodasHilerasCompletas[cuartel.id] == true
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: _cuartelesConTodasHilerasCompletas[cuartel.id] == true
                              ? Colors.green
                              : Colors.orange,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _cuartelesConTodasHilerasCompletas[cuartel.id] == true
                              ? 'Todas las hileras tienen plantas'
                              : 'Algunas hileras sin plantas',
                          style: TextStyle(
                            fontSize: 12,
                            color: _cuartelesConTodasHilerasCompletas[cuartel.id] == true
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Botón para finalizar catastro (solo si está iniciado Y todas las hileras tienen plantas)
                if (cuartel.idEstadoCatastro == 2 && 
                    cuartel.id != null && 
                    _cuartelesConTodasHilerasCompletas[cuartel.id] == true)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.check_circle, size: 18),
                        label: Text('Finalizar Catastro'),
                        onPressed: () => _verificarYFinalizarCatastro(cuartel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginacion() {
    final totalPaginas = (_cuartelesFiltrados.length / _cuartelesPorPagina).ceil();
    if (totalPaginas <= 1) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _paginaActual > 0 ? () => _cambiarPagina(_paginaActual - 1) : null,
          ),
          Text('Página ${_paginaActual + 1} de $totalPaginas'),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _paginaActual < totalPaginas - 1 ? () => _cambiarPagina(_paginaActual + 1) : null,
          ),
        ],
      ),
    );
  }

  Future<void> _cargarDatos({bool verificarCompletos = true}) async {
    setState(() => _isLoading = true);
    try {
      logInfo("🔄 Cargando datos en paralelo...");
      
      // Cargar todos los datos en paralelo para mayor velocidad
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
        
        // Limpiar caches cuando se recargan los datos
        _limpiarTodosLosCaches();
      });
      
      // Aplicar filtros inmediatamente para mostrar datos rápido
      _aplicarFiltros();
      
      // Verificar cuarteles completos en background (no bloquear la UI)
      if (verificarCompletos) {
        _verificarCuartelesCompletosEnBackground();
      }
      
      logInfo("✅ Datos cargados: cuarteles=${_cuarteles.length}, variedades=${variedades.length}, especies=${especies.length}, sucursalActiva=$_sucursalActivaId");
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


} 