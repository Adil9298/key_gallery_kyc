import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/customers/models/customer_model.dart';

class DBHelper {
  DBHelper._();

  static final DBHelper instance = DBHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();

    return _database!;
  }

  Future<Database> _initDB() async {
    final Directory appDir =
    await getApplicationDocumentsDirectory();

    final String dbPath =
    join(appDir.path, 'key_gallery_kyc.db');

    return await openDatabase(
      dbPath,
      version: 3, // increased version
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_name TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT,
        aadhar_number TEXT,
        pincode TEXT,
        vehicle_type TEXT,
        vehicle_model_name TEXT,
        vehicle_number TEXT,
        key_cutting_number TEXT,
        customer_photo TEXT,
        rc_photo TEXT,
        aadhar_front_photo TEXT,
        aadhar_back_photo TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_phone ON customers(phone);',
    );

    await db.execute(
      'CREATE INDEX idx_vehicle_number ON customers(vehicle_number);',
    );

    await db.execute(
      'CREATE INDEX idx_vehicle_model_name ON customers(vehicle_model_name);',
    );

    await db.execute(
      'CREATE INDEX idx_key_cutting_number ON customers(key_cutting_number);',
    );

    await db.execute(
      'CREATE INDEX idx_created_at ON customers(created_at);',
    );
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    // Version 2 migration
    if (oldVersion < 2) {
      final columns =
      await db.rawQuery('PRAGMA table_info(customers)');

      final keyExists = columns.any(
            (c) => c['name'] == 'key_cutting_number',
      );

      if (!keyExists) {
        await db.execute(
          'ALTER TABLE customers ADD COLUMN key_cutting_number TEXT',
        );
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_key_cutting_number ON customers(key_cutting_number);',
      );
    }

    // Version 3 migration
    if (oldVersion < 3) {
      final columns =
      await db.rawQuery('PRAGMA table_info(customers)');

      final modelExists = columns.any(
            (c) => c['name'] == 'vehicle_model_name',
      );

      if (!modelExists) {
        await db.execute(
          'ALTER TABLE customers ADD COLUMN vehicle_model_name TEXT',
        );
      }

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_vehicle_model_name ON customers(vehicle_model_name);',
      );
    }
  }

  // INSERT
  Future<int> insertCustomer(
      CustomerModel customer) async {
    final db = await database;

    return await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // UPDATE
  Future<int> updateCustomer(
      CustomerModel customer) async {
    final db = await database;

    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // DELETE
  Future<int> deleteCustomer(int id) async {
    final db = await database;

    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // GET BY ID
  Future<CustomerModel?> getCustomerById(
      int id) async {
    final db = await database;

    final result = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return CustomerModel.fromMap(result.first);
    }

    return null;
  }

  // GET ALL
  Future<List<CustomerModel>>
  getAllCustomers() async {
    final db = await database;

    final result = await db.query(
      'customers',
      orderBy: 'created_at DESC',
    );

    return result
        .map((e) => CustomerModel.fromMap(e))
        .toList();
  }

  // SEARCH
  Future<List<CustomerModel>> searchCustomers(
      String query) async {
    final db = await database;

    final result = await db.query(
      'customers',
      where: '''
        customer_name LIKE ?
        OR phone LIKE ?
        OR vehicle_number LIKE ?
        OR vehicle_model_name LIKE ?
        OR key_cutting_number LIKE ?
        OR aadhar_number LIKE ?
      ''',
      whereArgs: [
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
        '%$query%',
      ],
      orderBy: 'created_at DESC',
    );

    return result
        .map((e) => CustomerModel.fromMap(e))
        .toList();
  }

  // DATE RANGE FILTER
  Future<List<CustomerModel>>
  getCustomersByDateRange(
      DateTime start,
      DateTime end,
      ) async {
    final db = await database;

    final result = await db.query(
      'customers',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'created_at DESC',
    );

    return result
        .map((e) => CustomerModel.fromMap(e))
        .toList();
  }

  // TODAY
  Future<List<CustomerModel>>
  getTodayCustomers() async {
    final now = DateTime.now();

    final start =
    DateTime(now.year, now.month, now.day);

    final end = start.add(const Duration(days: 1));

    return getCustomersByDateRange(start, end);
  }

  // THIS WEEK
  Future<List<CustomerModel>>
  getThisWeekCustomers() async {
    final now = DateTime.now();

    final start =
    now.subtract(Duration(days: now.weekday - 1));

    final weekStart =
    DateTime(start.year, start.month, start.day);

    final end =
    weekStart.add(const Duration(days: 7));

    return getCustomersByDateRange(weekStart, end);
  }

  // THIS MONTH
  Future<List<CustomerModel>>
  getThisMonthCustomers() async {
    final now = DateTime.now();

    final start = DateTime(now.year, now.month, 1);

    final end =
    DateTime(now.year, now.month + 1, 1);

    return getCustomersByDateRange(start, end);
  }

  // PREVIOUS MONTH
  Future<List<CustomerModel>>
  getPreviousMonthCustomers() async {
    final now = DateTime.now();

    final start =
    DateTime(now.year, now.month - 1, 1);

    final end = DateTime(now.year, now.month, 1);

    return getCustomersByDateRange(start, end);
  }

  // THIS QUARTER
  Future<List<CustomerModel>>
  getThisQuarterCustomers() async {
    final now = DateTime.now();

    final quarter = ((now.month - 1) ~/ 3);

    final startMonth = quarter * 3 + 1;

    final start =
    DateTime(now.year, startMonth, 1);

    final end =
    DateTime(now.year, startMonth + 3, 1);

    return getCustomersByDateRange(start, end);
  }

  // THIS YEAR
  Future<List<CustomerModel>>
  getThisYearCustomers() async {
    final now = DateTime.now();

    final start = DateTime(now.year, 1, 1);

    final end = DateTime(now.year + 1, 1, 1);

    return getCustomersByDateRange(start, end);
  }

  // COUNT
  Future<int> getCustomerCount() async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CLOSE DB
  Future<void> close() async {
    final db = await database;

    await db.close();
  }
}