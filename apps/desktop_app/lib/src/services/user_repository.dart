import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/user.dart';

/// Simple SQLite repository for the `usuarios` table.
class UserRepository {
  static UserRepository? _instance;
  static Database? _db;

  /// A singleton instance; this will be created lazily if [initialize] is not
  /// called before usage (e.g. in unit tests).
  static UserRepository get instance => _instance ??= UserRepository._();

  UserRepository._();

  /// Initializes the underlying database.
  ///
  /// This should be called before using the repository in production apps.
  static Future<void> initialize() async {
    _instance ??= UserRepository._();
    if (_db != null) return;

    sqfliteFfiInit();

    final dbPath = await _getDatabasePath();
    _db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE usuarios(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              nombres TEXT NOT NULL,
              apellidos TEXT NOT NULL,
              fecha_nacimiento TEXT NOT NULL,
              ciudad TEXT NOT NULL,
              direccion TEXT NOT NULL,
              celular TEXT NOT NULL
            )
          ''');
        },
      ),
    );
  }

  static Future<String> _getDatabasePath() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return '${dir.path}${Platform.pathSeparator}app_data.db';
  }

  Future<List<User>> getUsers({String? filter}) async {
    final db = _db;
    if (db == null) return [];

    final where = (filter != null && filter.trim().isNotEmpty)
        ? "(nombres LIKE ? OR apellidos LIKE ? OR ciudad LIKE ?)"
        : null;
    final args = (filter != null && filter.trim().isNotEmpty)
        ? ['%$filter%', '%$filter%', '%$filter%']
        : null;

    final maps = await db.query(
      'usuarios',
      where: where,
      whereArgs: args,
      orderBy: 'nombres, apellidos',
    );

    return maps.map((m) => User.fromMap(m)).toList();
  }

  Future<User> insert(User user) async {
    final db = _db;
    if (db == null) throw StateError('Database not initialized');

    final id = await db.insert('usuarios', user.toMap());
    return user.copyWith(id: id);
  }

  Future<int> update(User user) async {
    final db = _db;
    if (db == null) throw StateError('Database not initialized');
    if (user.id == null) throw ArgumentError('User id is required for update');

    return db.update(
      'usuarios',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> delete(int id) async {
    final db = _db;
    if (db == null) throw StateError('Database not initialized');

    return db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }
}
