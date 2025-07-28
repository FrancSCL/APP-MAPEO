class Cuartel {
  final int? id;
  final int? idCeco;
  final String? nombre;
  final int? idVariedad;
  final double? superficie;
  final int? anoPlantacion;
  final double? dsh;
  final double? deh;
  final int? idPropiedad;
  final int? idPortainjerto;
  final int? brazosEjes;
  final int? idEstado;
  final String? fechaBaja;
  final int? idEstadoProductivo;
  final int? nHileras;
  final int? idEstadoCatastro;
  final int? idSucursal;
  final String? nombreSucursal;

  Cuartel({
    this.id,
    this.idCeco,
    this.nombre,
    this.idVariedad,
    this.superficie,
    this.anoPlantacion,
    this.dsh,
    this.deh,
    this.idPropiedad,
    this.idPortainjerto,
    this.brazosEjes,
    this.idEstado,
    this.fechaBaja,
    this.idEstadoProductivo,
    this.nHileras,
    this.idEstadoCatastro,
    this.idSucursal,
    this.nombreSucursal,
  });

  factory Cuartel.fromJson(Map<String, dynamic> json) {
    return Cuartel(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.parse(json['id'].toString()) : null),
      idCeco: json['id_ceco'] is int ? json['id_ceco'] : (json['id_ceco'] != null ? int.parse(json['id_ceco'].toString()) : null),
      nombre: json['nombre'],
      idVariedad: json['id_variedad'] is int ? json['id_variedad'] : (json['id_variedad'] != null ? int.parse(json['id_variedad'].toString()) : null),
      superficie: json['superficie'] != null ? (json['superficie'] is num ? json['superficie'].toDouble() : double.parse(json['superficie'].toString())) : null,
      anoPlantacion: json['ano_plantacion'] is int ? json['ano_plantacion'] : (json['ano_plantacion'] != null ? int.parse(json['ano_plantacion'].toString()) : null),
      dsh: json['dsh'] != null ? (json['dsh'] is num ? json['dsh'].toDouble() : double.parse(json['dsh'].toString())) : null,
      deh: json['deh'] != null ? (json['deh'] is num ? json['deh'].toDouble() : double.parse(json['deh'].toString())) : null,
      idPropiedad: json['id_propiedad'] is int ? json['id_propiedad'] : (json['id_propiedad'] != null ? int.parse(json['id_propiedad'].toString()) : null),
      idPortainjerto: json['id_portainjerto'] is int ? json['id_portainjerto'] : (json['id_portainjerto'] != null ? int.parse(json['id_portainjerto'].toString()) : null),
      brazosEjes: json['brazos_ejes'] is int ? json['brazos_ejes'] : (json['brazos_ejes'] != null ? int.parse(json['brazos_ejes'].toString()) : null),
      idEstado: json['id_estado'] is int ? json['id_estado'] : (json['id_estado'] != null ? int.parse(json['id_estado'].toString()) : null),
      fechaBaja: json['fecha_baja'],
      idEstadoProductivo: json['id_estadoproductivo'] is int ? json['id_estadoproductivo'] : (json['id_estadoproductivo'] != null ? int.parse(json['id_estadoproductivo'].toString()) : null),
      nHileras: json['n_hileras'] is int ? json['n_hileras'] : (json['n_hileras'] != null ? int.parse(json['n_hileras'].toString()) : null),
      idEstadoCatastro: json['id_estadocatastro'] is int ? json['id_estadocatastro'] : (json['id_estadocatastro'] != null ? int.parse(json['id_estadocatastro'].toString()) : null),
      idSucursal: json['id_sucursal'] is int ? json['id_sucursal'] : (json['id_sucursal'] != null ? int.parse(json['id_sucursal'].toString()) : null),
      nombreSucursal: json['nombre_sucursal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_ceco': idCeco,
      'nombre': nombre,
      'id_variedad': idVariedad,
      'superficie': superficie,
      'ano_plantacion': anoPlantacion,
      'dsh': dsh,
      'deh': deh,
      'id_propiedad': idPropiedad,
      'id_portainjerto': idPortainjerto,
      'brazos_ejes': brazosEjes,
      'id_estado': idEstado,
      'fecha_baja': fechaBaja,
      'id_estadoproductivo': idEstadoProductivo,
      'n_hileras': nHileras,
      'id_estadocatastro': idEstadoCatastro,
      'id_sucursal': idSucursal,
      'nombre_sucursal': nombreSucursal,
    };
  }
} 