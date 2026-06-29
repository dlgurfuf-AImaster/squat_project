import 'package:flutter/material.dart';
import 'package:app/services/my_bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier {
  final MyBluetoothService _bluetoothService = MyBluetoothService();

  // 블루투스 상태 변수
  String _connectionStatus = 'DISCONNECTED'; // DISCONNECTED, CONNECTING, CONNECTED
  String get connectionStatus => _connectionStatus;

  // 🌟 외부에서 센서 데이터를 실시간으로 구독할 수 있도록 콜백 등록장치 마련
  Function(List<double> waistVec, List<double> thighVec)? onDataReceived;

  // 아두이노를 켜고 연결 시작 메서드 (오직 통신에만 집중!)
  Future<void> startBluetoothWorkout() async {
    try {
      _connectionStatus = 'CONNECTING';
      notifyListeners();

      // 아두이노를 찾아 연결 시도
      await _bluetoothService.connectToArduino("BT05", (waistVec, thighVec) {
        // 데이터가 들어오면 등록된 운동 로직 쪽 콜백 함수를 실행시켜 전달함
        if (onDataReceived != null) {
          onDataReceived!(waistVec, thighVec);
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

  // 🌟 블루투스 연결 해제 컨트롤 비즈니스 로직
  Future<void> disconnectArduino() async {
    try {
      // 1. 서비스의 해제 메서드 호출
      await _bluetoothService.disconnectFromArduino();
    } finally {
      // 2. 에러 여부와 상관없이 무조건 앱 상태는 DISCONNECTED로 안전하게 복구
      _connectionStatus = 'DISCONNECTED';
      notifyListeners(); // 📢 UI 화면(ArduinoStatusScreen)에 끊겼다고 소문내기
    }
  }
}