import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/person.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get database async => _db ??= await _initDB('personas.db');

  Future<Database> _initDB(String fileName) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dir = await getApplicationSupportDirectory();
    final path = join(dir.path, fileName);
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE personas (
              id       INTEGER PRIMARY KEY AUTOINCREMENT,
              nombres  TEXT    NOT NULL,
              apellidos TEXT   NOT NULL,
              ciudad   TEXT    NOT NULL,
              celular  TEXT    NOT NULL,
              peso     REAL    NOT NULL,
              estatura REAL    NOT NULL
            )
          ''');
        },
      ),
    );
  }

  Future<List<Person>> fetchAll() async {
    final db = await database;
    final rows = await db.query('personas', orderBy: 'id DESC');
    return rows.map(Person.fromMap).toList();
  }

  Future<int> insert(Person person) async {
    final db = await database;
    return db.insert('personas', person.toMap());
  }

  Future<int> update(Person person) async {
    final db = await database;
    return db.update(
      'personas',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('personas', where: 'id = ?', whereArgs: [id]);
  }
}
