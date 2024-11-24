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
  String? boothId;
  List<String> painters = []; // 작가 이름 리스트
  String selectedPainter = '작가 전체'; // 드롭다운 기본 값
  String searchKeyword = ''; // 검색어 상태 추가
  final numberFormat = NumberFormat('#,###');

  int totalSoldItems = 0; // 총 판매된 상품 개수
  double totalPrice = 0; // 총 가격
  Map<String, int> soldItems = {}; // 상품별 판매 개수 기록
  Map<String, int> localStock = {}; // 로컬 재고 상태 저장
  Set<String> exhaustedItems = {}; // 품절된 아이템 ID 저장

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackBarController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';
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
    Future.delayed(const Duration(milliseconds: 1), () {
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
                    '총 가격: ${numberFormat.format(totalPrice)}원                              ',
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  Text(
                    '총 상품 수: $totalSoldItems개                                          ',
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

                  // 로컬 재고 복원 및 품절 목록에서 제거
                  soldItems.forEach((itemId, soldQuantity) {
                    if (localStock.containsKey(itemId)) {
                      localStock[itemId] =
                          (localStock[itemId] ?? 0) + soldQuantity;
                    }

                    // 재고 복원 후 품절 상태가 아니면 품절 목록에서 제거
                    if ((localStock[itemId] ?? 0) > 0) {
                      exhaustedItems.remove(itemId);
                    }
                  });

                  setState(() {
                    totalPrice = 0;
                    totalSoldItems = 0;
                    soldItems.clear(); // 판매 기록 초기화
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
    final stock = localStock[itemId] ?? itemData['stockQuantity'] ?? 0;
    if (stock <= 0) {
      _showOutOfStockDialog(itemId, itemData);
      return;
    }

    setState(() {
      localStock[itemId] = stock - 1; // 재고 감소
      soldItems[itemId] = (soldItems[itemId] ?? 0) + 1;
      totalPrice += itemData['sellingPrice'] ?? 0;
      totalSoldItems = soldItems.values.fold(0, (sum, count) => sum + count);

      if (localStock[itemId] == 0) {
        exhaustedItems.add(itemId);
      }
    });

    _showSnackBar();
  }

  void _showOutOfStockDialog(String itemId, Map<String, dynamic> itemData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('품절된 상품입니다'),
          content: const Text('온라인 판매 수요조사를 시작하겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                _startOnlineDemand(itemId, itemData);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reloadItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;

    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId)
        .collection('items')
        .get();

    setState(() {
      // 로컬 재고 업데이트
      localStock = {
        for (var doc in itemsSnapshot.docs) doc.id: doc['stockQuantity'] ?? 0
      };

      // exhaustedItems에서 재고가 0이 아니게 된 상품 제거
      exhaustedItems.removeWhere((itemId) =>
      (localStock[itemId] ?? 0) > 0);
    });
  }



  Future<void> _startOnlineDemand(
      String itemId, Map<String, dynamic> itemData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;

    final itemRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId)
        .collection('items')
        .doc(itemId);

    await itemRef.set({'expect': 0}, SetOptions(merge: true));

    setState(() {
      exhaustedItems.add(itemId);
    });
  }

  void _startOnlineSale(Map<String, dynamic> itemData) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final onlineStoreRef = FirebaseFirestore.instance
        .collection('OnlineStore')
        .doc(uid)
        .collection('onlineSell');

    await onlineStoreRef.add(itemData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('온라인 판매가 시작되었습니다.')),
    );
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
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF7F8FF), // 배경색 설정
                border: Border.all(color: Colors.grey), // 전체 아웃라인 추가
                borderRadius: BorderRadius.circular(8), // 둥근 모서리 설정
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬 중앙으로
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        snackBarController?.close();
                        snackBarController = null;
                        Navigator.pushNamed(
                            context, '/seller_screens/adjustment',
                            arguments: boothId);
                      },
                      child: const Text(
                        '정산하기',
                        style: TextStyle(
                          color: Color(0xFFE84141),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 33, // VerticalDivider의 높이 설정
                    child: const VerticalDivider(
                      width: 1,
                      thickness: 1, // 두께
                      color: Colors.grey, // 경계선 색상
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        snackBarController?.close();
                        snackBarController = null;
                        // 사전구매 로직
                      },
                      child: const Text(
                        '사전구매',
                        style: TextStyle(
                          color: Color(0xFFE68C32),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

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
                suffixIcon: IconButton(
                  icon: Icon(Icons.search), // 돋보기 아이콘
                  onPressed: () {},
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // 드롭다운 버튼과 편집 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  padding: EdgeInsets.symmetric(horizontal: 8),
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
                TextButton(
                  onPressed: () {
                    snackBarController?.close();
                    snackBarController = null;
                    Navigator.pushNamed(context, '/seller_screens/edit_selling_items', arguments: boothId)
                        .then((_) {
                      setState(() {
                        _initializePainters();
                        _reloadItems();
                      });
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: const Color(0xFF434355),
                  ),
                  child: const Text(
                    '상품편집',
                    style: TextStyle(color: Colors.white),
                  ),
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
                    //처음에는 로딩화면을 띄우는 것으로 했으나 없는 것이 UX적으로 좋아보임
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 상품이 없습니다.'));
                  }

                  // 검색어 필터링
                  // 검색어와 드롭다운 필터링
                  final items = snapshot.data!.docs.where((doc) {
                    final docData = doc.data() as Map<String, dynamic>;
                    final itemName = docData['itemName']?.toLowerCase() ?? '';
                    final itemPainter = docData['artist'] ?? '작가 전체';

                    return (selectedPainter == '작가 전체' ||
                            itemPainter == selectedPainter) &&
                        itemName.contains(searchKeyword.toLowerCase());
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
                      final stock =
                          localStock[itemId] ?? itemData['stockQuantity'] ?? 0;

                      return GestureDetector(
                        onTap: () => _onItemCardClicked(itemData, itemId),
                        child: Card(
                          color: stock == 0 ? Colors.grey[300] : null,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  itemData['imagePath'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/catcul_w.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(itemData['itemName'] ?? ''),
                                    Text(
                                      '${numberFormat.format(stock)}개',
                                      style: TextStyle(
                                        color: stock == 0
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    if (itemData['expect'] != null &&
                                        exhaustedItems.contains(itemId))
                                      Column(
                                        children: [
                                          Text(
                                              '구매 희망자 수 : ${itemData['expect'] ?? 0}'),
                                          ElevatedButton(
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title:
                                                      const Text('온라인 판매 시작'),
                                                  content: const Text(
                                                      '온라인 판매를 시작하시겠습니까?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // 팝업 닫기
                                                      },
                                                      child: const Text('취소'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // 팝업 닫기
                                                        _startOnlineSale(
                                                            itemData); // 온라인 판매 시작
                                                      },
                                                      child: const Text('확인'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                            child: const Text('온라인 판매 시작'),
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
