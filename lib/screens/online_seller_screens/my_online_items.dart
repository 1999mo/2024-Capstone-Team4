import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MyOnlineItems extends StatefulWidget {
  const MyOnlineItems({super.key});

  @override
  State<MyOnlineItems> createState() => _MyOnlineItemsState();
}

class _MyOnlineItemsState extends State<MyOnlineItems> {
  String? boothId; // 이전 화면에서 받아올 boothId
  String? uid = FirebaseAuth.instance.currentUser?.uid; // 현재 사용자의 UID

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // boothId를 arguments로부터 추출
    boothId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<String?> _getImageUrl(String itemId) async {
    try {
      if (uid == null) return null;
      // Firebase Storage에서 이미지 URL 가져오기
      final ref = FirebaseStorage.instance.ref('$uid/${itemId.replaceAll(' ', '_')}.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null; // 이미지가 없거나 에러가 발생한 경우
    }
  }

  Future<void> _deleteItem(String itemId) async {
    if (uid == null || boothId == null) return;

    try {
      // Firestore에서 해당 아이템 문서 참조 생성
      final itemRef = FirebaseFirestore.instance
          .collection('OnlineStore')
          .doc(boothId)
          .collection(uid!)
          .doc(itemId);

      // 문서 가져오기
      final itemSnapshot = await itemRef.get();

      if (itemSnapshot.exists) {
        // 문서 데이터 가져오기
        final itemData = itemSnapshot.data() as Map<String, dynamic>?;

        // stockQuantity 확인
        if (itemData != null && itemData['stockQuantity'] != null) {
        } else {
          // stockQuantity가 없으면 이미지를 삭제
          final storageRef = FirebaseStorage.instance.ref();
          final imagePath = '$uid/${itemId.replaceAll(' ', '_')}.jpg';
          final imageRef = storageRef.child(imagePath);

          await imageRef.delete();
          print('이미지를 삭제했습니다.');
        }
      }

      // Firestore에서 문서 삭제
      await itemRef.delete();

      // 삭제 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품을 삭제했습니다.')),
      );
    } catch (e) {
      // 삭제 실패 시 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (boothId == null || uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('온라인 판매')),
        body: const Center(
          child: Text('부스 ID를 불러오지 못했습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('온라인 판매'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('OnlineStore').doc(boothId).collection(uid!).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {}
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 상품이 없습니다.'));
          }

          final items = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  // 부모 높이에 종속되도록 설정
                  physics: const NeverScrollableScrollPhysics(),
                  // ScrollView 내 독립 스크롤 비활성화
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 그리드 뷰 열 개수
                    crossAxisSpacing: 16, // 그리드 간격
                    mainAxisSpacing: 16, // 그리드 간격
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData = items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;

                    return FutureBuilder<String?>(
                      future: _getImageUrl(itemId),
                      builder: (context, imageSnapshot) {
                        if (imageSnapshot.connectionState == ConnectionState.waiting) {}

                        final imageUrl = imageSnapshot.data;

                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('상품 정보'),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: const Icon(Icons.close),
                                      ),
                                    ],
                                  ),
                                  content: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.6,
                                    height: MediaQuery.of(context).size.height * 0.45,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // 상품 이미지 표시
                                          Container(
                                            height: 250, // 이미지 높이 설정
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.grey, width: 1),
                                            ),
                                            child: imageUrl != null
                                                ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Image.asset(
                                                    'assets/catcul_w.jpg',
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                            )
                                                : ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.asset(
                                                'assets/catcul_w.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          // 상품 정보 텍스트
                                          Text('상품명: ${itemData['itemName'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('작가: ${itemData['artist'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('상품 종류: ${itemData['itemType'] ?? 'N/A'}', style: TextStyle(fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('원가: ${itemData['costPrice'] ?? 'N/A'}원', style: TextStyle(fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Text('판매 가격: ${itemData['sellingPrice'] ?? 'N/A'}원', style: TextStyle(fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text('삭제 확인'),
                                              content: const Text('정말로 이 상품을 삭제하시겠습니까?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context), // 팝업 닫기
                                                  child: const Text('취소'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _deleteItem(itemId); // 실제 삭제 수행
                                                    Navigator.pop(context); // 팝업 닫기
                                                    Navigator.pop(context); // 상품 정보 팝업 닫기
                                                  },
                                                  child: const Text(
                                                    '삭제',
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: const Text(
                                        '삭제',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context); // 팝업 닫기
                                        Navigator.pushNamed(
                                          context,
                                          '/online_seller_screens/online_item_edit',
                                          arguments: [boothId, itemId],
                                        );
                                      },
                                      child: const Text('수정'),
                                    ),
                                  ],
                                );

                              },
                            );
                          },
                          child: Card(
                            //elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Color(0xFFD1D1D1), width: 1),
                            ),
                              child: Column(
                                children: [
                                  // 이미지
                                  const SizedBox(height: 16),
                                  Expanded(
                              child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Image.asset('assets/catcul_w.jpg');
                                            },
                                          )
                                        : Image.asset('assets/catcul_w.jpg'),
                                  ),
                                  ),
                                  const SizedBox(height: 8),
                                  // itemName
                                  Text(
                                    itemData['itemName'] ?? '상품명 없음',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  // sellingPrice
                                  Text(
                                    '${itemData['sellingPrice'] ?? '가격 없음'}원',
                                    style: const TextStyle(fontSize: 14),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFFDBE85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),

        onPressed: () {
          Navigator.pushNamed(context, '/online_seller_screens/online_item_add', arguments: boothId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
