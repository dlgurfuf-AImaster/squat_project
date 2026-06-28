import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/squat_provider.dart';

class ArduinoStatusScreen extends StatefulWidget {
  const ArduinoStatusScreen({super.key});

  @override
  State<ArduinoStatusScreen> createState() => _ArduinoStatusScreenState();
}

class _ArduinoStatusScreenState extends State<ArduinoStatusScreen> {
  // 가상의 블루투스 상태 변수들 (실제 패키지 연동 시 이 값들을 갱신해 주면 됩니다)
  String _connectionStatus = 'DISCONNECTED'; // CONNECTED, CONNECTING, DISCONNECTED
  String? _connectedDeviceName;
  bool _isScanning = false;

  void _startScanAndConnect() async {
    final bluetoothProvider = context.read<SquatProvider>(); // 개발자님의 프로바이더 클래스명

    try {
      // 프로바이더의 연결 메서드 호출 (내부에서 상태를 CONNECTING -> CONNECTED로 바꿔줄 것입니다)
      await bluetoothProvider.startBluetoothWorkout();

      // 연결이 성공한 후 화면에 띄울 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아두이노 기기(BT05)와 연결되었습니다!')),
      );
    } catch (error) {
      // 에러 발생 시 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $error')),
      );
    }
  }

  // 3. 다시 연결하기 함수 (기존 연결 끊고 재연동 혹은 재시도)
  void _reconnectDevice() {
    setState(() {
      _connectionStatus = 'CONNECTING';
    });

    // 임시 시뮬레이션 코드 (2초 후 재연결 성공)
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _connectionStatus = 'CONNECTED';
      });
    });
  }

  // 연결 해제 함수
  void _disconnectDevice() {
    setState(() {
      _connectionStatus = 'DISCONNECTED';
      _connectedDeviceName = null;
    });
  }

  // 2. 상태에 따른 색상 및 텍스트 매핑 가이드 함수
  Color _getStatusColor() {
    switch (_connectionStatus) {
      case 'CONNECTED': return Colors.green;
      case 'CONNECTING': return Colors.orange;
      case 'DISCONNECTED':
      default: return Colors.red;
    }
  }

  String _getStatusText() {
    switch (_connectionStatus) {
      case 'CONNECTED': return '아두이노 연결됨';
      case 'CONNECTING': return '연결 시도 중...';
      case 'DISCONNECTED':
      default: return '연결 끊어짐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<SquatProvider>();
    _connectionStatus = bluetoothProvider.connectionStatus;

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
                      _connectionStatus == 'CONNECTED'
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      size: 40,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _connectionStatus == 'CONNECTED'
                              ? '기기명: $_connectedDeviceName'
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
                child: _isScanning
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('주변의 스쿼트 센서를 찾는 중입니다...'),
                  ],
                )
                    : Text(
                  _connectionStatus == 'CONNECTED'
                      ? '기기가 정상 연동되었습니다.\n이제 운동을 시작할 수 있습니다!'
                      : '아래 버튼을 눌러 아두이노 장치와 연결해 주세요.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
            ),

            // 요구사항 1 & 3: 하단 제어 버튼 영역
            if (_connectionStatus == 'DISCONNECTED') ...[
              // 1. 아예 이곳에서 새롭게 연결하는 버튼
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _startScanAndConnect,
                icon: const Icon(Icons.search),
                label: const Text('새로운 아두이노 장치 연결하기'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ] else if (_connectionStatus == 'CONNECTED') ...[
              // 연결된 상태일 때 노출되는 해제 버튼
              OutlinedButton.icon(
                onPressed: _disconnectDevice,
                icon: const Icon(Icons.close),
                label: const Text('연결 해제하기'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
              ),
            ] else ...[
              // 요구사항 3: 연결 시도 중(또는 에러 상황)일 때 다시 시도할 수 있는 재연결 버튼
              ElevatedButton.icon(
                onPressed: _reconnectDevice,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 연결 시도하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
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