class TipoPlanta {
  final String id;
  final String nombre;
  final double factorProductivo;
  final int idEmpresa;
  final String? descripcion;

  TipoPlanta({
    required this.id,
    required this.nombre,
    required this.factorProductivo,
    required this.idEmpresa,
    this.descripcion,
  });

  factory TipoPlanta.fromJson(Map<String, dynamic> json) {
    return TipoPlanta(
      id: json['id'],
      nombre: json['nombre'],
      factorProductivo: json['factor_productivo'].toDouble(),
      idEmpresa: json['id_empresa'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'factor_productivo': factorProductivo,
      'id_empresa': idEmpresa,
      'descripcion': descripcion,
    };
  }
} 