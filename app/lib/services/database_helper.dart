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
      version: 1,
      onCreate: _createDB,
    );
  }

  // 최초 실행 시 squat_records 테이블 생성
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE squat_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        successCount INTEGER NOT NULL,
        waistErrorCount INTEGER NOT NULL,
        depthErrorCount INTEGER NOT NULL,
        goodMorningCount INTEGER NOT NULL
      )
    ''');
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

  // 🗑️ 3. 특정 기록 삭제 (옵션)
  Future<int> deleteRecord(int id) async {
    final db = await instance.database;
    return await db.delete(
      'squat_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}