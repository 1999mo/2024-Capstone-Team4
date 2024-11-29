import 'package:catculator/screens/buyer_screens/bag_screen.dart';
import 'package:catculator/screens/buyer_screens/booth_list_screen.dart';
import 'package:flutter/material.dart';

class BuyerNavigationScreen extends StatefulWidget {
  final String? festivalName;

  const BuyerNavigationScreen({
    Key? key,
    required this.festivalName,
  }) : super(key: key);

  @override
  State<BuyerNavigationScreen> createState() => BuyerNavigationState();
}

class BuyerNavigationState extends State<BuyerNavigationScreen> {
  late int _selectedIndex;
  final TextEditingController _controller = TextEditingController();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    _screens = [
      Center(child: Text('지도 화면')),
      BoothListScreen(painter: _controller.text, festivalName: widget.festivalName),
      Center(child: Text('사전 구매 화면')),
      BagScreen(),
    ];
  }

  void _onTabSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateBoothScreen() {
    setState(() {
      _screens[1] = BoothListScreen(painter: _controller.text, festivalName: widget.festivalName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '작가명 또는 상품명으로 검색',
            suffixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (value) {
            _updateBoothScreen();
            },
        ),
        backgroundColor: Colors.blue,
      ),
      body: _screens[_selectedIndex],
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/main_screens/setting');
            },
          child: const Icon(Icons.settings),
        ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            label: '지도',
            icon: Icon(Icons.map),
          ),
          BottomNavigationBarItem(
            label: '부스 목록',
            icon: Icon(Icons.list),
          ),
          BottomNavigationBarItem(
            label: '사전 구매',
            icon: Icon(Icons.shopping_cart),
          ),
          BottomNavigationBarItem(
            label: '장바구니',
            icon: Icon(Icons.shopping_bag),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onTabSelect,
      ),
    );
  }
}