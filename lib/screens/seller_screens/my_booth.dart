import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBooth extends StatefulWidget {
  const MyBooth({super.key});

  @override
  State<MyBooth> createState() => _MyBoothState();
}

class _MyBoothState extends State<MyBooth> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('내 부스')),
      body: Column(
        children: [
          const Text('내 부스 목록', style: TextStyle(fontSize: 18)),

          // 회색 경계선
          Container(
            color: Colors.grey,
            height: 1,
          ),

          // 부스 목록을 일반 ListView로 표시
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('booths')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('아직 추가된 부스가 없습니다.'));
                  }
                  final booths = snapshot.data!.docs;

                  // default 부스만 있을 때 처리
                  if (booths.length == 1 && booths[0].id == 'default') {
                    return Center(child: Text('아직 추가된 부스가 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: booths.length,
                    itemBuilder: (context, index) {
                      final data = booths[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['FestivalName'] ?? ''),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/seller_screens/selling',
                            arguments: booths[index].id,
                          );
                        },
                        onLongPress: () {
                          _showDeleteDialog(context, booths[index].id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20), // 리스트와 버튼 사이 간격

          // "부스 새로 추가하기" 버튼
          Container(
            margin: const EdgeInsets.all(15),
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/seller_screens/add_booth');
              },
              child: const Text('부스 새로 추가하기'),
            ),
          ),
        ],
      ),
    );
  }

  /// 삭제 확인 팝업 표시
  void _showDeleteDialog(BuildContext context, String boothId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('부스를 삭제하겠습니까?', style: TextStyle(fontSize: 15)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text('뒤로'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteBooth(boothId);
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red), // 삭제 텍스트 빨간색
              ),
            ),
          ],
        );
      },
    );
  }

  /// Firestore에서 부스 삭제
  Future<void> _deleteBooth(String boothId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("로그인된 유저가 없습니다.");

      final userDocRef = FirebaseFirestore.instance.collection('Users').doc(uid);
      final boothsCollectionRef = userDocRef.collection('booths');

      // Festival 컬렉션에서 UID 제거
      final festivalDocRef =
      FirebaseFirestore.instance.collection('Festivals').doc(boothId);
      await festivalDocRef.update({
        'sellers': FieldValue.arrayRemove([uid]), // UID 제거
      });

      // 사용자의 부스 문서 삭제
      await boothsCollectionRef.doc(boothId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('부스가 성공적으로 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('부스 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }
}
