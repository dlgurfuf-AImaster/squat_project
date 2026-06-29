import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/squat_provider.dart';
import '../providers/bluetooth_provider.dart';

class ArduinoStatusScreen extends StatefulWidget {
  const ArduinoStatusScreen({super.key});

  @override
  State<ArduinoStatusScreen> createState() => _ArduinoStatusScreenState();
}

class _ArduinoStatusScreenState extends State<ArduinoStatusScreen> {

  // 1. [요구사항 1] 버튼으로 블루투스 연결 수행
  void _startScanAndConnect() async {
    final bluetoothProvider = context.read<BluetoothProvider>();
    final squatProvider = context.read<SquatProvider>(); // 🌟 운동 프로바이더 가져오기

    try {
      // 🌟 연결을 시작할 때 운동 타워의 updateRawData 함수를 커넥터로 결합!
      await bluetoothProvider.startBluetoothWorkout(
        onParsedData: (w, t) => squatProvider.updateRawData(w, t),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $error')),
      );
    }
  }

  // 3. [요구사항 3] 연결 끊기 버튼 클릭 시 실행되는 함수 수정
  void _disconnectDevice() async {
    final bluetoothProvider = context.read<BluetoothProvider>();

    // 프로바이더의 연결 해제 실행 (로딩이나 예외처리가 필요하면 async/await 활용)
    await bluetoothProvider.disconnectArduino();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('아두이노 연결이 해제되었습니다.')),
    );
  }

  // 2. [요구사항 2] 상태에 따른 색상 및 텍스트 매핑 가이드 함수
  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONNECTED': return Colors.green;
      case 'CONNECTING': return Colors.orange;
      case 'DISCONNECTED':
      default: return Colors.red;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'CONNECTED': return '아두이노 연결됨';
      case 'CONNECTING': return '연결 시도 중...';
      case 'DISCONNECTED':
      default: return '연결 끊어짐';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 중요: 블루투스 상태를 들고 있는 진짜 'BluetoothProvider'를 관찰(watch)합니다.
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final String connectionStatus = bluetoothProvider.connectionStatus;

    // 현재 스캔 중인지는 상태가 'CONNECTING'일 때 로딩바를 보여주는 것으로 대체합니다.
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
            // 요구사항 2: 현재 상태를 시각적으로 확인할 수 있는 상단 카드 영역
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

            // 중앙 상태 표시 정보 및 가이드 문구
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

            // 4. 요구사항 1 & 3: 하단 제어 버튼 영역 수정
            if (connectionStatus == 'DISCONNECTED') ...[
              // 1. 새로운 아두이노 장치 연결하기 버튼
              ElevatedButton.icon(
                onPressed: _startScanAndConnect,
                icon: const Icon(Icons.bluetooth),
                label: const Text('아두이노 장치 연결하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  // 🌟 여기에 명시적으로 TextStyle 구조를 선언해 줍니다.
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    inherit: true, // 👈 상속 여부를 명시
                  ),
                ),
              ),
            ] else if (connectionStatus == 'CONNECTED') ...[
              // 2. 연결 해제하기 버튼
              OutlinedButton.icon(
                onPressed: _disconnectDevice,
                icon: const Icon(Icons.close),
                label: const Text('연결 해제하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    inherit: true, // 👈 동일하게 맞춰줍니다.
                  ),
                ),
              ),
            ] else ...[
              // 3. 연결 시도 중(CONNECTING)일 때 보여주는 비활성화 버튼
              ElevatedButton.icon(
                onPressed: null, // 비활성화 상태
                icon: const Icon(Icons.refresh),
                label: const Text('연결을 시도하는 중입니다...'),
                style: ElevatedButton.styleFrom(
                  // 비활성화 상태일 때의 스타일도 명시적으로 결을 맞춰줍니다.
                  disabledBackgroundColor: Colors.grey[300],
                  disabledForegroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    inherit: true, // 👈 동일하게 맞춰줍니다.
                  ),
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