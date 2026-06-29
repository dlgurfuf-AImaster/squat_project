import 'package:flutter/material.dart';
import 'package:app/services/my_bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier {
  final MyBluetoothService _bluetoothService = MyBluetoothService();

  String _connectionStatus = 'DISCONNECTED';
  String get connectionStatus => _connectionStatus;

  Function(List<double> waistVec, List<double> thighVec)? onDataReceived;

  List<double>? _latestWaistVec;
  List<double>? _latestThighVec;
  List<double>? get latestWaistVec => _latestWaistVec;
  List<double>? get latestThighVec => _latestThighVec;

  // 🌟 변경 포인트: 메서드가 실행될 때 외부(SquatProvider의 수신부) 콜백을 주입받습니다.
  Future<void> startBluetoothWorkout({Function(List<double> w, List<double> t)? onParsedData}) async {
    try {
      _connectionStatus = 'CONNECTING';
      notifyListeners();

      await _bluetoothService.connectToArduino("BT05", (waistVec, thighVec) {
        _latestWaistVec = waistVec;
        _latestThighVec = thighVec;

        // 1. 기존에 클래스 내부 필드에 등록된 콜백이 있다면 실행
        if (onDataReceived != null) {
          onDataReceived!(waistVec, thighVec);
        }

        // 🌟 2. 메서드 인자로 들어온 실시간 파이프라인 콜백(SquatProvider)으로 데이터 토스!
        if (onParsedData != null) {
          onParsedData(waistVec, thighVec);
        }
      });

      _connectionStatus = 'CONNECTED';
      notifyListeners();
    } catch (error) {
      _connectionStatus = 'DISCONNECTED';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnectArduino() async {
    try {
      await _bluetoothService.disconnectFromArduino();
    } finally {
      _connectionStatus = 'DISCONNECTED';
      notifyListeners();
    }
  }
}