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

      final email = user.email!;
      final doc =
          await FirebaseFirestore.instance.collection('Users').doc(email).get();

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
        duration: Duration(seconds: 3),
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
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          // 오류 발생 시 처리
          return Center(
            child: Text('오류가 발생했습니다.'),
          );
        } else if (snapshot.hasData) {
          // isSeller 값에 따라 화면 반환
          final isSeller = snapshot.data!;
          return isSeller ? SellerMainScreen() : BuyerMainScreen();
        } else {
          // null 케이스가 없으므로 여기는 실행되지 않음
          return SizedBox();
        }
      },
    );
  }
}

// SellerMainScreen
class SellerMainScreen extends StatefulWidget {
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
            alignment: Alignment.center,
            color: Colors.lightBlue,
            margin: EdgeInsets.all(15),
            width: 320,
            height: 197,
            child: Text('공지사항 자리'),
          ),
          ElevatedButton(onPressed: () {}, child: Text('부스 판매하기')),
          ElevatedButton(onPressed: () {}, child: Text('부스 둘러보기')),
          ElevatedButton(onPressed: () {}, child: Text('온라인 물품 팔기')),
          ElevatedButton(onPressed: () {}, child: Text('온라인 물품 둘러보기'))
        ],
      )),
      floatingActionButton:FloatingActionButton(onPressed: () {
        Navigator.pushNamed(context, '/main_screens.setting');
      }, child: Icon(Icons.settings),)
    );
  }
}

// BuyerMainScreen
class BuyerMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('구매자 메인 화면'),
      ),
    );
  }
}
