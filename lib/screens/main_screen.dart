import 'package:flutter/material.dart';
import 'package:tkt/screens/tools_screen.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'discussion_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 使用簡單的小部件列表，避免初始化複雜的頁面
  Widget _getPageForIndex(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const DiscussionScreen();
      case 3:
        return const ToolsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const Center(child: Text('頁面不存在'));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 使用簡化版的 scaffold
    return Scaffold(
      body: _getPageForIndex(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '搜尋',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '討論區',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: '工具',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        onTap: _onItemTapped,
      ),
    );
  }
} 