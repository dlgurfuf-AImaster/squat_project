import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? rxCharacteristic;
  String _dataBuffer = "";

  // 🌟 Future<void>가 진짜 연결 완료 시점을 보장하도록 수정
  Future<void> connectToArduino(String deviceName, Function(List<double> w, List<double> t) onDataReceived) async {

    // 비동기 작업을 수동으로 제어하기 위한 완료 신호기
    final Completer<void> connectionCompleter = Completer<void>();

    print("🔎 주변 블루투스 기기 스캔 시작...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));

    // 스캔 리스트 구독
    StreamSubscription<List<ScanResult>>? subscription;
    subscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // 기기 이름이나 ID가 매칭되는지 확인
        if (r.device.platformName == deviceName || r.device.remoteId.str == deviceName) {
          print("🎯 기기 발견: ${r.device.platformName} [${r.device.remoteId.str}]");

          targetDevice = r.device;
          FlutterBluePlus.stopScan();
          subscription?.cancel(); // 스캔 구독 해제

          try {
            print("⚡ 아두이노에 물리적 연결 시도 중...");
            await targetDevice!.connect();

            print("📂 서비스 및 캐릭터리스틱 탐색 중...");
            List<BluetoothService> services = await targetDevice!.discoverServices();
            for (var service in services) {
              for (var c in service.characteristics) {
                if (c.properties.notify) {
                  rxCharacteristic = c;
                  await rxCharacteristic!.setNotifyValue(true);

                  _dataBuffer = "";
                  rxCharacteristic!.lastValueStream.listen((value) {
                    _dataBuffer += utf8.decode(value);
                    while (_dataBuffer.contains('\n')) {
                      int newlineIndex = _dataBuffer.indexOf('\n');
                      String completePacket = _dataBuffer.substring(0, newlineIndex);
                      _dataBuffer = _dataBuffer.substring(newlineIndex + 1);
                      _parseAndSend(completePacket, onDataReceived);
                    }
                  });

                  print("🟢 [연결 완전 성공] 블루투스 소켓 및 데이터 스트림 개통 완료!");
                  connectionCompleter.complete(); // 📢 기다리던 await에게 성공 신호 전달!
                  return;
                }
              }
            }
          } catch (e) {
            print("❌ 연결 도중 에러 발생: $e");
            connectionCompleter.completeError("기기 연결 실패: $e");
          }
        }
      }
    });

    // 🌟 7초 동안 기기를 아예 못 찾았을 때의 타임아웃 예외 처리
    Future.delayed(const Duration(seconds: 7), () {
      if (!connectionCompleter.isCompleted) {
        FlutterBluePlus.stopScan();
        subscription?.cancel();
        connectionCompleter.completeError("주변에 '$deviceName' 기기를 찾을 수 없습니다. 아두이노 전원을 확인하세요.");
      }
    });

    // 🌟 중요: 주입된 completer가 complete() 될 때까지 이 함수는 여기서 딱 멈춰서 기다립니다!
    return connectionCompleter.future;
  }

  void _parseAndSend(String raw, Function(List<double> w, List<double> t) callback) {
    try {
      String cleanRaw = raw.trim();

      // 패킷 시작 기호($) 검증
      if (cleanRaw.isEmpty || !cleanRaw.contains('\$')) return;

      // '$'의 위치를 찾아서 그 뒤 잘라내기
      int startSignIndex = cleanRaw.indexOf('\$');
      String dataPart = cleanRaw.substring(startSignIndex + 1);

      List<String> sensors = dataPart.split('|');
      if (sensors.length != 2) return;

      List<String> waistRaw = sensors[0].split(',');
      List<String> thighRaw = sensors[1].split(',');

      if (waistRaw.length == 3 && thighRaw.length == 3) {
        List<double> waistVec = waistRaw.map((e) => double.parse(e)).toList();
        List<double> thighVec = thighRaw.map((e) => double.parse(e)).toList();

        // UI와 연산 프로세서로 데이터 최종 전송
        callback(waistVec, thighVec);
      }
    } catch (e) {
      // 파싱 실패하더라도 튕기지 않고 다음 패킷을 기다림
      print("⚠️ 패킷 조립 및 파싱 스킵: $e");
    }
  }

  Future<void> disconnectFromArduino() async {
    try {
      if (rxCharacteristic != null) {
        await rxCharacteristic!.setNotifyValue(false);
        rxCharacteristic = null;
      }

      // 물리적인 블루투스 연결 해제
      if (targetDevice != null) {
        await targetDevice!.disconnect();
        targetDevice = null;
      }

      _dataBuffer = "";
      print("아두이노 블루투스 연결이 해제되었음");
    } catch (e) {
      print("연결 해제 중 오류 발생: $e");
      rxCharacteristic = null;
      targetDevice = null;
      _dataBuffer = "";
    }
  }
}