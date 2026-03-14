class User {
  final int? id;
  final String nombres;
  final String apellidos;
  final DateTime fechaNacimiento;
  final String ciudad;
  final String direccion;
  final String celular;

  const User({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.ciudad,
    required this.direccion,
    required this.celular,
  });

  User copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    DateTime? fechaNacimiento,
    String? ciudad,
    String? direccion,
    String? celular,
  }) {
    return User(
      id: id ?? this.id,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      ciudad: ciudad ?? this.ciudad,
      direccion: direccion ?? this.direccion,
      celular: celular ?? this.celular,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'apellidos': apellidos,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'ciudad': ciudad,
      'direccion': direccion,
      'celular': celular,
    };
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      id: map['id'] as int?,
      nombres: map['nombres'] as String? ?? '',
      apellidos: map['apellidos'] as String? ?? '',
      fechaNacimiento: DateTime.parse(map['fecha_nacimiento'] as String? ?? ''),
      ciudad: map['ciudad'] as String? ?? '',
      direccion: map['direccion'] as String? ?? '',
      celular: map['celular'] as String? ?? '',
    );
  }
}
