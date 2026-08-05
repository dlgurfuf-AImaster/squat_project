import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  BluetoothDevice? waistDevice;
  BluetoothDevice? thighDevice;

  BluetoothCharacteristic? waistRxChar;
  BluetoothCharacteristic? thighRxChar;

  StreamSubscription<List<int>>? _waistStreamSub;
  StreamSubscription<List<int>>? _thighStreamSub;

  String _waistBuffer = "";
  String _thighBuffer = "";

  List<double>? _latestWaistVec;
  List<double>? _latestThighVec;

  static const int _maxBufferLength = 4096; // 최대 데이터 버퍼 용량 제한

  /// 허리(BT05_WAIST) 및 허벅지(BT05_THIGH) 기기 동시 스캔 및 연결
  Future<void> connectToDualArduino(
      Function(List<double> w, List<double> t) onDataReceived) async {
    final Completer<void> connectionCompleter = Completer<void>();

    print("🔎 센서 모듈(BT05_WAIST, BT05_THIGH) 동시 스캔 시작...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    StreamSubscription<List<ScanResult>>? scanSubscription;

    scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        final String pName = r.device.platformName;

        if (pName == "BT05_WAIST" && waistDevice == null) {
          print("🎯 허리 센서 발견: $pName");
          waistDevice = r.device;
        } else if (pName == "BT05_THIGH" && thighDevice == null) {
          print("🎯 허벅지 센서 발견: $pName");
          thighDevice = r.device;
        }

        // 두 기기를 모두 찾은 경우 스캔 중단 및 물리 연결 시작
        if (waistDevice != null && thighDevice != null) {
          await FlutterBluePlus.stopScan();
          await scanSubscription?.cancel();
          scanSubscription = null;

          try {
            print("⚡ 두 센서 보드와 물리 연결 및 통로 개통 중...");
            await Future.wait([
              _connectAndSetupChar(waistDevice!, isWaist: true, onDataReceived: onDataReceived),
              _connectAndSetupChar(thighDevice!, isWaist: false, onDataReceived: onDataReceived),
            ]);

            print("🟢 [연결 성공] 허리 및 허벅지 블루투스 세션 개통 완료!");
            connectionCompleter.complete();
            return;
          } catch (e) {
            connectionCompleter.completeError("기기 연결 실패: $e");
          }
        }
      }
    });

    // 타임아웃 예외 처리
    Future.delayed(const Duration(seconds: 8), () async {
      if (!connectionCompleter.isCompleted) {
        await FlutterBluePlus.stopScan();
        await scanSubscription?.cancel();

        List<String> missing = [];
        if (waistDevice == null) missing.add("BT05_WAIST");
        if (thighDevice == null) missing.add("BT05_THIGH");

        connectionCompleter.completeError("주변에서 다음 기기를 찾을 수 없습니다: ${missing.join(', ')}");
      }
    });

    return connectionCompleter.future; // 비동기 처리 중
  }

  /// 단일 디바이스 연결 및 Rx 특성 구독 설정
  Future<void> _connectAndSetupChar(BluetoothDevice device,
      {required bool isWaist, required Function(List<double> w, List<double> t) onDataReceived}) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();

    for (var service in services) {
      for (var c in service.characteristics) {
        if (!c.properties.notify) continue;

        if (isWaist) {
          waistRxChar = c;
          await waistRxChar!.setNotifyValue(true);
          _waistBuffer = "";
          await _waistStreamSub?.cancel();

          _waistStreamSub = waistRxChar!.lastValueStream.listen((value) {
            if (_waistBuffer.length > _maxBufferLength) _waistBuffer = "";
            _waistBuffer += utf8.decode(value);
            _processBuffer(isWaist: true, onDataReceived: onDataReceived);
          });
        } else {
          thighRxChar = c;
          await thighRxChar!.setNotifyValue(true);
          _thighBuffer = "";
          await _thighStreamSub?.cancel();

          _thighStreamSub = thighRxChar!.lastValueStream.listen((value) {
            if (_thighBuffer.length > _maxBufferLength) _thighBuffer = "";
            _thighBuffer += utf8.decode(value);
            _processBuffer(isWaist: false, onDataReceived: onDataReceived);
          });
        }
        return;
      }
    }
  }

  /// 버퍼 단위 개행 문자 자르기 및 벡터 병합
  void _processBuffer({required bool isWaist, required Function(List<double> w, List<double> t) onDataReceived}) {
    String buffer = isWaist ? _waistBuffer : _thighBuffer;

    while (buffer.contains('\n')) {
      int newlineIndex = buffer.indexOf('\n');
      String completePacket = buffer.substring(0, newlineIndex);
      buffer = buffer.substring(newlineIndex + 1);

      _parsePacket(completePacket, isWaist: isWaist);
    }

    if (isWaist) {
      _waistBuffer = buffer;
    } else {
      _thighBuffer = buffer;
    }

    // 두 센서의 최신 가속도 벡터가 모두 수신되었을 때 통합 콜백 호출
    if (_latestWaistVec != null && _latestThighVec != null) {
      onDataReceived(_latestWaistVec!, _latestThighVec!);
    }
  }

  /// "$W|x,y,z" 및 "$T|x,y,z" 패킷 파싱
  void _parsePacket(String raw, {required bool isWaist}) {
    try {
      String cleanRaw = raw.trim();
      String expectedPrefix = isWaist ? "\$W|" : "\$T|";

      if (!cleanRaw.startsWith(expectedPrefix)) return;

      String dataPart = cleanRaw.substring(expectedPrefix.length);
      List<String> values = dataPart.split(',');

      if (values.length == 3) {
        List<double> vec = values.map((e) => double.parse(e)).toList();
        if (isWaist) {
          _latestWaistVec = vec;
        } else {
          _latestThighVec = vec;
        }
      }
    } catch (e) {
      print("⚠️ 패킷 파싱 스킵 ($raw): $e");
    }
  }

  /// 자원 해제
  Future<void> disconnectFromArduino() async {
    try {
      await _waistStreamSub?.cancel();
      await _thighStreamSub?.cancel();

      if (waistRxChar != null) await waistRxChar!.setNotifyValue(false);
      if (thighRxChar != null) await thighRxChar!.setNotifyValue(false);

      if (waistDevice != null) await waistDevice!.disconnect();
      if (thighDevice != null) await thighDevice!.disconnect();
    } catch (e) {
      print("연결 해제 처리 중 오류: $e");
    } finally {
      _waistStreamSub = null;
      _thighStreamSub = null;
      waistRxChar = null;
      thighRxChar = null;
      waistDevice = null;
      thighDevice = null;
      _latestWaistVec = null;
      _latestThighVec = null;
      _waistBuffer = "";
      _thighBuffer = "";
      print("듀얼 블루투스 리소스 반환 완료");
    }
  }
}