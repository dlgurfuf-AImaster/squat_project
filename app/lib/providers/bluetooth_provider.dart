import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/providers/squat_provider.dart';
import 'package:app/services/my_bluetooth_service.dart';

class BluetoothProvider with ChangeNotifier {
  final MyBluetoothService _bluetoothService = MyBluetoothService();

  String _connectionStatus = 'DISCONNECTED';
  String get connectionStatus => _connectionStatus;

  /// 아두이노 블루투스 연결 및 데이터 흐름 개통
  Future<void> startBluetoothWorkout(BuildContext context) async {
    try {
      _connectionStatus = 'CONNECTING';
      notifyListeners();

      // 블루투스 기기(BT05) 연결 및 실시간 데이터 바인딩 시도
      await _bluetoothService.connectToArduino("BT05", (waistVec, thighVec) {
        try {
          // 실시간으로 유입되는 원본 센서 데이터를 현재 활성화된 SquatProvider로 전송
          final squatProvider = context.read<SquatProvider>();
          squatProvider.updateRawData(waistVec, thighVec);
        } catch (e) {
          print("🚨 스트림 내부에서 SquatProvider 호출 실패: $e");
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

  /// 아두이노 연결 해제 및 상위 상태 원점 복구
  Future<void> disconnectArduino(SquatProvider squatProvider) async {
    try {
      // 1) 하드웨어 연결 및 소켓 스트림 완전 종료 (Service 내부에서 취소 처리됨)
      await _bluetoothService.disconnectFromArduino();
    } finally {
      // 2) 프로바이더 연결 상태 값 갱신
      _connectionStatus = 'DISCONNECTED';

      // 3) 운동 중이던 상태 스위치를 강제로 내림 (안전장치 구동)
      squatProvider.stopReadingOnDisconnect();

      notifyListeners();
    }
  }
}