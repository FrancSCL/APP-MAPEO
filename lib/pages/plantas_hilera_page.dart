import 'package:flutter/material.dart';
import '../models/hilera.dart';
import '../models/planta.dart';
import '../models/cuartel.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import 'agregar_planta_page.dart';
import 'agregar_plantas_lote_page.dart';

class PlantasHileraPage extends StatefulWidget {
  final Hilera hilera;
  final Cuartel cuartel;
  
  const PlantasHileraPage({
    Key? key, 
    required this.hilera, 
    required this.cuartel,
  }) : super(key: key);

  @override
  State<PlantasHileraPage> createState() => _PlantasHileraPageState();
}

class _PlantasHileraPageState extends State<PlantasHileraPage> {
  List<Planta> _plantas = [];
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _cargarPlantas();
  }

  Future<void> _cargarPlantas() async {
    setState(() => _isLoading = true);
    try {
      final plantas = await _apiService.getPlantasPorHilera(widget.hilera.id);
      setState(() {
        _plantas = plantas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar plantas: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // Verificar si se pueden agregar plantas según el estado del catastro
  bool _puedeAgregarPlantas() {
    final estadoCatastro = widget.cuartel.idEstadoCatastro ?? 0;
    return estadoCatastro == 1 || estadoCatastro == 2; // Sin catastro o Iniciado
  }

  Future<void> _eliminarPlanta(Planta planta) async {
    try {
      await _apiService.eliminarPlanta(planta.id);
      
      // Verificar y actualizar automáticamente el estado del catastro
      await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
      
      await _cargarPlantas();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Planta ${planta.planta} eliminada correctamente'),
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar planta: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  void _mostrarConfirmacionEliminar(Planta planta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Última Planta'),
        content: Text('¿Está seguro de eliminar la planta ${planta.planta}?\n\nSolo se puede eliminar la última planta de la hilera.'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: errorColor),
            onPressed: () {
              Navigator.pop(context);
              _eliminarPlanta(planta);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Plantas - Hilera ${widget.hilera.hilera}'),
        backgroundColor: primaryGreen,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (_puedeAgregarPlantas())
            PopupMenuButton<String>(
              icon: Icon(Icons.add, color: Colors.white),
              onSelected: (value) async {
                if (value == 'individual') {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgregarPlantaPage(
                        hilera: widget.hilera,
                        cuartel: widget.cuartel,
                      ),
                    ),
                  );
                  if (resultado == true) {
                    // Se agregó una planta, verificar estado del catastro
                    await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
                  }
                  _cargarPlantas(); // Recargar después de agregar
                } else if (value == 'lote') {
                  final resultado = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgregarPlantasLotePage(
                        hilera: widget.hilera,
                        cuartel: widget.cuartel,
                      ),
                    ),
                  );
                  if (resultado == true) {
                    // Se agregaron plantas, verificar estado del catastro
                    await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
                  }
                  _cargarPlantas(); // Recargar después de agregar
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'individual',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: primaryGreen),
                      SizedBox(width: 8),
                      Text('Agregar Planta Individual'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'lote',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, color: primaryGreen),
                      SizedBox(width: 8),
                      Text('Agregar Plantas en Lote'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // Información del cuartel y hilera
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cuartel.nombre ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Hilera ${widget.hilera.hilera}',
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.local_florist,
                            color: primaryGreen,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${_plantas.length} plantas',
                            style: TextStyle(
                              fontSize: 14,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Mensaje si no hay plantas
                if (_plantas.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_florist_outlined,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No hay plantas registradas',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Esta hilera no tiene plantas configuradas',
                            style: TextStyle(
                              fontSize: 14,
                              color: textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          if (_puedeAgregarPlantas())
                            ElevatedButton.icon(
                              icon: Icon(Icons.add),
                              label: Text('Agregar Primera Planta'),
                              onPressed: () async {
                                final resultado = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AgregarPlantaPage(
                                      hilera: widget.hilera,
                                      cuartel: widget.cuartel,
                                    ),
                                  ),
                                );
                                if (resultado == true) {
                                  // Se agregó una planta, verificar estado del catastro
                                  await _apiService.verificarYActualizarEstadoCatastro(widget.cuartel.id ?? 0);
                                }
                                _cargarPlantas();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  // Lista de plantas
                  Expanded(
                    child: ListView.builder(
                      itemCount: _plantas.length,
                      itemBuilder: (context, index) {
                        final planta = _plantas[index];
                                                 final esUltimaPlanta = index == _plantas.length - 1;
                         return Card(
                           margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                           color: esUltimaPlanta ? Colors.orange[50] : null,
                           child: ListTile(
                             leading: CircleAvatar(
                               backgroundColor: esUltimaPlanta ? Colors.orange : primaryGreen,
                               child: Text(
                                 '${planta.planta}',
                                 style: TextStyle(
                                   color: Colors.white,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                             ),
                            title: Text(
                              'Planta ${planta.planta}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                                                         subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text('Ubicación: ${planta.ubicacion}'),
                                 Text(
                                   'Creada: ${planta.fechaCreacion}',
                                   style: TextStyle(fontSize: 12, color: textLight),
                                 ),
                                 if (esUltimaPlanta)
                                   Text(
                                     'Última planta',
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: Colors.orange[700],
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                               ],
                             ),
                            trailing: _puedeAgregarPlantas() && index == _plantas.length - 1
                                ? IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _mostrarConfirmacionEliminar(planta),
                                  )
                                : _puedeAgregarPlantas()
                                    ? Icon(
                                        Icons.lock,
                                        color: Colors.grey[400],
                                        size: 20,
                                      )
                                    : Icon(
                                        Icons.lock,
                                        color: Colors.grey[400],
                                        size: 20,
                                      ),
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