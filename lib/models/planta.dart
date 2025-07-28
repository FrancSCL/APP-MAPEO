class Planta {
  final int id;
  final int idHilera;
  final int planta;
  final String ubicacion;
  final String fechaCreacion;

  Planta({
    required this.id,
    required this.idHilera,
    required this.planta,
    required this.ubicacion,
    required this.fechaCreacion,
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      idHilera: json['id_hilera'],
      planta: json['planta'],
      ubicacion: json['ubicacion'],
      fechaCreacion: json['fecha_creacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_hilera': idHilera,
      'planta': planta,
      'ubicacion': ubicacion,
      'fecha_creacion': fechaCreacion,
    };
  }
}

// Modelo para crear planta - solo incluye los campos necesarios
class CrearPlantaRequest {
  final int idHilera;
  final int planta;
  final String ubicacion;

  CrearPlantaRequest({
    required this.idHilera,
    required this.planta,
    required this.ubicacion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_hilera': idHilera,
      'planta': planta,
      'ubicacion': ubicacion,
    };
  }
}

// Modelo para actualizar planta
class ActualizarPlantaRequest {
  final int? idHilera;
  final int? planta;
  final String? ubicacion;

  ActualizarPlantaRequest({
    this.idHilera,
    this.planta,
    this.ubicacion,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (idHilera != null) data['id_hilera'] = idHilera;
    if (planta != null) data['planta'] = planta;
    if (ubicacion != null) data['ubicacion'] = ubicacion;
    return data;
  }
} 