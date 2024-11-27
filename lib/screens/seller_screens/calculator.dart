import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

Future<Map<String, dynamic>?> showCalculatorBottomSheet({
  required BuildContext context,
  required Map<String, int> soldItems,
  required Map<String, Map<String, dynamic>> itemDetails,
  required int totalAmount,
  required String boothId,
}) async {
  int receivedAmount = 0;

  return await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final numberFormat = NumberFormat('#,###');
      final next5000 = ((totalAmount / 5000).ceil()) * 5000;
      final next10000 = next5000 == ((totalAmount / 10000).ceil()) * 10000
          ? ((totalAmount / 50000).ceil()) * 50000
          : ((totalAmount / 10000).ceil()) * 10000;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          final change = (receivedAmount - totalAmount).clamp(0, double.infinity).toInt();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),
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
                const SizedBox(height: 48),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = totalAmount;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(112,33),
                          backgroundColor: const Color(0xFFD1D1D1),
                        ),
                        child: Text(numberFormat.format(totalAmount), style: const TextStyle(color: Colors.black),),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = next5000;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(112,33),
                          backgroundColor: const Color(0xFFD1D1D1),
                        ),
                        child: Text(numberFormat.format(next5000), style: const TextStyle(color: Colors.black),),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = next10000;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          fixedSize: const Size(112,33),
                          backgroundColor: const Color(0xFFD1D1D1),
                        ),
                        child: Text(numberFormat.format(next10000), style: const TextStyle(color: Colors.black),),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  childAspectRatio: 1.5,
                  children: [
                    ...List.generate(9, (index) {
                      final number = (index + 1).toString();
                      return TextButton(
                        onPressed: () {
                          setState(() {
                            receivedAmount = int.parse('$receivedAmount$number');
                          });
                        },

                        child: Text(number, style: const TextStyle(fontSize: 24, color: Colors.black)),
                      );
                    }),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          receivedAmount = 0;
                        });
                      },
                      child: const Text('C', style: TextStyle(fontSize: 24, color: Colors.black)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          receivedAmount = int.parse('${receivedAmount}0');
                        });
                      },
                      child: const Text('0', style: TextStyle(fontSize: 24, color: Colors.black)),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (receivedAmount > 0) {
                            receivedAmount ~/= 10;
                          }
                        });
                      },
                      child: const Icon(Icons.backspace, color: Colors.black),
                    ),
                  ],
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
                        Navigator.pop(context, null); // 아무 값도 반환하지 않음
                      },
                      child: const Text('뒤로가기', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                    ),
          ),
                    const SizedBox(width: 10),
                    Expanded(
                    child: Container(
          decoration: BoxDecoration(
          color: const Color(0xFFFDBE85),
          borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton(
                      onPressed: () async {
                        if (receivedAmount < totalAmount) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('결제 실패'),
                                content: const Text('받은 금액이 부족합니다.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('확인'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null) {
                            // Firebase 참조 초기화
                            final boothRef = FirebaseFirestore.instance
                                .collection('Users')
                                .doc(uid)
                                .collection('booths')
                                .doc(boothId);

                            final salesCollection = boothRef.collection('sales');

                            // 현재 날짜와 시간을 기반으로 문서 ID 생성
                            final now = DateTime.now().toUtc().add(const Duration(hours: 9));
                            final formattedDate =
                                '${now.year}-${now.month}-${now.day}-${now.hour}-${now.minute}-${now.second}';
                            final newSaleId = 'sale-$formattedDate';

                            int totalProfit = 0;

                            // 1. stockQuantity 감소 로직 수행
                            for (final itemId in soldItems.keys) {
                              final itemRef = boothRef.collection('items').doc(itemId);
                              final soldQuantity = soldItems[itemId]!;

                              // `stockQuantity` 업데이트
                              final itemDoc = await itemRef.get();
                              if (itemDoc.exists) {
                                final data = itemDoc.data()!;
                                final currentStock = data['stockQuantity'] ?? 0;

                                // 재고 업데이트
                                final updatedStock = currentStock - soldQuantity;
                                await itemRef.update({'stockQuantity': updatedStock});
                              }
                            }

                            // 2. popUntil 및 SnackBar 표시
                            Navigator.popUntil(context, ModalRoute.withName('/seller_screens/selling'));

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('결제가 완료되었습니다.'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 1),
                              ),
                            );

                            // 3. 나머지 작업 비동기적으로 수행
                            Future(() async {
                              // 판매 문서 생성
                              await salesCollection.doc(newSaleId).set({
                                'itemsSold': soldItems,
                                'totalAmount': totalAmount,
                                'time': FieldValue.serverTimestamp(),
                                'profit': totalProfit, // 초기값으로 설정 (아래에서 업데이트 예정)
                              });

                              for (final itemId in soldItems.keys) {
                                final itemRef = boothRef.collection('items').doc(itemId);
                                final soldQuantity = soldItems[itemId]!;

                                final itemDoc = await itemRef.get();
                                if (itemDoc.exists) {
                                  final data = itemDoc.data()!;
                                  final sellingPrice = data['sellingPrice'] ?? 0;
                                  final costPrice = data['costPrice'] ?? 0;
                                  final artist = data['artist'] ?? 'Unknown'; // 작가 정보 가져오기

                                  // 순이익 계산
                                  final profitPerItem = (sellingPrice - costPrice) * soldQuantity;
                                  totalProfit += profitPerItem as int;

                                  // adjustment 문서에 기록
                                  final adjustmentRef = boothRef.collection('sales').doc('adjustment');
                                  final artistCollection = adjustmentRef.collection('artist');
                                  final artistDocRef = artistCollection.doc(artist);

                                  await FirebaseFirestore.instance.runTransaction((transaction) async {
                                    final artistDoc = await transaction.get(artistDocRef);

                                    if (artistDoc.exists) {
                                      final currentData = artistDoc.data()!;
                                      final currentSoldMap = Map<String, dynamic>.from(currentData['soldItems'] ?? {});

                                      // 기존 데이터에 팔린 물건 개수 추가
                                      currentSoldMap[itemId] = (currentSoldMap[itemId] ?? 0) + soldQuantity;

                                      // 매출 및 순이익 업데이트
                                      final totalSales =
                                          (currentData['totalSales'] ?? 0) + (sellingPrice * soldQuantity);
                                      final totalProfit = (currentData['totalProfit'] ?? 0) + profitPerItem;

                                      transaction.update(artistDocRef, {
                                        'soldItems': currentSoldMap,
                                        'totalSales': totalSales,
                                        'totalProfit': totalProfit,
                                      });
                                    } else {
                                      // 새로운 데이터 생성
                                      transaction.set(artistDocRef, {
                                        'soldItems': {itemId: soldQuantity},
                                        'totalSales': sellingPrice * soldQuantity,
                                        'totalProfit': profitPerItem,
                                      });
                                    }
                                  });
                                }
                              }

                              // 판매 문서에 최종 순이익 업데이트
                              await salesCollection.doc(newSaleId).update({
                                'profit': totalProfit,
                              });
                            });
                          }
                        }
                      },
                      child: const Text('결제하기', style: TextStyle(fontSize: 16, color: Colors.black)),
                    ),
                    ),
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
