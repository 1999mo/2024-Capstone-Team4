import 'package:flutter/material.dart';
import 'online_select_booths.dart';
import 'online_buyer_shopping_cart.dart';
import 'online_buyer_order_list.dart';

class NavigationMain extends StatefulWidget {
  const NavigationMain({super.key});

  @override
  State<NavigationMain> createState() => _NavigationMainState();
}

class _NavigationMainState extends State<NavigationMain> {
  int _selectedIndex = 0;

  // 탭에 표시될 위젯
  final List<Widget> _pages = [
    const OnlineSelectBooths(),
    const OnlineBuyerShoppingCart(),
    const OnlineBuyerOrderList(),
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
      body: _pages[_selectedIndex], // 선택된 탭의 위젯을 표시
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFDBE85), // 선택된 아이템 색상
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: '상품 둘러보기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: '주문목록',
          ),
        ],
      ),
    );
  }
}
