import 'dart:convert';

// Modelo para registros individuales de plantas mapeadas (tabla existente)
class RegistroMapeo {
  final String id;
  final String idEvaluador;
  final String horaRegistro;
  final String idPlanta; // Cambiado de int a String para bigint
  final int idTipoPlanta;
  final String? imagen;

  RegistroMapeo({
    required this.id,
    required this.idEvaluador,
    required this.horaRegistro,
    required this.idPlanta,
    required this.idTipoPlanta,
    this.imagen,
  });

  factory RegistroMapeo.fromJson(Map<String, dynamic> json) {
    return RegistroMapeo(
      id: json['id']?.toString() ?? '',
      idEvaluador: json['id_evaluador']?.toString() ?? '',
      horaRegistro: json['hora_registro']?.toString() ?? '',
      idPlanta: json['id_planta'].toString(), // Convertir a String para bigint
      idTipoPlanta: json['id_tipoplanta'] ?? 0,
      imagen: json['imagen']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_evaluador': idEvaluador,
      'hora_registro': horaRegistro,
      'id_planta': idPlanta,
      'id_tipoplanta': idTipoPlanta,
      'imagen': imagen,
    };
  }
}

// 🆕 NUEVO MODELO: Para la tabla registromapeo (sesiones de mapeo)
class RegistroMapeoSesion {
  final String id;
  final int idTemporada;
  final int idCuartel;
  final String fechaInicio;
  final String? fechaTermino;
  final int idEstado;

  RegistroMapeoSesion({
    required this.id,
    required this.idTemporada,
    required this.idCuartel,
    required this.fechaInicio,
    this.fechaTermino,
    required this.idEstado,
  });

  factory RegistroMapeoSesion.fromJson(Map<String, dynamic> json) {
    return RegistroMapeoSesion(
      id: json['id']?.toString() ?? '',
      idTemporada: json['id_temporada'] ?? 0,
      idCuartel: json['id_cuartel'] ?? 0,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaTermino: json['fecha_termino']?.toString(),
      idEstado: json['id_estado'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_temporada': idTemporada,
      'id_cuartel': idCuartel,
      'fecha_inicio': fechaInicio,
      'fecha_termino': fechaTermino, // ✅ Ahora el backend maneja null correctamente
      'id_estado': idEstado,
    };
  }

  // Método para crear un registro de mapeo para iniciar sesión
  static RegistroMapeoSesion crearParaIniciar({
    required int idTemporada,
    required int idCuartel,
  }) {
    // 🆕 Corregir formato de fecha: YYYY-MM-DD en lugar de ISO 8601
    final now = DateTime.now();
    final fechaInicio = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    return RegistroMapeoSesion(
      id: '', // Se generará en el backend
      idTemporada: idTemporada,
      idCuartel: idCuartel,
      fechaInicio: fechaInicio, // 🆕 Formato YYYY-MM-DD
      fechaTermino: null,
      idEstado: 1, // INICIADO
    );
  }
} 