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
          final change = (receivedAmount - totalAmount)
              .clamp(0, double.infinity)
              .toInt();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                          receivedAmount = totalAmount;
                        });
                      },
                      child: Text(numberFormat.format(totalAmount)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          receivedAmount = next5000;
                        });
                      },
                      child: Text(numberFormat.format(next5000)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          receivedAmount = next10000;
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
                      child: const Icon(Icons.backspace),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, null); // 아무 값도 반환하지 않음
                      },
                      child: const Text('뒤로가기', style: TextStyle(fontSize: 16)),
                    ),
                    TextButton(
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
                            final boothRef = FirebaseFirestore.instance
                                .collection('Users')
                                .doc(uid)
                                .collection('booths')
                                .doc(boothId);

                            final salesCollection = boothRef.collection('sales');
                            final saleDoc = await salesCollection
                                .orderBy(FieldPath.documentId, descending: true)
                                .limit(1)
                                .get();
                            final lastId = saleDoc.docs.isNotEmpty
                                ? int.tryParse(saleDoc.docs.first.id
                                .replaceFirst('sale', '')) ??
                                0
                                : 0;
                            final newSaleId = 'sale${lastId + 1}';

                            final painterSummary = {};
                            for (final item in soldItems.entries) {
                              final painter = itemDetails[item.key]?['painter'] ?? 'Unknown';
                              painterSummary[painter] =
                                  (painterSummary[painter] ?? 0) + item.value;
                            }

                            await salesCollection.doc(newSaleId).set({
                              'itemsSold': soldItems,
                              'totalAmount': totalAmount,
                              'time': FieldValue.serverTimestamp(),
                              'painterSummary': painterSummary,
                            });

                            for (final itemId in soldItems.keys) {
                              final itemRef = boothRef.collection('items').doc(itemId);
                              final soldQuantity = soldItems[itemId]!;
                              final itemDoc = await itemRef.get();
                              if (itemDoc.exists) {
                                final currentStock =
                                    itemDoc.data()?['stockQuantity'] ?? 0;
                                final updatedStock = currentStock - soldQuantity;

                                await itemRef.update({'stockQuantity': updatedStock});
                              }
                            }
                          }

                          Navigator.pop(context, {
                            'soldItems': soldItems,
                            'itemDetails': itemDetails,
                            'totalAmount': totalAmount,
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('결제가 완료되었습니다.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
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

