import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../models/user.dart';
import '../services/user_repository.dart';
import '../services/settings_service.dart';
import 'theme_settings.dart';
import 'user_form_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  List<User> _users = [];
  bool _isLoading = true;

  UserRepository get _repository => context.read<UserRepository>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? filter}) async {
    setState(() => _isLoading = true);
    _users = await _repository.getUsers(filter: filter);
    setState(() => _isLoading = false);
  }

  Future<void> _showUserForm([User? user]) async {
    final result = await showUserFormDialog(context, user: user);
    if (result == null) return;

    if (user == null) {
      await _repository.insert(result);
    } else {
      await _repository.update(result);
    }

    await _loadUsers(filter: _searchController.text);
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar a ${user.nombres} ${user.apellidos}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed != true) return;
    if (user.id != null) {
      await _repository.delete(user.id!);
      await _loadUsers(filter: _searchController.text);
    }
  }

  void _openSearch() async {
    final filter = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _searchController.text);
        return AlertDialog(
          title: const Text('Buscar'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Buscar por nombre o ciudad'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Buscar')),
          ],
        );
      },
    );

    if (filter != null) {
      _searchController.text = filter;
      await _loadUsers(filter: filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      body: Column(
        children: [
          _buildTitleBar(context, settings),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserTable(context),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo usuario'),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            const Text('Mi App de Escritorio', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            _buildMenuButton(
              context: context,
              label: 'Edición',
              items: [
                PopupMenuItem(
                  value: 'nuevo',
                  child: const Text('Nuevo'),
                ),
                PopupMenuItem(
                  value: 'buscar',
                  child: const Text('Buscar'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'configurar',
                  child: const Text('Configuración'),
                ),
              ],
              onSelected: (value) async {
                switch (value) {
                  case 'nuevo':
                    _showUserForm();
                    break;
                  case 'buscar':
                    _openSearch();
                    break;
                  case 'configurar':
                    await showThemeSettingsDialog(context, settings);
                    break;
                }
              },
            ),
            const SizedBox(width: 8),
            _buildMenuButton(
              context: context,
              label: 'Ayuda',
              items: [
                PopupMenuItem(
                  value: 'acerca',
                  child: const Text('Acerca de'),
                ),
                PopupMenuItem(
                  value: 'licencias',
                  child: const Text('Licencias'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'acerca':
                    showAboutDialog(
                      context: context,
                      applicationName: 'Flutter Desktop Demo',
                      applicationVersion: '1.0.0',
                      children: const [Text('Aplicación de ejemplo con SQLite y tray.')],
                    );
                    break;
                  case 'licencias':
                    showLicensePage(
                      context: context,
                      applicationName: 'Flutter Desktop Demo',
                      applicationVersion: '1.0.0',
                    );
                    break;
                }
              },
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Minimizar',
              icon: const Icon(Icons.minimize),
              onPressed: () => windowManager.minimize(),
            ),
            IconButton(
              tooltip: 'Cerrar',
              icon: const Icon(Icons.close),
              onPressed: () => windowManager.close(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required List<PopupMenuEntry<String>> items,
    required void Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      tooltip: label,
      offset: const Offset(0, 38),
      itemBuilder: (_) => items,
      onSelected: onSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildUserTable(BuildContext context) {
    if (_users.isEmpty) {
      return const Center(child: Text('No hay usuarios. Agrega uno con "Nuevo".'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombres')),
          DataColumn(label: Text('Apellidos')),
          DataColumn(label: Text('Fecha Nac.')),
          DataColumn(label: Text('Ciudad')),
          DataColumn(label: Text('Dirección')),
          DataColumn(label: Text('Celular')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: _users.map((user) {
          return DataRow(cells: [
            DataCell(Text(user.nombres)),
            DataCell(Text(user.apellidos)),
            DataCell(Text(_formatDate(user.fechaNacimiento))),
            DataCell(Text(user.ciudad)),
            DataCell(Text(user.direccion)),
            DataCell(Text(user.celular)),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _showUserForm(user),
                  child: const Text('Actualizar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _deleteUser(user),
                  child: const Text('Eliminar'),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
