class Sucursal {
  final int id;
  final String nombre;
  final String ubicacion;

  Sucursal({
    required this.id,
    required this.nombre,
    required this.ubicacion,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) {
    return Sucursal(
      id: json['id'],
      nombre: json['nombre'],
      ubicacion: json['ubicacion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'ubicacion': ubicacion,
    };
  }
}

class Empresa {
  final int id;
  final String nombre;
  final int rut;
  final int codigoVerificador;
  final String fechaSuscripcion;

  Empresa({
    required this.id,
    required this.nombre,
    required this.rut,
    required this.codigoVerificador,
    required this.fechaSuscripcion,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: json['id'],
      nombre: json['nombre'],
      rut: json['rut'],
      codigoVerificador: json['codigo_verificador'],
      fechaSuscripcion: json['fecha_suscripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'rut': rut,
      'codigo_verificador': codigoVerificador,
      'fecha_suscripcion': fechaSuscripcion,
    };
  }
}

class Labor {
  final int id;
  final String nombre;

  Labor({
    required this.id,
    required this.nombre,
  });

  factory Labor.fromJson(Map<String, dynamic> json) {
    return Labor(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class Unidad {
  final int id;
  final String nombre;

  Unidad({
    required this.id,
    required this.nombre,
  });

  factory Unidad.fromJson(Map<String, dynamic> json) {
    return Unidad(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class TipoCeco {
  final int id;
  final String nombre;

  TipoCeco({
    required this.id,
    required this.nombre,
  });

  factory TipoCeco.fromJson(Map<String, dynamic> json) {
    return TipoCeco(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}

class OpcionesResponse {
  final List<Labor> labores;
  final List<Unidad> unidades;
  final List<TipoCeco> tipoCecos;

  OpcionesResponse({
    required this.labores,
    required this.unidades,
    required this.tipoCecos,
  });

  factory OpcionesResponse.fromJson(Map<String, dynamic> json) {
    return OpcionesResponse(
      labores: (json['labores'] as List)
          .map((labor) => Labor.fromJson(labor))
          .toList(),
      unidades: (json['unidades'] as List)
          .map((unidad) => Unidad.fromJson(unidad))
          .toList(),
      tipoCecos: (json['tipoCecos'] as List)
          .map((tipoCeco) => TipoCeco.fromJson(tipoCeco))
          .toList(),
    );
  }
} 