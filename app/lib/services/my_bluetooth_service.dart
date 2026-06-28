import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBluetoothService {
  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? rxCharacteristic;

  // 쪼개져서 들어오는 문자열 조각들을 모아둘 임시 버퍼
  String _dataBuffer = "";

  Future<void> connectToArduino(String deviceName, Function(List<double> w, List<double> t) onDataReceived) async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.device.platformName == deviceName || r.device.remoteId.str == deviceName) {
          targetDevice = r.device;
          FlutterBluePlus.stopScan();

          await targetDevice!.connect();

          List<BluetoothService> services = await targetDevice!.discoverServices();
          for (var service in services) {
            for (var c in service.characteristics) {
              if (c.properties.notify) {
                rxCharacteristic = c;
                await rxCharacteristic!.setNotifyValue(true);

                // 버퍼 초기화
                _dataBuffer = "";

                rxCharacteristic!.lastValueStream.listen((value) {
                  // 1. 들어온 바이트 데이터를 문자열로 변환하여 버퍼에 계속 이어 붙임
                  _dataBuffer += utf8.decode(value);

                  // 2. 버퍼 줄바꿈(\n)이 포함되어 있다면 하나의 완성된 패킷. 정보
                  while (_dataBuffer.contains('\n')) {
                    int newlineIndex = _dataBuffer.indexOf('\n');

                    // 완성된 한 줄
                    String completePacket = _dataBuffer.substring(0, newlineIndex);
                    // 남은 내용은 다시 버퍼에 보관
                    _dataBuffer = _dataBuffer.substring(newlineIndex + 1);

                    // 3. 조립 완료된 깨끗한 패킷만 파싱 함수로 보냄
                    _parseAndSend(completePacket, onDataReceived);
                  }
                });

                print("🎯 블루투스 버퍼 스트림 개통 완료!");
                return;
              }
            }
          }
        }
      }
    });
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
}