import 'package:catculator/screens/buyer_screens/bag_qr.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BagScreen extends StatefulWidget {
  const BagScreen({Key? key}) : super(key: key);

  @override
  State<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends State<BagScreen> {
  // Dummy data for order items (can be replaced with actual data later)
  final List<Map<String, dynamic>> orderItems = [
    {
      'itemName': '상품A',
      'price': 1000,
      'itemQuantitySelected': 2,
    },
    {
      'itemName': '상품B',
      'price': 1500,
      'itemQuantitySelected': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate the total price
    int totalPrice = orderItems.fold<int>(0, (sum, item) {
      return sum + (int.tryParse(item['price'].toString()) ?? 0) * (int.tryParse(item['itemQuantitySelected'].toString()) ?? 0);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('미리담기 목록'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rectangle for 주문 목록 and item list combined
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주문 목록 title
                  const Center(
                    child: Text(
                    '주문 목록',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  // List of items
                  Column(
                    children: orderItems.map((item) {
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item['itemName']),
                              Text(
                                '${item['price']} x ${item['itemQuantitySelected']} = ${item['price'] * item['itemQuantitySelected']} 원',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Line separator for total price
                  const Divider(),
                  const SizedBox(height: 16),
                  // Total price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '총 가격 : $totalPrice 원',
                        style: const TextStyle(
                          fontSize: 30.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Buttons at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BagQrScreen(),
                      ),
                    );
                  },
                  child: const Text('결제하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}