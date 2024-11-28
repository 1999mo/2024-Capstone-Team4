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

  Set<String> clickedOutOfStockItems = {}; // 품절된 상품의 클릭 상태 관리
  Set<String> onlineSaleStartedItems = {}; // 온라인 판매 시작 상태 관리

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? snackBarController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';
    _initializePainters();
    _initializeItemsState();
  }

  Future<void> _initializeItemsState() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;

    CollectionReference itemsRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId)
        .collection('items');

    CollectionReference onlineItemsRef = FirebaseFirestore.instance
        .collection('OnlineStore')
        .doc(boothId)
        .collection(uid);

    try {
      List<Set<String>> results = await Future.wait([
        // 1. Initialize clickedOutOfStockItems and exhaustedItems
        itemsRef.get().then((itemsSnapshot) {
          Set<String> clickedItems = {};
          Set<String> exhaustedItemsLocal = {};

          for (var doc in itemsSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?; // 안전하게 캐스팅
            if (data != null &&
                data.containsKey('expect') && // expect 필드 존재
                (data['stockQuantity'] ?? 1) == 0) {
              // stockQuantity가 0인지 확인
              clickedItems.add(doc.id); // clickedOutOfStockItems에 추가
              exhaustedItemsLocal.add(doc.id); // exhaustedItems에도 추가
            }
          }

          setState(() {
            exhaustedItems = exhaustedItemsLocal; // exhaustedItems 업데이트
          });

          return clickedItems;
        }),

        // 2. Initialize onlineSaleStartedItems
        onlineItemsRef.get().then((onlineSnapshot) {
          Set<String> onlineItems = onlineSnapshot.docs.map((doc) => doc.id).toSet();
          return onlineItems;
        }),
      ]);

      // 상태 업데이트
      setState(() {
        clickedOutOfStockItems = results[0]; // 첫 번째 작업 결과
        onlineSaleStartedItems = results[1]; // 두 번째 작업 결과
      });
    } catch (e) {
      // 오류 발생 시 Snackbar 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터 초기화 중 오류가 발생했습니다.')),
      );
    }
  }


  Future<void> _initializePainters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final boothRef = FirebaseFirestore.instance.collection('Users').doc(uid).collection('booths').doc(boothId);

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
    snackBarController?.close();
    snackBarController = null;

    Future.delayed(const Duration(milliseconds: 1), () {
      final snackBar = SnackBar(
        duration: const Duration(days: 365), // 무한 지속
        backgroundColor: const Color(0xFFFDBE85),
        content: GestureDetector(
          onTap: () async {
            snackBarController?.close();
            snackBarController = null;

            // 결제 화면으로 이동
            await Navigator.pushNamed(
              context,
              '/seller_screens/selling_details',
              arguments: {
                'boothId': boothId,
                'soldItems': soldItems,
              },
            ).then((_) {
              // 돌아올 때 상태 초기화 또는 동기화
              setState(() {
                _reloadItems(); // Firebase에서 데이터 동기화
                totalPrice = 0;
                totalSoldItems = 0;
                soldItems.clear(); // soldItems 초기화
              });
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 가격: ${numberFormat.format(totalPrice)}원',
                    style: const TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  Text(
                    '총 상품 수: $totalSoldItems개',
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  snackBarController?.close();
                  snackBarController = null;

                  // 상태 초기화
                  soldItems.forEach((itemId, soldQuantity) {
                    if (localStock.containsKey(itemId)) {
                      localStock[itemId] = (localStock[itemId] ?? 0) + soldQuantity;
                    }

                    if ((localStock[itemId] ?? 0) > 0) {
                      exhaustedItems.remove(itemId);
                    }
                  });

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
                setState(() {
                  clickedOutOfStockItems.add(itemId); // 클릭 상태 저장
                });
                _startOnlineDemand(itemId, itemData); // 수요 조사 시작
                Navigator.pop(context); // 팝업 닫기
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
      localStock = {for (var doc in itemsSnapshot.docs) doc.id: doc['stockQuantity'] ?? 0};

      // Firebase에서 재고가 0인 항목으로 exhaustedItems 동기화
      exhaustedItems = localStock.entries.where((entry) => entry.value == 0).map((entry) => entry.key).toSet();

      // `soldItems` 초기화
      soldItems.clear();
    });
  }

  Future<void> _startOnlineDemand(String itemId, Map<String, dynamic> itemData) async {
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
      exhaustedItems.add(itemId); // 상태 업데이트
    });
  }

  void _startOnlineSale(Map<String, dynamic> itemData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String uid = user.uid; // 현재 사용자의 UID
    final String? email = user.email; // 현재 사용자의 이메일

    // itemData에서 문서 ID로 사용할 값을 가져옴 (예: 'itemName' 필드)
    final String? itemName = itemData['itemName'];
    if (itemName == null || itemName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 이름이 없습니다.')),
      );
      return;
    }

    final onlineStoreRef = FirebaseFirestore.instance.collection('OnlineStore').doc(boothId);

    try {
      // **1. Firebase 작업 수행**
      await onlineStoreRef.set(
        {'email': email}, // email 필드 추가
        SetOptions(merge: true), // 기존 데이터에 병합
      );

      final itemRef = onlineStoreRef.collection(uid).doc(itemName);
      await itemRef.set(itemData);

      // **2. 성공적으로 Firebase 작업 완료 후 로컬 상태 업데이트**
      setState(() {
        onlineSaleStartedItems.add(itemName); // 버튼 비활성화
      });

      // **3. 성공 메시지 표시**
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('온라인 판매가 시작되었습니다.')),
      );
    } catch (e) {
      // **4. Firebase 작업 실패 시 오류 메시지 표시**
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('온라인 판매 시작에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부스 상품 판매'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                //실험용 실험용 실험용
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('품절된 상품 목록'),
                      content: SingleChildScrollView(child: Text(boothId.toString())),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // 팝업 닫기
                          },
                          child: const Text('확인'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(Icons.ac_unit_outlined))
        ],
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
                        Navigator.pushNamed(context, '/seller_screens/adjustment', arguments: boothId).then((_) {
                          setState(() {
                            _reloadItems();
                          });
                        });
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
                        Navigator.pushNamed(context, '/seller_screens/pre_order', arguments: boothId).then((_) {
                          // 돌아올 때 Firebase 데이터 동기화
                          setState(() {
                            _reloadItems();
                          });
                        });
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
                  items: painters.map((painter) => DropdownMenuItem(value: painter, child: Text(painter))).toList(),
                ),
                TextButton(
                  onPressed: () {
                    snackBarController?.close();
                    snackBarController = null;
                    Navigator.pushNamed(context, '/seller_screens/edit_selling_items', arguments: boothId).then((_) {
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
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('등록된 상품이 없습니다.'));
                  }

                  final items = snapshot.data!.docs.where((doc) {
                    final docData = doc.data() as Map<String, dynamic>;
                    final itemName = docData['itemName']?.toLowerCase() ?? '';
                    final itemPainter = docData['artist'] ?? '작가 전체';

                    return (selectedPainter == '작가 전체' || itemPainter == selectedPainter) &&
                        itemName.contains(searchKeyword.toLowerCase());
                  }).toList();

                  // clickedOutOfStockItems 및 exhaustedItems 동기화
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final clickedItems = <String>{};
                    final exhaustedItemsLocal = <String>{};

                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data != null) {
                        if (data.containsKey('expect') && (data['stockQuantity'] ?? 1) == 0) {
                          clickedItems.add(doc.id);
                          exhaustedItemsLocal.add(doc.id);
                        }
                      }
                    }

                    // 상태 동기화
                    if (clickedOutOfStockItems != clickedItems || exhaustedItems != exhaustedItemsLocal) {
                      setState(() {
                        clickedOutOfStockItems = clickedItems;
                        exhaustedItems = exhaustedItemsLocal;
                      });
                    }
                  });

                  if (items.isEmpty) {
                    return const Center(child: Text('검색 결과가 없습니다.'));
                  }

                  // GridView 렌더링
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final itemData = items[index].data() as Map<String, dynamic>;
                      final itemId = items[index].id;
                      final stock = localStock[itemId] ?? itemData['stockQuantity'] ?? 0;

                      return GestureDetector(
                        onTap: clickedOutOfStockItems.contains(itemId)
                            ? null // 클릭 막기
                            : () => _onItemCardClicked(itemData, itemId),
                        child: Card(
                          // elevation: 3,
                          color: stock == 0 ? Colors.grey[300] : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Color(0xFFD1D1D1), width: 1),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    itemData['imagePath'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return ColorFiltered(
                                        colorFilter: stock == 0
                                            ? const ColorFilter.matrix(<double>[
                                          0.6, 0.2, 0.2, 0, 0, // R
                                          0.2, 0.6, 0.2, 0, 0, // G
                                          0.2, 0.2, 0.6, 0, 0, // B
                                          0,   0,   0,   1, 0, // Alpha
                                        ])
                                            : const ColorFilter.mode(
                                          Colors.transparent,
                                          BlendMode.multiply,
                                        ),
                                        child: Image.asset(
                                          'assets/catcul_w.jpg',
                                          fit: BoxFit.cover,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                        itemData['itemName'] ?? '',
                                      style: TextStyle(
                                        color: stock == 0 ? Colors.grey[700]: Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '${numberFormat.format(stock)}개',
                                      style: TextStyle(
                                        color: stock == 0 ? Colors.red : Colors.black,
                                      ),
                                    ),
                                    if (itemData['expect'] != null && exhaustedItems.contains(itemId))
                                      Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8.0),
                                            width: double.infinity,
                                            height: 38.0,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: Color(0xFFD1D1D1)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('구매 희망자 수 : ${itemData['expect'] ?? 0}',textAlign: TextAlign.center),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Container(
                                            width: double.infinity,
                                            height: 38.0,
                                            decoration: BoxDecoration(
                                              color: onlineSaleStartedItems.contains(itemId)? Colors.grey:const Color(0xFFFFDCBD),
                                              border: Border.all(color: Color(0xFFD1D1D1)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: TextButton(
                                              onPressed: onlineSaleStartedItems.contains(itemId)
                                                  ? null
                                                  : () => showDialog(
                                                        context: context,
                                                        builder: (BuildContext context) {
                                                          return AlertDialog(
                                                            title: Text('온라인 판매 시작'),
                                                            content: const Text('온라인 판매를 시작하시겠습니까?'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.of(context).pop(); // 팝업 닫기
                                                                },
                                                                child: const Text('취소'),
                                                              ),
                                                              ElevatedButton(
                                                                onPressed: onlineSaleStartedItems.contains(itemId)
                                                                    ? null // 이미 클릭된 경우 비활성화
                                                                    : () {
                                                                        setState(() {
                                                                          onlineSaleStartedItems.add(itemId); // 클릭 상태 저장
                                                                        });
                                                                        Navigator.of(context).pop(); // 팝업 닫기
                                                                        _startOnlineSale(itemData); // 온라인 판매 시작
                                                                      },
                                                                child: Text(
                                                                  onlineSaleStartedItems.contains(itemId)
                                                                      ? '진행 중...'
                                                                      : '확인',
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                              child: Text(
                                                onlineSaleStartedItems.contains(itemId) ? '온라인 판매 진행중!' : '온라인 판매 시작',
                                                style: TextStyle(color: Colors.black),
                                              ),
                                            ),
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
