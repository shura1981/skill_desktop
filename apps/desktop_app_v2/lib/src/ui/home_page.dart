import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../models/user.dart';
import '../services/user_repository.dart';
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
        title: const Text('Confirmar eliminacion'),
        content: Text('Eliminar a ${user.nombres} ${user.apellidos}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirmed != true || user.id == null) {
      return;
    }

    await _repository.delete(user.id!);
    await _loadUsers(filter: _searchController.text);
  }

  Future<void> _openSearch() async {
    final filter = await showDialog<String?>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _searchController.text);
        return AlertDialog(
          title: const Text('Buscar'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Buscar por nombre, apellido o ciudad'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Buscar')),
          ],
        );
      },
    );

    if (filter != null) {
      _searchController.text = filter;
      await _loadUsers(filter: filter);
    }
  }

  void _openThemeSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ThemeSettingsPage(),
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Desktop App V2',
      applicationVersion: '1.0.0',
      children: const [Text('Aplicacion de escritorio con tema Material 3, SQLite y tray.')],
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: 'Desktop App V2',
      applicationVersion: '1.0.0',
    );
  }

  List<PlatformMenuItem> _buildDesktopMenus() {
    return [
      PlatformMenu(
        label: 'Edicion',
        menus: [
          PlatformMenuItem(label: 'Nuevo', onSelected: () {
            _showUserForm();
          }),
          PlatformMenuItem(label: 'Buscar', onSelected: () {
            _openSearch();
          }),
        ],
      ),
      PlatformMenu(
        label: 'Ayuda',
        menus: [
          PlatformMenuItem(label: 'Acerca de', onSelected: _showAbout),
          PlatformMenuItem(label: 'Licencias', onSelected: _showLicenses),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: _buildDesktopMenus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Usuarios'),
          actions: [
            IconButton(
              tooltip: 'Buscar',
              icon: const Icon(Icons.search),
              onPressed: _openSearch,
            ),
            IconButton(
              tooltip: 'Tema',
              icon: const Icon(Icons.palette_outlined),
              onPressed: _openThemeSettings,
            ),
            IconButton(
              tooltip: 'Minimizar',
              icon: const Icon(Icons.minimize),
              onPressed: () => windowManager.minimize(),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildUserTable(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showUserForm();
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo'),
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    if (_users.isEmpty) {
      return const Center(child: Text('No hay usuarios. Usa Edicion > Nuevo para agregar uno.'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombres y apellidos')),
          DataColumn(label: Text('Fecha nacimiento')),
          DataColumn(label: Text('Ciudad')),
          DataColumn(label: Text('Direccion')),
          DataColumn(label: Text('Celular')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: _users.map((user) {
          return DataRow(cells: [
            DataCell(Text('${user.nombres} ${user.apellidos}')),
            DataCell(Text(_formatDate(user.fechaNacimiento))),
            DataCell(Text(user.ciudad)),
            DataCell(Text(user.direccion)),
            DataCell(Text(user.celular)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _showUserForm(user),
                    child: const Text('Actualizar'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _deleteUser(user),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
