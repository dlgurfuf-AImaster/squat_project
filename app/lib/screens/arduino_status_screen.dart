import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';

class ArduinoStatusScreen extends StatelessWidget {
  const ArduinoStatusScreen({super.key});

  // 장치 연결 수행
  void _startScanAndConnect(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    try {
      await bluetoothProvider.startBluetoothWorkout(context);
    } catch (error) {
      if (!context.mounted) return; // 비동기 작업 후 컨텍스트 유효성 체크
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $error')),
      );
    }
  }

  // 장치 연결 해제 수행
  void _disconnectDevice(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    final squatProvider = context.read<SquatProvider>();

    await bluetoothProvider.disconnectArduino(squatProvider);

    if (!context.mounted) return; // 비동기 작업 후 컨텍스트 유효성 체크
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아두이노 연결이 해제되었습니다.')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONNECTED': return Colors.green;
      case 'CONNECTING': return Colors.orange;
      default: return Colors.red;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CONNECTED': return '아두이노 연결됨';
      case 'CONNECTING': return '연결 시도 중...';
      default: return '연결 끊어짐';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 글로벌 블루투스 연결 상태 관찰
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final String connectionStatus = bluetoothProvider.connectionStatus;
    final bool isConnecting = connectionStatus == 'CONNECTING';

    return Scaffold(
      appBar: AppBar(
        title: const Text('아두이노 연결 관리'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 시각화 카드
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      connectionStatus == 'CONNECTED'
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      size: 40,
                      color: _getStatusColor(connectionStatus),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(connectionStatus),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(connectionStatus),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          connectionStatus == 'CONNECTED'
                              ? '기기명: BT05 (연결됨)'
                              : '연결된 센서 기기가 없습니다.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 중앙 안내 문구 및 인디케이터 영역
            Expanded(
              child: Center(
                child: isConnecting
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('주변의 스쿼트 센서(BT05)를 찾는 중입니다...'),
                  ],
                )
                    : Text(
                  connectionStatus == 'CONNECTED'
                      ? '기기가 정상 연동되었습니다.\n이제 운동 탭으로 이동해 스쿼트를 시작하세요!'
                      : '아래 버튼을 눌러 아두이노 장치와 연결해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),

            // 하단 상태별 제어 버튼 분기
            if (connectionStatus == 'DISCONNECTED') ...[
              ElevatedButton.icon(
                onPressed: () => _startScanAndConnect(context),
                icon: const Icon(Icons.bluetooth),
                label: const Text('아두이노 장치 연결하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),
                ),
              ),
            ] else if (connectionStatus == 'CONNECTED') ...[
              OutlinedButton.icon(
                onPressed: () => _disconnectDevice(context),
                icon: const Icon(Icons.close),
                label: const Text('연결 해제하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.refresh),
                label: const Text('연결을 시도하는 중입니다...'),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, inherit: true),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}