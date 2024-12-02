import 'package:flutter/material.dart';
import 'package:catculator/screens/buyer_screens/map_screen.dart';
import 'package:catculator/screens/buyer_screens/bag_list_screen.dart';
import 'package:catculator/screens/buyer_screens/booth_list_screen.dart';
import 'package:catculator/screens/buyer_screens/preBooth_list_screen.dart';
import 'package:catculator/screens/buyer_screens/order_list.dart';

class BuyerNavigationScreen extends StatefulWidget {
  const BuyerNavigationScreen({super.key});

  @override
  State<BuyerNavigationScreen> createState() => _BuyerNavigationScreenState();
}

class _BuyerNavigationScreenState extends State<BuyerNavigationScreen> {
  int _selectedIndex = 0;

  // 탭에 표시될 위젯
  final List<Widget> _pages = [
    const MapScreen(),
    const BoothListScreen(),
    const PreboothListScreen(),
    const BagListScreen(),
    const OrderList(),
  ];

  // 탭 클릭 시 동작
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // 선택된 탭의 위젯 표시
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFDBE85), // 선택된 아이템 색상
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '부스목록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket),
            label: '사전구매',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: '주문목록',
          ),
        ],
      ),
    );
  }
}
