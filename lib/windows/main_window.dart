import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../database/database_helper.dart';
import '../models/person.dart';

class MainWindowPage extends ConsumerWidget {
  const MainWindowPage({super.key});

  void _openWindow(BuildContext context, WidgetRef ref, String title) async {
    final viewId = await ui.PlatformDispatcher.instance.requestView();
    ref.read(windowTitleProvider.notifier).register(viewId, title);
    // Set the OS window title for the new secondary window
    await SystemChannels.window.invokeMethod<void>('setWindowTitle', {
      'id': viewId,
      'title': title,
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personsAsync = ref.watch(personsProvider);

    return Scaffold(
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.keyR, control: true): () =>
              ref.invalidate(personsProvider),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              // ── Native MenuBar ──────────────────────────────────────────
              MenuBar(
                children: [
                  SubmenuButton(
                    child: const MenuAcceleratorLabel('&Abrir'),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.window, size: 16),
                        onPressed: () =>
                            _openWindow(context, ref, 'Ventana 1'),
                        child: const MenuAcceleratorLabel('&Ventana 1'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.window, size: 16),
                        onPressed: () =>
                            _openWindow(context, ref, 'Ventana 2'),
                        child: const MenuAcceleratorLabel('Ventana &2'),
                      ),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.window, size: 16),
                        onPressed: () =>
                            _openWindow(context, ref, 'Ventana 3'),
                        child: const MenuAcceleratorLabel('Ventana &3'),
                      ),
                    ],
                  ),
                  SubmenuButton(
                    child: const MenuAcceleratorLabel('A&yuda'),
                    menuChildren: [
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.info_outline, size: 16),
                        onPressed: () => showAboutDialog(
                          context: context,
                          applicationName: 'Desktop App',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2026',
                          children: [
                            const Text(
                              'Aplicación de escritorio con múltiples ventanas y base de datos SQLite.',
                            ),
                          ],
                        ),
                        child: const MenuAcceleratorLabel('&Acerca de'),
                      ),
                    ],
                  ),
                ],
              ),
              // ── Title bar ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  'Registro de Personas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // ── Data table ─────────────────────────────────────────────
              Expanded(
                child: personsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        Text('Error: $err'),
                        FilledButton(
                          onPressed: () => ref.invalidate(personsProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                  data: (persons) => persons.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 8,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              Text(
                                'No hay registros todavía.\nUse el menú Abrir para ingresar personas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _PersonTable(
                          persons: persons,
                          onDelete: (id) async {
                            await DatabaseHelper.instance.delete(id);
                            ref.invalidate(personsProvider);
                          },
                        ),
                ),
              ),
              // ── Status bar ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: personsAsync.when(
                  loading: () => const Text('Cargando...'),
                  error: (_, __) => const Text('Error al cargar datos'),
                  data: (p) => Text(
                    '${p.length} registro${p.length == 1 ? '' : 's'}  •  '
                    'Ctrl+R para refrescar',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ─────────────────────────────────────────────────────────

class _PersonTable extends StatelessWidget {
  const _PersonTable({
    required this.persons,
    required this.onDelete,
  });

  final List<Person> persons;
  final void Function(int id) onDelete;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Nombres')),
            DataColumn(label: Text('Apellidos')),
            DataColumn(label: Text('Ciudad')),
            DataColumn(label: Text('Celular')),
            DataColumn(label: Text('Peso (kg)')),
            DataColumn(label: Text('Estatura (m)')),
            DataColumn(label: Text('Acciones')),
          ],
          rows: persons.map((p) {
            return DataRow(
              cells: [
                DataCell(Text('${p.id}')),
                DataCell(Text(p.nombres)),
                DataCell(Text(p.apellidos)),
                DataCell(Text(p.ciudad)),
                DataCell(Text(p.celular)),
                DataCell(Text(p.peso.toStringAsFixed(1))),
                DataCell(Text(p.estatura.toStringAsFixed(2))),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Eliminar',
                    onPressed: () => _confirmDelete(context, p),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Person p) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text(
          '¿Desea eliminar a ${p.nombres} ${p.apellidos}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && p.id != null) onDelete(p.id!);
    });
  }
}
