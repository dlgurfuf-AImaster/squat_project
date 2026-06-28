import 'package:app/screens/squat_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/arduino_status_screen.dart';

// 탭 바 스크린
class MainHolder extends StatefulWidget {
  const MainHolder({super.key});

  @override
  State<MainHolder> createState() => _MainHolderState();
}

class _MainHolderState extends State<MainHolder> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const ArduinoStatusScreen(),
    const SquatScreen(), // 메인 스쿼트 화면
    const Center(child: Text("기록 화면 준비 중")), // 임시 기록 화면
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: '연결 상태'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: '운동',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '기록'),
        ],
      ),
    );
  }
}
