import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_mapeo/pages/login_page.dart';
import 'package:app_mapeo/pages/home_page.dart';
import 'package:app_mapeo/theme/app_theme.dart';
import 'package:app_mapeo/providers/theme_provider.dart';
import 'package:app_mapeo/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');
  
  // Verificar si el token existe y es válido
  bool tokenValido = false;
  if (token != null) {
    try {
      final apiService = ApiService();
      tokenValido = await apiService.verificarTokenValido();
    } catch (e) {
      // Si hay error, limpiar el token
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
    }
  }
  
  final startPage = tokenValido ? HomePage() : LoginPage();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(startPage: startPage),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startPage;

  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
<<<<<<< HEAD
      title: 'App Mapeo',
=======
      title: 'LH Tarjas',
>>>>>>> 6242329353efdcc70be3637d201dea1775fbf32c
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiService.navigatorKey,
      theme: themeProvider.currentTheme,
      home: startPage,
    );
  }
}
