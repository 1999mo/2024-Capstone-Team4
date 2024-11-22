import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Selling extends StatefulWidget {
  const Selling({super.key});

  @override
  State<Selling> createState() => _SellingState();
}

class _SellingState extends State<Selling> {
  late final String boothId;
  List<String> painters = []; // 작가 이름 리스트
  String selectedPainter = '작가 전체'; // 드롭다운 기본 값

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';
    _initializePainters();
  }

  Future<void> _initializePainters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId);

    // painters 필드 가져오기
    final boothDoc = await boothRef.get();
    if (boothDoc.exists) {
      final data = boothDoc.data() as Map<String, dynamic>;
      setState(() {
        painters = ['작가 전체', ...List<String>.from(data['painters'] ?? [])];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부스 상품 판매'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 정산하기 & 사전구매 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // 정산하기 로직
                    },
                    child: const Text('정산하기'),
                  ),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      // 사전구매 로직
                    },
                    child: const Text('사전구매'),
                  ),
                ),
              ],
            ),
          ),

          // 검색 필드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              onChanged: (value) {
                // 검색 로직 추가 가능
              },
              decoration: InputDecoration(
                labelText: '상품 검색',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 드롭다운 버튼과 편집 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: selectedPainter,
                  onChanged: (value) {
                    setState(() {
                      selectedPainter = value!;
                      // 선택한 작가별로 필터링 로직 추가 가능
                    });
                  },
                  items: painters
                      .map((painter) =>
                      DropdownMenuItem(value: painter, child: Text(painter)))
                      .toList(),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/seller_screens/edit_selling_items', arguments: boothId);
                  },
                  child: const Text('편집'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 그리드뷰
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('booths')
                    .doc(boothId)
                    .collection('items')
                    .snapshots(), // 실시간 스트림
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 상품이 없습니다.'));
                  }
                  final items = snapshot.data!.docs;

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemData =
                      items[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                itemData['imagePath'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                itemData['itemName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
