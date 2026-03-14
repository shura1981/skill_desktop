import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          MenuBar(
            children: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(onPressed: () => _showUserForm(), child: const Text('Nuevo')),
                  MenuItemButton(onPressed: _openSearch, child: const Text('Buscar')),
                  MenuItemButton(
                    onPressed: () async {
                      await showThemeSettingsDialog(context, settings);
                    },
                    child: const Text('Configuración'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text('Edición'),
                ),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'Flutter Desktop Demo',
                        applicationVersion: '1.0.0',
                        children: const [Text('Aplicación de ejemplo con SQLite y tray.')],
                      );
                    },
                    child: const Text('Acerca de'),
                  ),
                  MenuItemButton(
                    onPressed: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'Flutter Desktop Demo',
                        applicationVersion: '1.0.0',
                      );
                    },
                    child: const Text('Licencias'),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Text('Ayuda'),
                ),
              ),
            ],
          ),
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
