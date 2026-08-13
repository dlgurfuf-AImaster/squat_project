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
      version: 2, // DB 버전을 1에서 2로 업그레이드
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // 버전 업그레이드 마이그레이션 콜백 등록
    );
  }

  // 최초 실행 시 squat_records 테이블 생성
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE squat_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        successCount INTEGER NOT NULL,
        waistErrorCount INTEGER NOT NULL,
        depthErrorCount INTEGER NOT NULL,
        goodMorningCount INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
  }

  // 기존 사용자를 위한 DB 마이그레이션 함수 (v1 -> v2 -> v3)
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE squat_records ADD COLUMN uuid TEXT',
      );
    }
  }

  // 📥 1. 스쿼트 운동 기록 1건 저장
  Future<int> insertRecord(SquatRecord record) async {
    final db = await instance.database;
    return await db.insert('squat_records', record.toMap());
  }

  // 📤 2. 전체 운동 기록 조회 (최신순 정렬)
  Future<List<SquatRecord>> getAllRecords() async {
    final db = await instance.database;
    final result = await db.query('squat_records', orderBy: 'date DESC');

    return result.map((json) => SquatRecord.fromMap(json)).toList();
  }

  // 🔄 3. 백업 성공 시 동기화 상태 업데이트 메서드
  Future<int> updateSyncStatus(int id, bool isSynced) async {
    final db = await instance.database;
    return await db.update(
      'squat_records',
      {'is_synced': isSynced ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🗑️ 4. 특정 기록 삭제 (옵션)
  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'squat_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// TODO 🧪 [테스트용] 로컬 DB에 더미 스쿼트 데이터 30개 생성 (is_synced = 0) (삭제할 것)
  Future<void> insertDummyRecords() async {
    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 30; i++) {
      // 최근 30일 이내 무작위 날짜 및 시간 생성
      final daysAgo = random.nextInt(30);
      final hoursAgo = random.nextInt(24);
      final minutesAgo = random.nextInt(60);
      final recordDate = now.subtract(
        Duration(days: daysAgo, hours: hoursAgo, minutes: minutesAgo),
      );

      final record = SquatRecord(
        date: recordDate,
        successCount: random.nextInt(15) + 5,   // 5 ~ 19회 성공
        waistErrorCount: random.nextInt(5),     // 0 ~ 4회 오류
        depthErrorCount: random.nextInt(5),     // 0 ~ 4회 오류
        goodMorningCount: random.nextInt(4),   // 0 ~ 3회 오류
        isSynced: false,                        // 💡 미전송(0) 상태로 설정
      );

      await insertRecord(record);
    }
  }
}