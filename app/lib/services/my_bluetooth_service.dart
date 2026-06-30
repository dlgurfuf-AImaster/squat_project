import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? rxCharacteristic;

  String _dataBuffer = "";
  StreamSubscription<List<int>>? _characterStreamSubscription;

  /// 최대 데이터 버퍼 용량 제한 (메모리 오버플로우 방지 장치: 약 4KB)
  static const int _maxBufferLength = 4096;

  /// 아두이노 블루투스 기기 스캔 및 최종 물리 소켓 연결
  Future<void> connectToArduino(String deviceName, Function(List<double> w, List<double> t) onDataReceived) async {
    final Completer<void> connectionCompleter = Completer<void>();

    print("🔎 주변 블루투스 기기 스캔 시작...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));

    StreamSubscription<List<ScanResult>>? scanSubscription;

    scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final String pName = r.device.platformName;
        final String rId = r.device.remoteId.str;

        // 기기 매칭 검증
        if (pName != deviceName && rId != deviceName) continue;

        print("🎯 기기 발견: $pName [$rId]");
        targetDevice = r.device;

        // 기기를 찾은 즉시 스캔 리소스 자원 전체 해제
        await FlutterBluePlus.stopScan();
        await scanSubscription?.cancel();
        scanSubscription = null;

        try {
          print("⚡ 아두이노에 물리적 연결 시도 중...");
          await targetDevice!.connect();

          print("📂 서비스 및 캐릭터리스틱 탐색 중...");
          List<BluetoothService> services = await targetDevice!.discoverServices();

          for (var service in services) {
            for (var c in service.characteristics) {
              // Notify 속성이 없는 특성은 패스 (Early Return)
              if (!c.properties.notify) continue;

              rxCharacteristic = c;
              await rxCharacteristic!.setNotifyValue(true);
              _dataBuffer = "";

              // [생명주기 최적화] 기존에 고립되어 잔존하던 스트림 완벽 폐기
              if (_characterStreamSubscription != null) {
                await _characterStreamSubscription!.cancel();
                _characterStreamSubscription = null;
              }

              // 실시간 하드웨어 데이터 파이프라인 신규 개통
              _characterStreamSubscription = rxCharacteristic!.lastValueStream.listen((value) {
                // 방어 코드: 버퍼가 비정상적으로 커지면 강제 초기화
                if (_dataBuffer.length > _maxBufferLength) {
                  _dataBuffer = "";
                }

                _dataBuffer += utf8.decode(value);

                while (_dataBuffer.contains('\n')) {
                  int newlineIndex = _dataBuffer.indexOf('\n');
                  String completePacket = _dataBuffer.substring(0, newlineIndex);
                  _dataBuffer = _dataBuffer.substring(newlineIndex + 1);
                  _parseAndSend(completePacket, onDataReceived);
                }
              });

              print("🟢 [연결 완전 성공] 블루투스 소켓 및 데이터 스트림 개통 완료!");
              connectionCompleter.complete();
              return;
            }
          }
        } catch (e) {
          print("❌ 연결 도중 에러 발생: $e");
          connectionCompleter.completeError("기기 연결 실패: $e");
        }
      }
    });

    // 7초 타임아웃 예외 안전장치
    Future.delayed(const Duration(seconds: 7), () async {
      if (!connectionCompleter.isCompleted) {
        await FlutterBluePlus.stopScan();
        await scanSubscription?.cancel();
        connectionCompleter.completeError("주변에 '$deviceName' 기기를 찾을 수 없습니다.");
      }
    });

    return connectionCompleter.future;
  }

  /// 데이터 패킷을 분해 및 가공하여 콜백으로 라우팅 (비즈니스 서브 로직)
  void _parseAndSend(String raw, Function(List<double> w, List<double> t) callback) {
    try {
      String cleanRaw = raw.trim();
      if (cleanRaw.isEmpty || !cleanRaw.contains('\$')) return;

      int startSignIndex = cleanRaw.indexOf('\$');
      String dataPart = cleanRaw.substring(startSignIndex + 1);

      List<String> sensors = dataPart.split('|');
      if (sensors.length != 2) return;

      List<String> waistRaw = sensors[0].split(',');
      List<String> thighRaw = sensors[1].split(',');

      if (waistRaw.length == 3 && thighRaw.length == 3) {
        List<double> waistVec = waistRaw.map((e) => double.parse(e)).toList();
        List<double> thighVec = thighRaw.map((e) => double.parse(e)).toList();

        callback(waistVec, thighVec);
      }
    } catch (e) {
      print("⚠️ 패킷 조립 및 파싱 스킵: $e");
    }
  }

  /// 아두이노 물리 소켓 연결 해제 및 리소스 완전 릴리즈
  Future<void> disconnectFromArduino() async {
    try {
      if (_characterStreamSubscription != null) {
        await _characterStreamSubscription!.cancel();
        _characterStreamSubscription = null;
      }

      if (rxCharacteristic != null) {
        await rxCharacteristic!.setNotifyValue(false);
        rxCharacteristic = null;
      }

      if (targetDevice != null) {
        await targetDevice!.disconnect();
        targetDevice = null;
      }
    } catch (e) {
      print("연결 해제 중 오류 발생: $e");
    } finally {
      // 에러 유무와 상관없이 최종 메모리 변수 원점 버퍼 비우기 보장
      _characterStreamSubscription = null;
      rxCharacteristic = null;
      targetDevice = null;
      _dataBuffer = "";
      print("아두이노 블루투스 리소스 반환 완료");
    }
  }
}