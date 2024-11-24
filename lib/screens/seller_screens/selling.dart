import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Selling extends StatefulWidget {
  const Selling({super.key});

  @override
  State<Selling> createState() => _SellingState();
}

class _SellingState extends State<Selling> {
  late final String boothId;
  List<String> painters = []; // 작가 이름 리스트
  String selectedPainter = '작가 전체'; // 드롭다운 기본 값
  String searchKeyword = ''; // 검색어 상태 추가
  final numberFormat = NumberFormat('#,###');

  int totalSoldItems = 0; // 총 판매된 상품 개수
  double totalPrice = 0; // 총 가격
  Map<String, int> soldItems = {}; // 상품별 판매 개수 기록

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackBarController;

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
  void dispose() {
    // 화면을 벗어날 때 스낵바 닫기
    snackBarController?.close();
    super.dispose();
  }

  void _showSnackBar() {
    // 기존 SnackBar 닫기
    snackBarController?.close();
    snackBarController = null;

    // 약간의 지연 시간 후 새로운 SnackBar 표시
    Future.delayed(Duration(milliseconds: 5), () {
      final snackBar = SnackBar(
        duration: const Duration(days: 365), // 무한 지속
        backgroundColor: const Color(0xFFFDBE85), // 배경색 설정
        content: GestureDetector(
          onTap: () async {
            snackBarController?.close();
            snackBarController = null; // 스낵바 상태 초기화
            // 클릭 시 '/seller_screens/selling_details'로 이동
            await Navigator.pushNamed(
              context,
              '/seller_screens/selling_details',
              arguments: {
                'boothId': boothId,
                'soldItems': soldItems,
              },
            );

            setState(() {
              totalPrice = 0;
              totalSoldItems = 0;
              soldItems.clear();
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SnackBar 내용
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 가격: ${numberFormat.format(totalPrice)}원',
                    style: const TextStyle(color: Colors.black),
                  ),
                  Text(
                    '총 상품 수: $totalSoldItems개',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              // X 버튼
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  // 스낵바 닫기 및 데이터 초기화
                  snackBarController?.close();
                  snackBarController = null; // 스낵바 상태 초기화
                  setState(() {
                    totalPrice = 0;
                    totalSoldItems = 0;
                    soldItems.clear();
                  });
                },
              ),
            ],
          ),
        ),
      );

      // 새로운 SnackBar 표시
      snackBarController = ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  void _onItemCardClicked(Map<String, dynamic> itemData, String itemId) {
    setState(() {
      final sellingPrice = itemData['sellingPrice'] ?? 0;
      // 상품별 판매 개수 및 총 가격 증가
      soldItems[itemId] = (soldItems[itemId] ?? 0) + 1;
      totalPrice += sellingPrice;
      // 총 상품 수 증가
      totalSoldItems = soldItems.values.reduce((sum, count) => sum + count);
    });

    // 스낵바를 업데이트처럼 보이게 처리
    _showSnackBar();
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
                      Navigator.pushNamed(
                          context, '/seller_screens/adjustment', arguments: boothId);
                    },
                    child: const Text('정산하기'),
                  ),
                ),
                const SizedBox(width: 8),
                const VerticalDivider(
                    width: 1, thickness: 1, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/seller_screens/pre_buy');
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
                setState(() {
                  searchKeyword = value.trim(); // 검색어 상태 업데이트
                });
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
                    });
                  },
                  items: painters
                      .map((painter) => DropdownMenuItem(
                      value: painter, child: Text(painter)))
                      .toList(),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/seller_screens/edit_selling_items',
                        arguments: boothId);
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
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 상품이 없습니다.'));
                  }

                  // 검색어 필터링
                  final items = snapshot.data!.docs.where((doc) {
                    final docId = doc.id.toLowerCase();
                    return docId.contains(searchKeyword.toLowerCase());
                  }).toList();

                  if (items.isEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  return GridView.builder(
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemData =
                      items[index].data() as Map<String, dynamic>;
                      final itemId = items[index].id;

                      return GestureDetector(
                        onTap: () {
                          _onItemCardClicked(itemData, itemId);
                        },
                        child: Card(
                          elevation: 3,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  itemData['imagePath'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                        Icons.image_not_supported);
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      itemData['itemName'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Text(
                                          '${numberFormat.format(itemData['sellingPrice'])}원',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${numberFormat.format(itemData['stockQuantity'])}개',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
