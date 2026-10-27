// lib/core/services/location/ping_queue.dart
import 'package:path/path.dart' as p;
import 'package:sales_management/features/attendance/models/ping_model.dart';
import 'package:sqflite/sqflite.dart';

class QueuedPing {
  final int rowId;
  final Ping ping;
  QueuedPing(this.rowId, this.ping);
}

class PingQueue {
  final Database _db;
  PingQueue._(this._db);

  static Future<PingQueue> open() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'pings.db'),
      version: 2,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE pings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          trip_id INTEGER NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          accuracy REAL,
          captured_at INTEGER NOT NULL,
          UNIQUE(trip_id, captured_at)
        )'''),
      // Phones that already created the v1 table get the new column.
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE pings ADD COLUMN accuracy REAL');
        }
      },
    );
    return PingQueue._(db);
  }

  Future<void> add(int tripId, Ping ping) => _db.insert(
    'pings',
    {
      'trip_id': tripId,
      'lat': ping.latitude,
      'lng': ping.longitude,
      'accuracy': ping.accuracy,
      'captured_at': (ping.capturedAt ?? DateTime.now()).millisecondsSinceEpoch,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore, // no duplicate rows
  );

  /// Oldest pings first, so the server receives them in order.
  Future<List<QueuedPing>> peek(int tripId, {int limit = 100}) async {
    final rows = await _db.query(
      'pings',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'captured_at ASC',
      limit: limit,
    );
    return rows
        .map(
          (r) => QueuedPing(
        r['id'] as int,
        Ping(
          latitude: r['lat'] as double,
          longitude: r['lng'] as double,
          accuracy: r['accuracy'] as double?,
          capturedAt: DateTime.fromMillisecondsSinceEpoch(r['captured_at'] as int),
        ),
      ),
    )
        .toList();
  }

  Future<void> delete(List<int> ids) {
    if (ids.isEmpty) return Future.value();
    final placeholders = List.filled(ids.length, '?').join(',');
    return _db.delete('pings', where: 'id IN ($placeholders)', whereArgs: ids);
  }

  /// Returns a list of all unique trip IDs currently in the queue,
  /// so the background service can retry sending stranded pings from past trips.
  Future<List<int>> getPendingTripIds() async {
    final rows = await _db.rawQuery('SELECT DISTINCT trip_id FROM pings');
    return rows.map((r) => r['trip_id'] as int).toList();
  }
}