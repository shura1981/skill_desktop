import 'package:flutter/material.dart';

import '../models/user.dart';

Future<User?> showUserFormDialog(BuildContext context, {User? user}) {
  final nombresController = TextEditingController(text: user?.nombres ?? '');
  final apellidosController = TextEditingController(text: user?.apellidos ?? '');
  final ciudadController = TextEditingController(text: user?.ciudad ?? '');
  final direccionController = TextEditingController(text: user?.direccion ?? '');
  final celularController = TextEditingController(text: user?.celular ?? '');
  DateTime fechaNacimiento = user?.fechaNacimiento ?? DateTime.now();

  return showDialog<User>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: Text(user == null ? 'Nuevo usuario' : 'Editar usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombresController,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                ),
                TextField(
                  controller: apellidosController,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                ),
                TextField(
                  controller: ciudadController,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                ),
                TextField(
                  controller: direccionController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                ),
                TextField(
                  controller: celularController,
                  decoration: const InputDecoration(labelText: 'Celular'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text('Fecha de nacimiento: ${fechaNacimiento.toLocal().toIso8601String().split('T').first}'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: fechaNacimiento,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (selected != null) {
                          setState(() {
                            fechaNacimiento = selected;
                          });
                        }
                      },
                      child: const Text('Seleccionar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                final newUser = User(
                  id: user?.id,
                  nombres: nombresController.text.trim(),
                  apellidos: apellidosController.text.trim(),
                  fechaNacimiento: fechaNacimiento,
                  ciudad: ciudadController.text.trim(),
                  direccion: direccionController.text.trim(),
                  celular: celularController.text.trim(),
                );

                Navigator.of(context).pop(newUser);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
