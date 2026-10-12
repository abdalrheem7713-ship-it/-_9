
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/device.dart';
import '../models/job.dart';
import '../models/vulnerability.dart';
import '../models/incident.dart';

class LocalDatabase {
  LocalDatabase._privateConstructor();

  static final LocalDatabase instance =
      LocalDatabase._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'nathr.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE devices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        authorized INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE jobs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vulnerabilities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        severity TEXT NOT NULL DEFAULT 'medium',
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE incidents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL DEFAULT 'open',
        priority TEXT NOT NULL DEFAULT 'normal',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        message TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================
  // الأجهزة
  // =========================

  Future<int> insertDevice(Device device) async {
    final db = await database;
    final data = device.toMap()..remove('id');

    return db.insert('devices', data);
  }

  Future<List<Device>> getDevices() async {
    final db = await database;
    final rows = await db.query(
      'devices',
      orderBy: 'id DESC',
    );

    return rows.map(Device.fromMap).toList();
  }

  Future<int> updateDevice(Device device) async {
    if (device.id == null) {
      throw ArgumentError('معرّف الجهاز مطلوب للتعديل');
    }

    final db = await database;
    final data = device.toMap()..remove('id');

    return db.update(
      'devices',
      data,
      where: 'id = ?',
      whereArgs: [device.id],
    );
  }

  Future<int> deleteDevice(int id) async {
    final db = await database;

    return db.delete(
      'devices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // المهام
  // =========================

  Future<int> insertJob(Job job) async {
    final db = await database;
    final data = job.toMap()..remove('id');

    return db.insert('jobs', data);
  }

  Future<List<Job>> getJobs() async {
    final db = await database;
    final rows = await db.query(
      'jobs',
      orderBy: 'id DESC',
    );

    return rows.map(Job.fromMap).toList();
  }

  Future<int> updateJob(Job job) async {
    if (job.id == null) {
      throw ArgumentError('معرّف المهمة مطلوب للتعديل');
    }

    final db = await database;
    final data = job.toMap()..remove('id');

    return db.update(
      'jobs',
      data,
      where: 'id = ?',
      whereArgs: [job.id],
    );
  }

  Future<int> deleteJob(int id) async {
    final db = await database;

    return db.delete(
      'jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // الثغرات
  // =========================

  Future<int> insertVulnerability(
    Vulnerability vulnerability,
  ) async {
    final db = await database;
    final data = vulnerability.toMap()..remove('id');

    return db.insert('vulnerabilities', data);
  }

  Future<List<Vulnerability>> getVulnerabilities() async {
    final db = await database;
    final rows = await db.query(
      'vulnerabilities',
      orderBy: 'id DESC',
    );

    return rows.map(Vulnerability.fromMap).toList();
  }

  Future<int> updateVulnerability(
    Vulnerability vulnerability,
  ) async {
    if (vulnerability.id == null) {
      throw ArgumentError('معرّف الثغرة مطلوب للتعديل');
    }

    final db = await database;
    final data = vulnerability.toMap()..remove('id');

    return db.update(
      'vulnerabilities',
      data,
      where: 'id = ?',
      whereArgs: [vulnerability.id],
    );
  }

  Future<int> deleteVulnerability(int id) async {
    final db = await database;

    return db.delete(
      'vulnerabilities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // القضايا الأمنية
  // =========================

  Future<int> insertIncident(Incident incident) async {
    final db = await database;
    final data = incident.toMap()..remove('id');

    return db.insert('incidents', data);
  }

  Future<List<Incident>> getIncidents() async {
    final db = await database;
    final rows = await db.query(
      'incidents',
      orderBy: 'id DESC',
    );

    return rows.map(Incident.fromMap).toList();
  }

  Future<int> updateIncident(Incident incident) async {
    if (incident.id == null) {
      throw ArgumentError('معرّف القضية مطلوب للتعديل');
    }

    final db = await database;
    final data = incident.toMap()..remove('id');

    return db.update(
      'incidents',
      data,
      where: 'id = ?',
      whereArgs: [incident.id],
    );
  }

  Future<int> deleteIncident(int id) async {
    final db = await database;

    return db.delete(
      'incidents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // السجلات
  // =========================

  Future<int> addLog({
    required String category,
    required String message,
  }) async {
    final db = await database;

    return db.insert('logs', {
      'category': category,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getLogs() async {
    final db = await database;

    return db.query(
      'logs',
      orderBy: 'id DESC',
    );
  }

  Future<int> deleteLog(int id) async {
    final db = await database;

    return db.delete(
      'logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // معلومات عامة
  // =========================

  Future<Map<String, int>> getCounts() async {
    final db = await database;

    final devices = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM devices'),
        ) ??
        0;

    final jobs = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM jobs'),
        ) ??
        0;

    final vulnerabilities = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM vulnerabilities',
          ),
        ) ??
        0;

    final incidents = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM incidents'),
        ) ??
        0;

    return {
      'devices': devices,
      'jobs': jobs,
      'vulnerabilities': vulnerabilities,
      'incidents': incidents,
    };
  }
}