import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'cambiar_clave_page.dart';
import 'cambiar_sucursal_page.dart';
import 'seleccionar_cuartel_page.dart';
import 'seleccionar_cuartel_mapeo_page.dart';
import '../widgets/layout/app_bar.dart';
import '../services/api_service.dart';
import '../utils/colors.dart';
import '../models/cuartel.dart';

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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String userName = "Usuario";
  String nombreCompleto = "Usuario"; // NUEVO CAMPO
  String userSucursal = "Sucursal";
  bool _isLoading = false;
  late AnimationController _animationController;
  
  Key _actividadesKey = UniqueKey();
  Key _rendimientosKey = UniqueKey();
  List<Map<String, dynamic>> _sucursalesDisponibles = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _cargarNombreUsuario();
    _cargarSucursalesDisponibles();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _forzarRecargaPantallas() {
    setState(() {
      _actividadesKey = UniqueKey();
      _rendimientosKey = UniqueKey();
    });
  }

  Future<void> _cargarNombreUsuario() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreCompletoRaw = prefs.getString('nombre_completo') ?? prefs.getString('user_name') ?? "Usuario";
      
      // Extraer solo el primer nombre
      final nombreSolo = nombreCompletoRaw.split(' ').first;
      
      setState(() {
        userName = prefs.getString('user_name') ?? "Usuario";
        nombreCompleto = nombreSolo; // Solo el primer nombre
        userSucursal = prefs.getString('user_sucursal') ?? "Sucursal";
        _isLoading = false;
      });
      logInfo("🏠 Sucursal activa cargada: $userSucursal");
      _forzarRecargaPantallas();
    } catch (e) {
      logError("❌ Error cargando datos de usuario: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSucursalesDisponibles() async {
    try {
      final sucursales = await ApiService().getSucursales();
      setState(() {
        _sucursalesDisponibles = sucursales;
      });
    } catch (e) {
      logError("❌ Error al cargar sucursales disponibles: $e");
    }
  }

  Future<void> _seleccionarSucursal(BuildContext context) async {
    final seleccion = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecciona una sucursal'),
          content: Container(
            width: double.maxFinite,
            child: _sucursalesDisponibles.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _sucursalesDisponibles.length,
                    itemBuilder: (context, index) {
                      final suc = _sucursalesDisponibles[index];
                      return ListTile(
                        leading: Icon(Icons.location_on, color: Colors.green),
                        title: Text(suc['nombre']),
                        selected: suc['nombre'] == userSucursal,
                        onTap: () => Navigator.pop(context, suc),
                      );
                    },
                  ),
          ),
        );
      },
    );
    
    if (seleccion != null && seleccion['nombre'] != userSucursal) {
      // Actualizar en backend
      final exito = await ApiService().actualizarSucursalActiva(seleccion['id'].toString());
      if (exito) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id_sucursal', seleccion['id'].toString());
        await prefs.setString('user_sucursal', seleccion['nombre']);
        setState(() {
          userSucursal = seleccion['nombre'];
        });
        _forzarRecargaPantallas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sucursal cambiada a ${seleccion['nombre']}'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar la sucursal activa en el AppBar
        await _recargarPagina();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('No se pudo actualizar la sucursal en el servidor'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _recargarPagina() async {
    _animationController.forward(from: 0);
    await _cargarNombreUsuario();
  }

  Future<void> _cerrarSesion() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text("Cerrar Sesión"),
            ],
          ),
          content: Text("¿Está seguro que desea cerrar sesión?"),
          actions: [
            TextButton(
              child: Text("Cancelar"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Cerrar Sesión"),
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el diálogo
                setState(() => _isLoading = true);
                
                try {
                  // Limpiar preferencias localmente primero
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  
                  // Mostrar mensaje de confirmación
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sesión cerrada exitosamente.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                  
                  // Navegar al login y limpiar el stack de navegación
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false
                    );
                  }
                } catch (e) {
                  logError('Error al cerrar sesión: $e');
                  // Si hay error, intentar cerrar sesión manualmente
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context, 
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      (route) => false
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String titulo = (_selectedIndex == 0) ? "Mapeo" : "Progreso";

    return Stack(
      children: [
        Scaffold(
          appBar: CustomAppBar(
            title: titulo,
            actions: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          nombreCompleto, // CAMBIADO: userName -> nombreCompleto
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _seleccionarSucursal(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            userSucursal,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_animationController),
                child: IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    await _recargarPagina();
                    await _cargarSucursalesDisponibles();
                  },
                ),
              ),
            ],
          ),
          body: _selectedIndex == 0 
            ? _buildActividadesTab()
            : _buildIndicadoresTab(),
          drawer: _buildDrawer(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            );
          }

          final prefs = snapshot.data!;
          final esAdmin = prefs.getString('id_perfil') == '3';

          return Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildDrawerHeader(),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(height: 20),
                        
                        Divider(height: 30, color: Colors.green.withOpacity(0.2)),
                        _buildDrawerItem(
                          icon: Icons.change_circle,
                          title: "Cambiar Sucursal Activa",
                          onTap: () async {
                            Navigator.pop(context);
                            final resultado = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CambiarSucursalPage()),
                            );
                            if (resultado == true) {
                              _cargarNombreUsuario();
                              _forzarRecargaPantallas();
                            }
                          },
                          color: Colors.blue,
                        ),
                        _buildDrawerItem(
                          icon: Icons.lock,
                          title: "Cambiar Clave",
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CambiarClavePage()),
                            );
                          },
                          color: Colors.amber,
                        ),
                        _buildDrawerItem(
                          icon: Icons.logout,
                          title: "Cerrar Sesión",
                          onTap: () {
                            Navigator.pop(context);
                            _cerrarSesion();
                          },
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 60, 16, 30),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: Colors.green, size: 40),
          ),
          SizedBox(height: 16),
          Text(
            "Bienvenido,",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          Text(
            nombreCompleto, // CAMBIADO: userName -> nombreCompleto
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  userSucursal,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildActividadesTab() {
    return Container(
      key: _actividadesKey,
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con saludo
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, $nombreCompleto! 👋', // CAMBIADO: userName -> nombreCompleto
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sucursal activa: $userSucursal',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Tres cards principales
            Column(
              children: [
                // Primera fila: Catastrar e Iniciar Mapeo
                Row(
                  children: [
                    Expanded(
                      child: _buildMapeoCard(
                        icon: Icons.agriculture,
                        title: 'Catastrar',
                        subtitle: 'Configurar cuarteles e hileras',
                        color: Colors.blue,
                        onTap: () async {
                          final cuartelSeleccionado = await Navigator.push<Cuartel>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeleccionarCuartelPage(),
                            ),
                          );
                          
                          if (cuartelSeleccionado != null && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Cuartel seleccionado: ${cuartelSeleccionado.nombre}'),
                                  ],
                                ),
                                backgroundColor: successColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildMapeoCard(
                        icon: Icons.map,
                        title: 'Iniciar Mapeo',
                        subtitle: 'Seleccionar cuartel y comenzar',
                        color: Color(0xFFFF9800), // Naranja
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SeleccionarCuartelMapeoPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Segunda fila: Sincronizar (centrado)
                _buildMapeoCard(
                  icon: Icons.sync,
                  title: 'Sincronizar',
                  subtitle: 'Enviar datos al servidor',
                  color: Color(0xFF4CAF50), // Verde
                  onTap: () {
                    // TODO: Implementar sincronización
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Funcionalidad en desarrollo'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Estadísticas rápidas
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 Estadísticas del Día',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.agriculture,
                          value: '0',
                          label: 'Cuarteles',
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.straighten,
                          value: '0',
                          label: 'Hileras',
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.local_florist,
                          value: '0',
                          label: 'Plantas',
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicadoresTab() {
    return Container(
      key: _rendimientosKey,
      padding: EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 Progreso de Mapeo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Resumen de actividades realizadas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Progreso general
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Objetivos del Día',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildProgressItem(
                    label: 'Plantas Mapeadas',
                    current: 0,
                    total: 100,
                    color: Colors.green,
                  ),
                  SizedBox(height: 12),
                  _buildProgressItem(
                    label: 'Hileras Completadas',
                    current: 0,
                    total: 10,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 12),
                  _buildProgressItem(
                    label: 'Cuarteles Visitados',
                    current: 0,
                    total: 5,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            
            // Últimas actividades
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🕒 Actividad Reciente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildActivityItem(
                    icon: Icons.info,
                    title: 'No hay actividad reciente',
                    subtitle: 'Inicia un mapeo para ver tu progreso',
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapeoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem({
    required String label,
    required int current,
    required int total,
    required Color color,
  }) {
    final progress = total > 0 ? current / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$current/$total',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapeo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Progreso',
          ),
        ],
      ),
    );
  }
}
