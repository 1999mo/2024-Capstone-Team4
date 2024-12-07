import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:catculator/screens/seller_screens/calculator.dart';

class SellingDetails extends StatefulWidget {
  const SellingDetails({super.key});

  @override
  State<SellingDetails> createState() => _SellingDetailsState();
}

class _SellingDetailsState extends State<SellingDetails> {
  Map<String, int> soldItems = {};
  Map<String, Map<String, dynamic>> itemDetails = {};
  int totalAmount = 0;
  String? boothId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    boothId = arguments['boothId'] as String? ?? 'Unknown';
    if (soldItems.isEmpty) {
      soldItems = Map<String, int>.from(arguments['soldItems'] ?? {});
      _fetchItemDetails();
    }
  }

  Future<void> _fetchItemDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return;
    final boothRef = FirebaseFirestore.instance.collection('Users').doc(uid).collection('booths').doc(boothId);

    Map<String, Map<String, dynamic>> details = {};
    int total = 0;

    for (String itemId in soldItems.keys) {
      final doc = await boothRef.collection('items').doc(itemId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final quantity = soldItems[itemId]!;
        final price = data['sellingPrice'] ?? 0;

        details[itemId] = {
          'itemName': data['itemName'] ?? '알 수 없음',
          'sellingPrice': price,
          'stockQuantity': data['stockQuantity'] ?? 0,
          'quantity': quantity,
          'painter': data['painter'] ?? 'Unknown', // 작가 이름 추가
        };

        total += (price as int) * quantity;
      }
    }

    setState(() {
      itemDetails = details;
      totalAmount = total;
    });
  }

  void _calculateTotalAmount() {
    totalAmount = itemDetails.values.fold(
      0,
      (sum, item) => sum + (item['sellingPrice'] as int) * (item['quantity'] as int),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세 정보'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          '주문 목록',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    //회색 구분선
                    const Divider(
                      color: Colors.grey,
                      thickness: 1, // 두께
                      indent: 20, // 왼쪽 여백
                      endIndent: 20, // 오른쪽 여백
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: itemDetails.entries.map((entry) {
                            final item = entry.value;
                            final productName = item['itemName'] ?? '알 수 없음';
                            final sellingPrice = item['sellingPrice'] as int? ?? 0;
                            final quantity = item['quantity'] as int? ?? 0;
                            final stockQuantity = item['stockQuantity'] as int? ?? 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    productName.length > 10
                                        ? '${productName.substring(0, 15)}...' // 10글자 초과 시 잘라내기
                                        : productName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${sellingPrice * quantity}원',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Color(0xFFD1D1D1)),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.all(4),
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Color(0xFFD1D1D1)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              height: 30,
                                              width: 30,
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.remove,
                                                  color: Colors.blue,
                                                ),
                                                iconSize: 18,
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () {
                                                  if (quantity > 0) {
                                                    setState(() {
                                                      item['quantity'] = quantity - 1;
                                                      soldItems[entry.key] = item['quantity']!;
                                                    });
                                                    _calculateTotalAmount();
                                                  }
                                                },
                                              ),
                                            ),

                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('$quantity', style: const TextStyle(fontSize: 16)),
                                            ),

                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Color(0xFFD1D1D1)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              height: 30,
                                              width: 30,
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.add,
                                                    color: Colors.red,
                                                ),
                                                iconSize: 18,
                                                padding: EdgeInsets.zero,
                                                constraints: BoxConstraints(),
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () {
                                                  if (quantity < stockQuantity) {
                                                    setState(() {
                                                      item['quantity'] = quantity + 1;
                                                      soldItems[entry.key] = item['quantity']!;
                                                    });
                                                    _calculateTotalAmount();
                                                  } else {
                                                    // 재고 초과 팝업
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: const Text('재고 초과'),
                                                          content: const Text('재고가 모자랍니다'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(context); // 팝업 닫기
                                                              },
                                                              child: const Text('확인'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    // 회색 구분선
                    const Divider(
                      color: Colors.grey,
                      thickness: 1, // 두께
                      indent: 20, // 왼쪽 여백
                      endIndent: 20, // 오른쪽 여백
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0), // 오른쪽 여백 추가
                            child: const Text(
                              '총 가격',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 16.0), // 왼쪽 여백 추가
                            child: Text(
                              '${NumberFormat('#,###').format(totalAmount)}원',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // 뒤로가기
                      },
                      child: const Text(
                        '뒤로가기',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBE85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        final result = await showCalculatorBottomSheet(
                          context: context,
                          soldItems: soldItems,
                          itemDetails: itemDetails,
                          totalAmount: totalAmount,
                          boothId: boothId!,
                        );

                        // 결과를 받아 상태를 갱신
                        if (result != null) {
                          setState(() {
                            soldItems = result['soldItems'] ?? soldItems;
                            itemDetails = result['itemDetails'] ?? itemDetails;
                            totalAmount = result['totalAmount'] ?? totalAmount;
                          });
                        }
                      },
                      child: const Text(
                        '결제하기',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
