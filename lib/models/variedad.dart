class Variedad {
  final int id;
  final String nombre;
  final int idEspecie;
  final int? idForma;
  final int? idColor;

  Variedad({
    required this.id,
    required this.nombre,
    required this.idEspecie,
    this.idForma,
    this.idColor,
  });

  factory Variedad.fromJson(Map<String, dynamic> json) {
    return Variedad(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre'] ?? '',
      idEspecie: json['id_especie'] is int ? json['id_especie'] : int.parse(json['id_especie'].toString()),
      idForma: json['id_forma'] != null 
          ? (json['id_forma'] is int ? json['id_forma'] : int.parse(json['id_forma'].toString()))
          : null,
      idColor: json['id_color'] != null 
          ? (json['id_color'] is int ? json['id_color'] : int.parse(json['id_color'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'id_especie': idEspecie,
      'id_forma': idForma,
      'id_color': idColor,
    };
  }
} 