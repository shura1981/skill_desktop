import 'package:flutter/material.dart';

import '../services/settings_service.dart';

const _accentColors = <Color>[
  Colors.blue,
  Colors.green,
  Colors.red,
  Colors.purple,
  Colors.teal,
  Colors.orange,
  Colors.indigo,
  Colors.amber,
];

Future<void> showThemeSettingsDialog(BuildContext context, SettingsService settings) async {
  ThemeMode mode = settings.themeMode;
  Color selectedColor = settings.seedColor;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Apariencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tema'),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('Sistema'),
                value: ThemeMode.system,
                // ignore: deprecated_member_use
                groupValue: mode,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => mode = v ?? ThemeMode.system),
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('Claro'),
                value: ThemeMode.light,
                // ignore: deprecated_member_use
                groupValue: mode,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => mode = v ?? ThemeMode.light),
              ),
              // ignore: deprecated_member_use
              RadioListTile<ThemeMode>(
                title: const Text('Oscuro'),
                value: ThemeMode.dark,
                // ignore: deprecated_member_use
                groupValue: mode,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => mode = v ?? ThemeMode.dark),
              ),
              const SizedBox(height: 16),
              const Text('Color de acento'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _accentColors.map((color) {
                  final selected = selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: selected ? Border.all(width: 3, color: Colors.black) : null,
                      ),
                      child: selected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                settings.updateThemeMode(mode);
                settings.updateAccentColor(selectedColor);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      });
    },
  );
}
