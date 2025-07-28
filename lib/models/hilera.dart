class Hilera {
  final int id;
  final int hilera;
  final int idCuartel;
  final String? nombreCuartel;
  final String? nombre;

  Hilera({
    required this.id,
    required this.hilera,
    required this.idCuartel,
    this.nombreCuartel,
    this.nombre,
  });

  factory Hilera.fromJson(Map<String, dynamic> json) {
    return Hilera(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      hilera: json['hilera'],
      idCuartel: json['id_cuartel'],
      nombreCuartel: json['nombre_cuartel'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hilera': hilera,
      'id_cuartel': idCuartel,
      'nombre_cuartel': nombreCuartel,
      'nombre': nombre,
    };
  }
}

// Modelo para crear hilera - solo incluye los campos necesarios
class CrearHileraRequest {
  final int hilera;
  final int idCuartel;

  CrearHileraRequest({
    required this.hilera,
    required this.idCuartel,
  });

  Map<String, dynamic> toJson() {
    return {
      'hilera': hilera,
      'id_cuartel': idCuartel,
    };
  }
}

// Modelo para actualizar hilera
class ActualizarHileraRequest {
  final int? hilera;
  final int? idCuartel;

  ActualizarHileraRequest({
    this.hilera,
    this.idCuartel,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (hilera != null) data['hilera'] = hilera;
    if (idCuartel != null) data['id_cuartel'] = idCuartel;
    return data;
  }
} 