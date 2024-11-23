import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SellingDetails extends StatefulWidget {
  const SellingDetails({super.key});

  @override
  State<SellingDetails> createState() => _SellingDetailsState();
}

class _SellingDetailsState extends State<SellingDetails> {
  Map<String, Map<String, dynamic>> soldItems = {}; // 판매된 상품 정보
  int totalAmount = 0; // 총 가격

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 넘겨받은 판매 정보
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    soldItems = arguments.map((key, value) => MapEntry(key, {...value}));
    _calculateTotalAmount();
  }

  // 총 가격 계산
  void _calculateTotalAmount() {
    totalAmount = soldItems.entries.fold(
      0,
          (sum, entry) {
        final price = entry.value['sellingPrice'] as int? ?? 0;
        final quantity = entry.value['quantity'] as int? ?? 0;
        return sum + (price * quantity);
      },
    );
    setState(() {});
  }

  void _showPaymentSheet() {
    PaymentSheet.show(context, totalAmount, soldItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 주문 목록 컨테이너
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
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '주문 목록',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(color: Colors.grey), // 회색 구분선

                    // 스크롤 가능한 상품 리스트
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: soldItems.entries.map((entry) {
                            final productName = entry.value['itemName'] ?? '알 수 없음';
                            final sellingPrice = entry.value['sellingPrice'] as int? ?? 0;
                            final quantity = entry.value['quantity'] as int? ?? 0;
                            final stockQuantity = entry.value['stockQuantity'] as int? ?? 0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    productName,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${sellingPrice * quantity}원',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          if (quantity < stockQuantity) {
                                            setState(() {
                                              soldItems[entry.key]!['quantity'] = quantity + 1;
                                            });
                                            _calculateTotalAmount();
                                          }
                                        },
                                      ),
                                      Text('$quantity', style: const TextStyle(fontSize: 16)),
                                      IconButton(
                                        icon: const Icon(Icons.remove),
                                        onPressed: () {
                                          if (quantity > 0) {
                                            setState(() {
                                              soldItems[entry.key]!['quantity'] = quantity - 1;
                                            });
                                            _calculateTotalAmount();
                                          }
                                        },
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

                    const Divider(color: Colors.grey), // 회색 구분선

                    // 총 가격
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '총 가격',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(totalAmount)}원',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 뒤로가기 & 결제하기 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 뒤로가기
                  },
                  child: const Text(
                    '뒤로가기',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: _showPaymentSheet,
                  child: const Text(
                    '결제하기',
                    style: TextStyle(fontSize: 16),
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

// 결제 시트
class PaymentSheet {
  static void show(BuildContext context, int totalAmount, Map<String, Map<String, dynamic>> soldItems) {
    final numberFormat = NumberFormat('#,###');
    int receivedAmount = 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final next5000 = ((totalAmount / 5000).ceil()) * 5000;
            final next10000 = ((totalAmount / 10000).ceil()) * 10000;
            final change = (receivedAmount - totalAmount).clamp(0, double.infinity).toInt();

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 받은 금액
                  Text(
                    '받은 금액 ${numberFormat.format(receivedAmount)}원',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: receivedAmount < totalAmount ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '결제해야할 금액 ${numberFormat.format(totalAmount)}원 / 거스름 돈: ${numberFormat.format(change)}원',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount += totalAmount;
                          });
                        },
                        child: Text(numberFormat.format(totalAmount)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount += next5000;
                          });
                        },
                        child: Text(numberFormat.format(next5000)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount += next10000;
                          });
                        },
                        child: Text(numberFormat.format(next10000)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    children: [
                      ...List.generate(9, (index) {
                        final number = (index + 1).toString();
                        return TextButton(
                          onPressed: () {
                            setState(() {
                              receivedAmount = int.parse('$receivedAmount$number');
                            });
                          },
                          child: Text(number, style: const TextStyle(fontSize: 24)),
                        );
                      }),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = 0;
                          });
                        },
                        child: const Text('C', style: TextStyle(fontSize: 24)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = int.parse('${receivedAmount}0');
                          });
                        },
                        child: const Text('0', style: TextStyle(fontSize: 24)),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            if (receivedAmount > 0) {
                              receivedAmount ~/= 10;
                            }
                          });
                        },
                        child: const Text('<=', style: TextStyle(fontSize: 24)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('뒤로가기', style: TextStyle(fontSize: 16)),
                      ),
                      TextButton(
                        onPressed: () {
                          // 결제 완료 로직 추가
                        },
                        child: const Text('결제하기', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
