import 'dart:math';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/squat_record.dart';

/// 앱 내부 SQLite 데이터베이스 관리 클래스 (싱글톤 패턴)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // DB 인스턴스 싱글톤 획득
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('squat_records.db');
    return _database!;
  }

  // 디바이스 내 파일 경로에 DB 연결 및 생성
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // 최초 실행 시 squat_records 테이블 생성
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE squat_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        totalCount INTEGER NOT NULL,
        successCount INTEGER NOT NULL,
        waistErrorCount INTEGER NOT NULL,
        depthErrorCount INTEGER NOT NULL,
        fastRepCount INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // 기존 DB를 새로운 구조로 업그레이드
  Future _upgradeDB(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE squat_records
        ADD COLUMN totalCount INTEGER NOT NULL DEFAULT 0
      ''');
    }
  }

  // 스쿼트 운동 기록 1건 저장
  Future<int> insertRecord(SquatRecord record) async {
    final db = await instance.database;
    return await db.insert(
      'squat_records',
      record.toMap(),
    );
  }

  // 전체 운동 기록 조회 (최신순 정렬)
  Future<List<SquatRecord>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query(
      'squat_records',
      orderBy: 'date DESC',
    );

    return result
        .map((json) => SquatRecord.fromMap(json))
        .toList();
  }

  // 백업 성공 시 동기화 상태 업데이트
  Future<int> updateSyncStatus(
      int id,
      bool isSynced,
      ) async {
    final db = await instance.database;

    return await db.update(
      'squat_records',
      {'is_synced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 특정 기록 삭제
  Future<int> deleteRecord(int id) async {
    final db = await instance.database;

    return await db.delete(
      'squat_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 전체 로컬 기록 삭제
  Future<int> deleteAllRecords() async {
    final db = await instance.database;

    return await db.delete('squat_records');
  }

  // 테스트용 로컬 DB 더미 데이터 생성
  Future<void> insertDummyRecords() async {
    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      // 최근 30일 이내 무작위 날짜 및 시간 생성
      final daysAgo = random.nextInt(30);
      final hoursAgo = random.nextInt(24);
      final minutesAgo = random.nextInt(60);

      final recordDate = now.subtract(
        Duration(
          days: daysAgo,
          hours: hoursAgo,
          minutes: minutesAgo,
        ),
      );

      final totalCount = random.nextInt(15) + 5;

      final successCount = random.nextInt(totalCount + 1);

      final record = SquatRecord(
        date: recordDate,
        totalCount: totalCount,
        successCount: successCount,
        waistErrorCount: random.nextInt(10),
        depthErrorCount: random.nextInt(10),
        fastRepCount: random.nextInt(10),
        isSynced: false,
      );

      await insertRecord(record);
    }
  }
}