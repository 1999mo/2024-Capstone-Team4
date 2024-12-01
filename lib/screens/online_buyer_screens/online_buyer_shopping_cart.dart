import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 숫자 포맷팅
import 'package:cached_network_image/cached_network_image.dart';

class OnlineBuyerShoppingCart extends StatefulWidget {
  const OnlineBuyerShoppingCart({super.key});

  @override
  State<OnlineBuyerShoppingCart> createState() => _OnlineBuyerShoppingCartState();
}

class _OnlineBuyerShoppingCartState extends State<OnlineBuyerShoppingCart> {
  String? festivalName;
  Map<String, List<Map<String, dynamic>>> cartData = {};
  Map<String, String> sellerNames = {};
  Map<String, Future<String>> imageCache = {}; // 캐시가 Future<String> 타입으로 변경됨
  int totalCost = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_basket')
        .doc(festivalName);

    final cartSnapshot = await cartRef.get();
    if (cartSnapshot.exists) {
      final data = cartSnapshot.data() as Map<String, dynamic>;
      final newCartData = <String, List<Map<String, dynamic>>>{};
      final newSellerNames = <String, String>{};
      int newTotalCost = 0;

      final futures = data.keys.map((sellerId) async {
        final items = List<Map<String, dynamic>>.from(data[sellerId]);

        // Fetch boothName for the seller
        final sellerDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerId)
            .collection('booths')
            .doc(festivalName)
            .get();

        final boothName = sellerDoc.exists ? (sellerDoc.data()?['boothName'] as String?) : null;

        newCartData[sellerId] = items;
        newSellerNames[sellerId] = boothName ?? 'Unknown Booth';

        for (final item in items) {
          final imagePath = item['imagePath'] as String?;
          if (imagePath != null && !imageCache.containsKey(imagePath)) {
            imageCache[imagePath] = _getCachedImageUrl(imagePath); // 캐시로 저장
          }
        }

        newTotalCost += items.fold(
          0,
              (sum, item) =>
          sum + (((item['sellingPrice'] as num?)?.toInt() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 0)),
        );
      }).toList();

      await Future.wait(futures);

      setState(() {
        cartData = newCartData;
        sellerNames = newSellerNames;
        totalCost = newTotalCost;
      });
    }
  }

  Future<String> _getCachedImageUrl(String path) async {
    try {
      return await FirebaseStorage.instance.ref(path).getDownloadURL();
    } catch (e) {
      return ''; // 이미지 로드 실패 시 기본 빈 문자열 반환
    }
  }

  Future<void> _updateCartData(String sellerId, List<Map<String, dynamic>> updatedItems) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    final cartRef =
    FirebaseFirestore.instance.collection('Users').doc(uid).collection('online_basket').doc(festivalName);

    if (updatedItems.isEmpty) {
      await cartRef.update({sellerId: FieldValue.delete()});
    } else {
      await cartRef.update({sellerId: updatedItems});
    }
  }

  Future<void> _deleteItemFromCart(String sellerId, Map<String, dynamic> item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    // Firestore 문서 참조
    final cartRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_basket')
        .doc(festivalName);

    // Firestore에서 해당 항목 삭제
    try {
      final cartSnapshot = await cartRef.get();
      if (cartSnapshot.exists) {
        final cartData = cartSnapshot.data() as Map<String, dynamic>? ?? {};

        if (cartData.containsKey(sellerId)) {
          List<dynamic> items = cartData[sellerId];
          items.removeWhere((element) => element['itemName'] == item['itemName']);

          if (items.isEmpty) {
            await cartRef.update({sellerId: FieldValue.delete()});
          } else {
            await cartRef.update({sellerId: items});
          }

          // UI 갱신
          setState(() {
            cartData[sellerId] = items;
            if (items.isEmpty) {
              cartData.remove(sellerId);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상품이 장바구니에서 삭제되었습니다.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final sortedEntries = cartData.entries.toList();
    sortedEntries.sort((a, b) {
      final boothNameA = sellerNames[a.key] ?? 'Unknown Booth';
      final boothNameB = sellerNames[b.key] ?? 'Unknown Booth';
      return boothNameA.compareTo(boothNameB);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: sortedEntries.map((entry) {
                  final sellerId = entry.key;
                  final items = entry.value;
                  final boothName = sellerNames[sellerId] ?? 'Unknown Booth';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8, left: 20),
                        child: Text(
                          '$boothName  주문상품',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ...items.map((item) {
                        final imagePath = item['imagePath'] as String?;
                        return Stack(
                          children: [
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          children: [
                                            SizedBox(
                                              height: 60,
                                              width: 60,
                                              child: FutureBuilder<String>(
                                                future: imagePath != null ? imageCache[imagePath] : Future.value(''),
                                                builder: (context, snapshot) {
                                                  final imageUrl = snapshot.data;
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return const Center(
                                                      child: CircularProgressIndicator(),
                                                    );
                                                  } else if (snapshot.hasError || imageUrl == null || imageUrl.isEmpty) {
                                                    return ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.asset(
                                                        'assets/catcul_w.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    );
                                                  } else {
                                                    return ClipRRect(
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
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Color(0xFFD1D1D1)),
                                                    shape: BoxShape.circle,
                                                    color: item['quantity'] == 0 ? Color(
                                                        0x91D1D1D1) : null,
                                                  ),
                                                  height: 30,
                                                  width: 30,
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.remove,
                                                        color: Colors.blue
                                                    ),
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    visualDensity: VisualDensity.compact,
                                                    onPressed: () {
                                                      if (item['quantity'] > 0) {
                                                        setState(() {
                                                          item['quantity']--;
                                                          totalCost -= item['sellingPrice'] as int;
                                                        });
                                                        _updateCartData(sellerId, cartData[sellerId]!);
                                                      }
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text('${item['quantity']}'),
                                                const SizedBox(width: 4),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Color(0xFFD1D1D1)),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  height: 30,
                                                  width: 30,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.add, color: Colors.red),
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    visualDensity: VisualDensity.compact,
                                                    onPressed: () {
                                                      setState(() {
                                                        item['quantity']++;
                                                        totalCost += item['sellingPrice'] as int;
                                                      });
                                                      _updateCartData(sellerId, cartData[sellerId]!);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['itemName'] ?? '',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              Text(
                                                '작가: ${item['artist']}',
                                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                              Text(
                                                '종류: ${item['itemType']}',
                                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '₩${numberFormat.format(item['sellingPrice']*item['quantity'])}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // 오른쪽 상단 X 버튼
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.grey),
                                        iconSize: 20,
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('삭제 확인'),
                                                content: const Text('이 상품을 장바구니에서 삭제하시겠습니까?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context), // 팝업 닫기
                                                    child: const Text('취소'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      // Firestore에서 삭제
                                                      await _deleteItemFromCart(sellerId, item);
                                                      Navigator.pop(context); // 팝업 닫기
                                                    },
                                                    child: const Text('삭제'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.zero,
            color: const Color(0xFFFDBE85),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/online_buyer_screens/online_buyer_pay', arguments: [festivalName, totalCost]);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        '총 금액: ₩${numberFormat.format(totalCost)}',
                      ),
                      const Text(
                        '구매하기',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
