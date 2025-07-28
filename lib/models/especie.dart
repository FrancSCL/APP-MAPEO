class Especie {
  final int id;
  final String nombre;
  final double cajaEquivalente;

  Especie({
    required this.id,
    required this.nombre,
    required this.cajaEquivalente,
  });

  factory Especie.fromJson(Map<String, dynamic> json) {
    return Especie(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      cajaEquivalente: json['caja_equivalente'] != null 
          ? (json['caja_equivalente'] is num ? json['caja_equivalente'].toDouble() : double.parse(json['caja_equivalente'].toString()))
          : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'caja_equivalente': cajaEquivalente,
    };
  }
} 