import 'package:ehr/model/patient.dart';
import 'package:ehr/model/visit.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'clinicconnect.db');

    // DELETE THIS AFTER TESTING - Only for development
    await deleteDatabase(path);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id TEXT PRIMARY KEY,
        firebaseUid TEXT NOT NULL,
        firstName TEXT NOT NULL,
        lastName TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        gender TEXT NOT NULL,
        idNumber TEXT UNIQUE NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT,
        medicalHistory TEXT,
        allergies TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_firebaseUid ON patients(firebaseUid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_isSynced ON patients(isSynced)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_idNumber ON patients(idNumber)',
    );

    // Visits table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visits (
        id TEXT PRIMARY KEY,
        firebaseUid TEXT NOT NULL,
        patientId TEXT NOT NULL,
        patientName TEXT NOT NULL,
        visitDate TEXT NOT NULL,
        chiefComplaint TEXT NOT NULL,
        diagnosis TEXT NOT NULL,
        treatment TEXT NOT NULL,
        prescription TEXT,
        notes TEXT,
        nextFollowUp TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER DEFAULT 0,
        FOREIGN KEY(patientId) REFERENCES patients(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visits_firebaseUid ON visits(firebaseUid)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visits_patientId ON visits(patientId)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visits_isSynced ON visits(isSynced)',
    );
  }

  // ============ PATIENT OPERATIONS ============

  Future<void> insertPatient(Patient patient) async {
    try {
      final db = await database;
      await db.insert(
        'patients',
        patient.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Error inserting patient: $e');
    }
  }

  Future<List<Patient>> getPatientsByUser(String firebaseUid) async {
    try {
      final db = await database;
      final maps = await db.query(
        'patients',
        where: 'firebaseUid = ?',
        whereArgs: [firebaseUid],
        orderBy: 'createdAt DESC',
      );
      return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error fetching patients: $e');
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );
      return maps.isNotEmpty ? Patient.fromMap(maps.first) : null;
    } catch (e) {
      throw DatabaseException('Error fetching patient: $e');
    }
  }

  Future<Patient?> getPatientByIdNumber(String idNumber) async {
    try {
      final db = await database;
      final maps = await db.query(
        'patients',
        where: 'idNumber = ?',
        whereArgs: [idNumber],
      );
      return maps.isNotEmpty ? Patient.fromMap(maps.first) : null;
    } catch (e) {
      throw DatabaseException('Error fetching patient by ID number: $e');
    }
  }

  Future<void> updatePatient(Patient patient) async {
    try {
      final db = await database;
      final updatedPatient = patient.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await db.update(
        'patients',
        updatedPatient.toMap(),
        where: 'id = ?',
        whereArgs: [patient.id],
      );
    } catch (e) {
      throw DatabaseException('Error updating patient: $e');
    }
  }

  Future<void> deletePatient(String id) async {
    try {
      final db = await database;
      await db.delete(
        'patients',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Error deleting patient: $e');
    }
  }

  Future<List<Patient>> getUnsyncedPatients(String firebaseUid) async {
    try {
      final db = await database;
      final maps = await db.query(
        'patients',
        where: 'firebaseUid = ? AND isSynced = 0',
        whereArgs: [firebaseUid],
      );
      return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error fetching unsynced patients: $e');
    }
  }

  Future<void> markPatientAsSynced(String id) async {
    try {
      final db = await database;
      await db.update(
        'patients',
        {'isSynced': 1, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Error marking patient as synced: $e');
    }
  }

  Future<int> getPatientCount(String firebaseUid) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM patients WHERE firebaseUid = ?',
        [firebaseUid],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw DatabaseException('Error getting patient count: $e');
    }
  }

  Future<List<Patient>> searchPatients(
    String firebaseUid,
    String searchTerm,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        'patients',
        where: 'firebaseUid = ? AND (firstName LIKE ? OR lastName LIKE ? OR idNumber LIKE ?)',
        whereArgs: [firebaseUid, '%$searchTerm%', '%$searchTerm%', '%$searchTerm%'],
        orderBy: 'firstName ASC',
      );
      return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error searching patients: $e');
    }
  }

  Future<void> deleteAllPatients(String firebaseUid) async {
    try {
      final db = await database;
      await db.delete(
        'patients',
        where: 'firebaseUid = ?',
        whereArgs: [firebaseUid],
      );
    } catch (e) {
      throw DatabaseException('Error deleting all patients: $e');
    }
  }

  Future<void> insertVisit(Visit visit) async {
    try {
      final db = await database;
      await db.insert(
        'visits',
        visit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw DatabaseException('Error inserting visit: $e');
    }
  }

  Future<List<Visit>> getVisitsByPatient(String patientId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'visits',
        where: 'patientId = ?',
        whereArgs: [patientId],
        orderBy: 'visitDate DESC',
      );
      return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error fetching visits: $e');
    }
  }

  Future<List<Visit>> getVisitsByUser(String firebaseUid) async {
    try {
      final db = await database;
      final maps = await db.query(
        'visits',
        where: 'firebaseUid = ?',
        whereArgs: [firebaseUid],
        orderBy: 'visitDate DESC',
      );
      return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error fetching user visits: $e');
    }
  }

  Future<List<Visit>> getUnsyncedVisits(String firebaseUid) async {
    try {
      final db = await database;
      final maps = await db.query(
        'visits',
        where: 'firebaseUid = ? AND isSynced = 0',
        whereArgs: [firebaseUid],
      );
      return List.generate(maps.length, (i) => Visit.fromMap(maps[i]));
    } catch (e) {
      throw DatabaseException('Error fetching unsynced visits: $e');
    }
  }

  Future<void> markVisitAsSynced(String id) async {
    try {
      final db = await database;
      await db.update(
        'visits',
        {'isSynced': 1, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Error marking visit as synced: $e');
    }
  }

  Future<void> updateVisit(Visit visit) async {
    try {
      final db = await database;
      final updatedVisit = visit.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false,
      );
      await db.update(
        'visits',
        updatedVisit.toMap(),
        where: 'id = ?',
        whereArgs: [visit.id],
      );
    } catch (e) {
      throw DatabaseException('Error updating visit: $e');
    }
  }

  Future<void> deleteVisit(String id) async {
    try {
      final db = await database;
      await db.delete(
        'visits',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw DatabaseException('Error deleting visit: $e');
    }
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}