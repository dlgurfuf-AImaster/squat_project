import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';

class ArduinoStatusScreen extends StatelessWidget {
  const ArduinoStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final String connectionStatus = bluetoothProvider.connectionStatus;
    final bool isConnecting = connectionStatus == 'CONNECTING';
    final bool isConnected = connectionStatus == 'CONNECTED';

    return Scaffold(
      appBar: AppBar(
        title: const Text('아두이노 연결 관리'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 허리 센서 카드
              _buildDeviceCard(
                title: '허리 센서 (BT05_WAIST)',
                deviceName: 'BT05_WAIST',
                isConnected: isConnected,
              ),
              const SizedBox(height: 15),

              // 2. 허벅지 센서 카드
              _buildDeviceCard(
                title: '허벅지 센서 (BT05_THIGH)',
                deviceName: 'BT05_THIGH',
                isConnected: isConnected,
              ),
              const SizedBox(height: 20),

              // 3. 중앙 안내 영역 (Expanded 레이아웃 안정화)
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isConnecting) ...[
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          const Text(
                            'BT05_WAIST 및 BT05_THIGH 센서를\n찾고 연결하는 중입니다...',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.black87),
                          ),
                        ] else ...[
                          Icon(
                            isConnected ? Icons.check_circle_outline : Icons.bluetooth_searching,
                            size: 60,
                            color: isConnected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isConnected
                                ? '두 센서가 모두 연결되었습니다!\n운동 탭에서 스쿼트를 시작하세요.'
                                : '아래 버튼을 눌러 센서 연결을 시작하세요.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 4. 하단 동작 버튼 (TextStyle 충돌 원인 제거)
              _buildActionButton(
                context: context,
                isConnecting: isConnecting,
                isConnected: isConnected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상태별 하단 버튼 생성 (TextStyle 애니메이션 에러 방지)
  Widget _buildActionButton({
    required BuildContext context,
    required bool isConnecting,
    required bool isConnected,
  }) {
    if (isConnecting) {
      return ElevatedButton.icon(
        onPressed: null, // 비활성화 상태
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text(
          '센서 연결 시도 중...',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      );
    }

    if (isConnected) {
      return OutlinedButton.icon(
        onPressed: () => _disconnectDevice(context),
        icon: const Icon(Icons.power_settings_new),
        label: const Text(
          '모든 연결 해제하기',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Colors.red),
          foregroundColor: Colors.red,
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _startScanAndConnect(context),
      icon: const Icon(Icons.bluetooth_searching),
      label: const Text(
        '센서 모듈 연결하기',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required String deviceName,
    required bool isConnected,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              size: 32,
              color: isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? '연결됨 (통신 중)' : '미연결',
                  style: TextStyle(
                    color: isConnected ? Colors.green[700] : Colors.grey[600],
                    fontWeight: isConnected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startScanAndConnect(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    try {
      await bluetoothProvider.startBluetoothWorkout(context);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연결 실패: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _disconnectDevice(BuildContext context) async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    final squatProvider = context.read<SquatProvider>();

    await bluetoothProvider.disconnectArduino(squatProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('모든 아두이노 연결이 해제되었습니다.')),
    );
  }
}