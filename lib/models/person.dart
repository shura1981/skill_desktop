class Person {
  final int? id;
  final String nombres;
  final String apellidos;
  final String ciudad;
  final String celular;
  final double peso;
  final double estatura;

  const Person({
    this.id,
    required this.nombres,
    required this.apellidos,
    required this.ciudad,
    required this.celular,
    required this.peso,
    required this.estatura,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nombres': nombres,
    'apellidos': apellidos,
    'ciudad': ciudad,
    'celular': celular,
    'peso': peso,
    'estatura': estatura,
  };

  factory Person.fromMap(Map<String, dynamic> map) => Person(
    id: map['id'] as int?,
    nombres: map['nombres'] as String,
    apellidos: map['apellidos'] as String,
    ciudad: map['ciudad'] as String,
    celular: map['celular'] as String,
    peso: (map['peso'] as num).toDouble(),
    estatura: (map['estatura'] as num).toDouble(),
  );

  Person copyWith({
    int? id,
    String? nombres,
    String? apellidos,
    String? ciudad,
    String? celular,
    double? peso,
    double? estatura,
  }) => Person(
    id: id ?? this.id,
    nombres: nombres ?? this.nombres,
    apellidos: apellidos ?? this.apellidos,
    ciudad: ciudad ?? this.ciudad,
    celular: celular ?? this.celular,
    peso: peso ?? this.peso,
    estatura: estatura ?? this.estatura,
  );
}
