import 'package:flutter/material.dart';
import '../models/hilera.dart';
import '../models/cuartel.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';

class AgregarPlantasLotePage extends StatefulWidget {
  final Hilera hilera;
  final Cuartel cuartel;
  
  const AgregarPlantasLotePage({
    Key? key, 
    required this.hilera, 
    required this.cuartel,
  }) : super(key: key);

  @override
  State<AgregarPlantasLotePage> createState() => _AgregarPlantasLotePageState();
}

class _AgregarPlantasLotePageState extends State<AgregarPlantasLotePage> {
  final _formKey = GlobalKey<FormState>();
  final _numeroInicialController = TextEditingController();
  final _cantidadController = TextEditingController();
  
  bool _isLoading = false;
  bool _isCalculando = false;
  int _siguienteNumero = 1;
  int _cantidadPlantas = 0;
  List<int> _numerosPlantas = [];
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _calcularSiguienteNumero();
  }

  @override
  void dispose() {
    _numeroInicialController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  // Calcular el siguiente número disponible
  Future<void> _calcularSiguienteNumero() async {
    setState(() => _isCalculando = true);
    
    try {
      final plantas = await _apiService.getPlantasPorHilera(widget.hilera.id);
      int siguienteNumero = 1;
      
      if (plantas.isNotEmpty) {
        final maxNumero = plantas.map((p) => p.planta).reduce((a, b) => a > b ? a : b);
        siguienteNumero = maxNumero + 1;
      }
      
      if (mounted) {
        setState(() {
          _siguienteNumero = siguienteNumero;
          _numeroInicialController.text = siguienteNumero.toString();
          _isCalculando = false;
        });
        _actualizarNumerosPlantas();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _siguienteNumero = 1;
          _numeroInicialController.text = '1';
          _isCalculando = false;
        });
        _actualizarNumerosPlantas();
      }
    }
  }

  // Actualizar la lista de números de plantas
  void _actualizarNumerosPlantas() {
    final numeroInicial = int.tryParse(_numeroInicialController.text) ?? _siguienteNumero;
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    
    setState(() {
      _cantidadPlantas = cantidad;
      _numerosPlantas = List.generate(
        cantidad,
        (index) => numeroInicial + index,
      );
    });
  }

  // Verificar si se puede agregar plantas según el estado del catastro
  bool _puedeAgregarPlantas() {
    final estadoCatastro = widget.cuartel.idEstadoCatastro ?? 0;
    return estadoCatastro == 1 || estadoCatastro == 2; // Sin catastro o Iniciado
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: errorColor,
      ),
    );
  }

  Future<void> _agregarPlantasLote() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_puedeAgregarPlantas()) {
      _mostrarError('No se pueden agregar plantas en cuarteles finalizados');
      return;
    }

    final numeroInicial = int.parse(_numeroInicialController.text);
    final cantidad = int.parse(_cantidadController.text);

    if (cantidad <= 0) {
      _mostrarError('La cantidad debe ser mayor a 0');
      return;
    }

    if (cantidad > 100) {
      _mostrarError('No se pueden agregar más de 100 plantas a la vez');
      return;
    }

    // Confirmar antes de agregar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Agregar Plantas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de agregar $cantidad plantas?'),
            SizedBox(height: 8),
            Text('Desde: Planta $numeroInicial'),
            Text('Hasta: Planta ${numeroInicial + cantidad - 1}'),
            Text('Hilera: ${widget.hilera.hilera}'),
            Text('Cuartel: ${widget.cuartel.nombre}'),
            SizedBox(height: 8),
            Text(
              '⚠️ Las plantas se crearán SIN ubicación GPS',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
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
            child: Text('Agregar'),
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      // Mostrar progreso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              SizedBox(width: 8),
              Text('Agregando plantas...'),
            ],
          ),
          backgroundColor: primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );

      int plantasAgregadas = 0;
      int plantasFallidas = 0;

      // Agregar plantas una por una
      for (int i = 0; i < cantidad; i++) {
        try {
          final numeroPlanta = numeroInicial + i;
          
          // Crear planta sin ubicación (usar coordenadas vacías o null)
          await _apiService.crearPlantaSimple(
            widget.hilera.id,
            numeroPlanta,
            '', // Ubicación vacía
          );
          
          plantasAgregadas++;
        } catch (e) {
          plantasFallidas++;
          print('Error agregando planta ${numeroInicial + i}: $e');
        }
      }

      // Verificar y actualizar automáticamente el estado del catastro
      if (plantasAgregadas > 0) {
        await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
      }

      if (!mounted) return;

      // Cerrar el snackbar de progreso
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Mostrar resultado
      String mensaje;
      Color colorMensaje;

      if (plantasAgregadas > 0 && plantasFallidas == 0) {
        mensaje = '✅ Se agregaron $plantasAgregadas plantas correctamente';
        colorMensaje = successColor;
      } else if (plantasAgregadas > 0 && plantasFallidas > 0) {
        mensaje = '⚠️ Se agregaron $plantasAgregadas plantas, $plantasFallidas fallaron';
        colorMensaje = Colors.orange;
      } else {
        mensaje = '❌ No se pudo agregar ninguna planta';
        colorMensaje = errorColor;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: colorMensaje,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, plantasAgregadas > 0);

    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al agregar plantas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar Plantas en Lote'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

              // Número inicial
              TextFormField(
                controller: _numeroInicialController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Número Inicial',
                  hintText: 'Ej: 1, 5, 10...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  suffixIcon: _isCalculando
                      ? Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.refresh),
                          onPressed: _calcularSiguienteNumero,
                          tooltip: 'Calcular siguiente número',
                        ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el número inicial';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  final numero = int.parse(value);
                  if (numero <= 0) {
                    return 'El número debe ser mayor a 0';
                  }
                  return null;
                },
                onChanged: (value) => _actualizarNumerosPlantas(),
              ),
              SizedBox(height: 16),

              // Cantidad de plantas
              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad de Plantas',
                  hintText: 'Ej: 10, 20, 50...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.add_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la cantidad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Debe ser un número válido';
                  }
                  final cantidad = int.parse(value);
                  if (cantidad <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  if (cantidad > 100) {
                    return 'Máximo 100 plantas a la vez';
                  }
                  return null;
                },
                onChanged: (value) => _actualizarNumerosPlantas(),
              ),
              SizedBox(height: 16),

              // Vista previa de números
              if (_cantidadPlantas > 0) ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plantas a crear:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Cantidad: $_cantidadPlantas plantas'),
                        Text('Desde: Planta ${_numerosPlantas.first}'),
                        Text('Hasta: Planta ${_numerosPlantas.last}'),
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Las plantas se crearán SIN ubicación GPS',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],

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
                  label: Text(_isLoading ? 'Agregando...' : 'Agregar Plantas en Lote'),
                  onPressed: _isLoading ? null : _agregarPlantasLote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 