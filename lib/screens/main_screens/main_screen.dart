import 'package:catculator/screens/buyer_screens/bag_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '/screens/buyer_screens/booth_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // isSeller 값을 Firestore에서 가져오는 함수
  Future<bool> fetchIsSeller(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackbar(context, '로그인된 사용자가 없습니다.');
        return false; // 기본값으로 false 반환
      }

      final uid = user.uid;
      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(uid).get();

      if (doc.exists) {
        final isSeller = doc.data()?['isSeller'];
        if (isSeller is bool) {
          return isSeller;
        }
      }

      _showSnackbar(context, '사용자 문서가 존재하지 않거나 데이터가 올바르지 않습니다.');
      return false; // 기본값으로 false 반환
    } catch (e) {
      _showSnackbar(context, 'isSeller 읽기 실패: $e');
      return false; // 기본값으로 false 반환
    }
  }

  // 스낵바 표시 함수
  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: fetchIsSeller(context), // isSeller 값을 가져옴
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 로딩 상태 표시
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          // 오류 발생 시 처리
          //return Center(
          //  child: Text('오류가 발생했습니다.'),
          //);
          return const BuyerMainScreen();
        } else if (snapshot.hasData) {
          // isSeller 값에 따라 화면 반환
          final isSeller = snapshot.data!;
          return isSeller ? const SellerMainScreen() : const BuyerMainScreen();
        } else {
          // null 케이스가 없으므로 여기는 실행되지 않음
          return const SizedBox();
        }
      },
    );
  }
}

// SellerMainScreen
class SellerMainScreen extends StatefulWidget {
  const SellerMainScreen({super.key});

  @override
  State<SellerMainScreen> createState() => _SellerMainScreenState();
}

class _SellerMainScreenState extends State<SellerMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Column(
          children: [
            Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1.0)),
                alignment: Alignment.center,
                margin: const EdgeInsets.all(15),
                width: 320,
                child: Column(
                  children: [
                    Container(
                      width: 275,
                      height: 24,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      child: const Text(
                        '공지사항',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1),
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1, // 두께
                      indent: 20, // 왼쪽 여백
                      endIndent: 20, // 오른쪽 여백
                    ),
                    Column(children: [
                      Image.asset(
                        'assets/catcul_w.jpg',
                        width: 128,
                        height: 128,
                      ),
                      Text(
                        '우리를 위한 축제 필수템!',
                        style:
                            TextStyle(fontSize: 18, color: Colors.pinkAccent),
                      ),
                      Text('좋은 앱 이름 추천 받아요... \n아이디어 있으면 연락주세요 (제발)'),
                      Text('\n부스 판매하기, 부스 추가 구현 완료')
                    ])
                  ],
                )),
            const SizedBox(height: 50),
            GestureDetector(
              child: Container(
                width: 320,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                    color: Color(0xFFEBEBEB),
                    shape: RoundedRectangleBorder(
                        side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                        borderRadius: BorderRadius.circular(8))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '부스 판매하기',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.chevron_right)
                  ],
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/seller_screens/my_booth');
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              child: Container(
                  width: 320,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                      color: Color(0xFFEBEBEB),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                          borderRadius: BorderRadius.circular(8))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          '부스 둘러보기',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(Icons.chevron_right)
                    ],
                  )),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              child: Container(
                  width: 320,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                      color: Color(0xFFEBEBEB),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                          borderRadius: BorderRadius.circular(8))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          '온라인 판매하기',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(Icons.chevron_right)
                    ],
                  )),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              child: Container(
                  width: 320,
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: ShapeDecoration(
                      color: Color(0xFFEBEBEB),
                      shape: RoundedRectangleBorder(
                          side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                          borderRadius: BorderRadius.circular(8))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          '온라인 상품 둘러보기',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(Icons.chevron_right)
                    ],
                  )),
            ),
          ],
        )),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/main_screens/setting');
          },
          child: const Icon(Icons.settings),
        ));
  }
}

// BuyerMainScreen
class BuyerMainScreen extends StatefulWidget {
  final int selectedIndex;

  const BuyerMainScreen({
    Key? key,
    this.selectedIndex = 1,  // Default value for selectedIndex
  }) : super(key: key);

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  late int _selectedIndex;
  final TextEditingController _controller = TextEditingController();

  // Initialize _screens with the first state of screens
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    _screens = [
      Center(child: Text('지도 화면')), // 지도
      BoothListScreen(painter: _controller.text), // 부스
      Center(child: Text('사전 구매 화면')), // 사전 구매
      BagScreen(), // 장바구니
    ];
  }

  void _onTabSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateBoothScreen() {
    // Only update the second screen (BoothListScreen)
    setState(() {
      _screens[1] = BoothListScreen(painter: _controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: '작가명 또는 캐릭터명으로 검색',
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
      body: _screens[_selectedIndex], // Display selected screen
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