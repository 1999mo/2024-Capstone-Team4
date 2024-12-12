import 'package:catculator/screens/buyer_screens/bag_list_screen.dart';
import 'package:catculator/screens/buyer_screens/booth_list_screen.dart';
import 'package:catculator/screens/buyer_screens/buyer_navigation_screen.dart';
import 'package:catculator/screens/buyer_screens/festival_select.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final doc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

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
          return isSeller ? const SellerMainScreen() : const BuyerMainScreen(); //BuyerMainScreen
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
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/main_screens/setting');
              },
              icon: Icon(Icons.settings))
        ],
      ),
      body: Center(
          child: Column(
        children: [
          Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: Color(0xFFD1D1D1), width: 2.0)),
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    child: const Text(
                      '공지사항',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1),
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFD1D1D1),
                    thickness: 2, // 두께
                    indent: 20, // 왼쪽 여백
                    endIndent: 20, // 오른쪽 여백
                  ),
                  Column(children: [
                    Image.asset(
                      'assets/catcul_w.jpg',
                      width: 220,
                      height: 220,
                    ),
                    Text(
                      '서코, 일페를 위한 축제 필수템!',
                      style: TextStyle(fontSize: 18, color: Colors.pinkAccent),
                    ),

                  ])
                ],
              )),
          const SizedBox(height: 30),
          const Divider(
            color: Color(0x81D1D1D1),
            thickness: 6,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  '판매하기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                // const Icon(Icons.chevron_right)
                Text(
                  '내가 만든 상품을 판매해보세요!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                // GestureDetector(
                //   child: Container(
                //     width: double.infinity,
                //     height: 56,
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     decoration: ShapeDecoration(
                //       color: Color(0xFFECECEC),
                //       shape: RoundedRectangleBorder(
                //           side: BorderSide(width: 1, color: Color(0xFFD1D1D1)), borderRadius: BorderRadius.circular(8)),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         const Text(
                //           '부스 판매하기',
                //           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                //         ),
                //         const Icon(Icons.chevron_right)
                //       ],
                //     ),
                //   ),
                //   onTap: () {
                //     Navigator.pushNamed(context, '/seller_screens/my_booth');
                //   },
                // ),
                // const SizedBox(height: 20),
                // GestureDetector(
                //   child: Container(
                //     width: double.infinity,
                //     height: 56,
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     decoration: ShapeDecoration(
                //       color: Color(0xFFECECEC),
                //       shape: RoundedRectangleBorder(
                //           side: BorderSide(width: 1, color: Color(0xFFD1D1D1)), borderRadius: BorderRadius.circular(8)),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         Container(
                //           child: Text(
                //             '부스 둘러보기',
                //             style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                //           ),
                //         ),
                //         Icon(Icons.chevron_right)
                //       ],
                //     ),
                //   ),
                //   onTap: () async {
                //     String? selection = await showDialog<String>(
                //         context: context,
                //         builder: (BuildContext context) {
                //           return MyDropdownDialog();
                //         });
                //
                //     if (selection == '') {
                //       //this is where nothing selected, such as cancel, or selecting nothing and continue;
                //     } else {
                //       Navigator.pushNamed(context, '/buyer_screens/buyer_navigation_screen', arguments: selection);
                //     }
                //   },
                // ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Color(0xFF6FCD65),
                            shape: RoundedRectangleBorder(
                              // side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/offline_sale.png',
                                width: 105,
                                height: 105,
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                '현장 판매',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              //Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/seller_screens/my_booth');
                        },
                      ),
                    ),
                    const SizedBox(width: 10), // 버튼 사이 간격
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Color(0xFFFDBE85),
                            shape: RoundedRectangleBorder(
                              // side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/online_sale.png',
                                width: 105,
                                height: 105,
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                '온라인 판매',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              //Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/online_seller_screens/online_select_booth');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}

// BuyerMainScreen

// SellerMainScreen
class BuyerMainScreen extends StatefulWidget {
  const BuyerMainScreen({super.key});

  @override
  State<BuyerMainScreen> createState() => _BuyerMainScreenState();
}

class _BuyerMainScreenState extends State<BuyerMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/main_screens/setting');
              },
              icon: Icon(Icons.settings))
        ],
      ),
      body: Center(
          child: Column(
        children: [
          Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.all(color: Color(0xFFD1D1D1), width: 2.0)),
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    child: const Text(
                      '공지사항',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1),
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFD1D1D1),
                    thickness: 2, // 두께
                    indent: 20, // 왼쪽 여백
                    endIndent: 20, // 오른쪽 여백
                  ),
                  Column(children: [
                    Image.asset(
                      'assets/catcul_w.jpg',
                      width: 220,
                      height: 220,
                    ),
                    Text(
                      '우리를 위한 축제 필수템!',
                      style: TextStyle(fontSize: 18, color: Colors.pinkAccent),
                    ),
                  ])
                ],
              )),
          const SizedBox(height: 30),
          const Divider(
            color: Color(0x81D1D1D1),
            thickness: 6,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Text(
                  '구매하기',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                // const Icon(Icons.chevron_right)
                Text(
                  '다양한 상품을 구경하러 가볼까요?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
                // GestureDetector(
                //   child: Container(
                //     width: double.infinity,
                //     height: 56,
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     decoration: ShapeDecoration(
                //       color: Color(0xFFECECEC),
                //       shape: RoundedRectangleBorder(
                //           side: BorderSide(width: 1, color: Color(0xFFD1D1D1)), borderRadius: BorderRadius.circular(8)),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         const Text(
                //           '부스 판매하기',
                //           style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                //         ),
                //         const Icon(Icons.chevron_right)
                //       ],
                //     ),
                //   ),
                //   onTap: () {
                //     Navigator.pushNamed(context, '/seller_screens/my_booth');
                //   },
                // ),
                // const SizedBox(height: 20),
                // GestureDetector(
                //   child: Container(
                //     width: double.infinity,
                //     height: 56,
                //     padding: const EdgeInsets.symmetric(horizontal: 16),
                //     decoration: ShapeDecoration(
                //       color: Color(0xFFECECEC),
                //       shape: RoundedRectangleBorder(
                //           side: BorderSide(width: 1, color: Color(0xFFD1D1D1)), borderRadius: BorderRadius.circular(8)),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         Container(
                //           child: Text(
                //             '부스 둘러보기',
                //             style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                //           ),
                //         ),
                //         Icon(Icons.chevron_right)
                //       ],
                //     ),
                //   ),
                //   onTap: () async {
                //     String? selection = await showDialog<String>(
                //         context: context,
                //         builder: (BuildContext context) {
                //           return MyDropdownDialog();
                //         });
                //
                //     if (selection == '') {
                //       //this is where nothing selected, such as cancel, or selecting nothing and continue;
                //     } else {
                //       Navigator.pushNamed(context, '/buyer_screens/buyer_navigation_screen', arguments: selection);
                //     }
                //   },
                // ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Color(0xFF6FCD65),
                            shape: RoundedRectangleBorder(
                              // side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.1,
                                child: Image.asset(
                                  'assets/offline_buy.png',
                                  width: 105,
                                  height: 105,
                                ),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                '현장 구매',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              //Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        onTap: () async {
                          String? selection = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                return MyDropdownDialog();
                              });

                          if (selection == '') {
                            //this is where nothing selected, such as cancel, or selecting nothing and continue;
                          } else {
                            Navigator.pushNamed(context, '/buyer_screens/buyer_navigation_screen',
                                arguments: selection);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10), // 버튼 사이 간격
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          height: 200,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Color(0xFFFDBE85),
                            shape: RoundedRectangleBorder(
                              // side: BorderSide(width: 1, color: Color(0xFFD1D1D1)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Image.asset(
                                  'assets/online_buy2.png',
                                  width: 105,
                                  height: 105,
                                ),
                              ),
                              const SizedBox(height: 25),
                              const Text(
                                '온라인 구매',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              //Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/online_buyer_screens/online_select_festival');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
