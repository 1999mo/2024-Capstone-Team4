import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OrderList extends StatefulWidget {
  const OrderList({super.key});

  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> {
  String? festivalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<Map<String, List<dynamic>>> _fetchOrderList() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return {};

    final docRef =
    FirebaseFirestore.instance.collection('Users').doc(uid).collection('pre_order_list').doc(festivalName);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return {};

    final data = snapshot.data();
    if (data == null) return {};

    return data.map((key, value) => MapEntry(key, value as List<dynamic>));
  }

  Future<String?> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _showExchangeTicket(Map<String, dynamic> buyerInfo) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '이 화면을 판매자에게 보여주세요',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    buyerInfo['qr_path'] != null
                        ? Image.network(
                      buyerInfo['qr_path'],
                      height: 150,
                      width: 150,
                      fit: BoxFit.contain,
                    )
                        : const Icon(Icons.qr_code, size: 150, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      '주문 번호: ${buyerInfo['pre_order_code'] ?? 'N/A'}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 목록'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: _fetchOrderList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('주문 목록이 없습니다.'));
          }

          final orderData = snapshot.data!;

          return ListView.builder(
            itemCount: orderData.length,
            itemBuilder: (context, index) {
              final orderId = orderData.keys.elementAt(index);
              final List<dynamic> orderItems = orderData[orderId]!;
              final Map<String, dynamic> buyerInfo = orderItems.first as Map<String, dynamic>;

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              buyerInfo['boothName'] ?? '이름 없는 부스',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            TextButton(
                              onPressed: () => _showExchangeTicket(buyerInfo),
                              child: const Row(
                                children: [
                                  Text(
                                    '교환권 보기',
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                        for (var i = 1; i < orderItems.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                FutureBuilder<String?>(
                                  future: _getImageUrl(orderItems[i]['imagePath']),
                                  builder: (context, imageSnapshot) {
                                    final imageUrl = imageSnapshot.data;
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null
                                          ? Image.network(
                                        imageUrl,
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      )
                                          : Image.asset(
                                        'assets/catcul_w.jpg',
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${orderItems[i]['itemName'] ?? ''}',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '${orderItems[i]['sellingPrice'] ?? 0}원',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '수량: ${orderItems[i]['quantity'] ?? 0}개',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (i < orderItems.length - 1)
                            const Divider(height: 0, thickness: 1, color: Color(0x7BD1D1D1)),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 8, thickness: 8, color: Color(0x8BD1D1D1)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
