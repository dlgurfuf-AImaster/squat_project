import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/squat_provider.dart';
import '../services/my_bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier {
  final MyBluetoothService _bluetoothService = MyBluetoothService();

  String _connectionStatus = 'DISCONNECTED';
  String get connectionStatus => _connectionStatus;

  /// 듀얼 아두이노 블루투스 연결 시작
  Future<void> startBluetoothWorkout(BuildContext context) async {
    try {
      _connectionStatus = 'CONNECTING';
      notifyListeners();

      await _bluetoothService.connectToDualArduino((waistVec, thighVec) {
        try {
          final squatProvider = context.read<SquatProvider>();
          squatProvider.updateRawData(waistVec, thighVec);
        } catch (e) {
          print("🚨 SquatProvider 업데이트 오류: $e");
        }
      });

      _connectionStatus = 'CONNECTED';
      notifyListeners();
    } catch (error) {
      _connectionStatus = 'DISCONNECTED';
      notifyListeners();

      // UI 렌더링 스택 깨짐 방지를 위해 rethrow 대신 사용자 친화적 String 형태 예외 전달
      throw error.toString().replaceAll("Exception: ", "");
    }
  }

  /// 두 기기 연결 해제
  Future<void> disconnectArduino(SquatProvider squatProvider) async {
    try {
      await _bluetoothService.disconnectFromArduino();
    } finally {
      _connectionStatus = 'DISCONNECTED';
      squatProvider.stopReadingOnDisconnect();
      notifyListeners();
    }
  }
}