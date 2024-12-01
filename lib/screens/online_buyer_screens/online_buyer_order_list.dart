import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OnlineBuyerOrderList extends StatefulWidget {
  const OnlineBuyerOrderList({super.key});

  @override
  State<OnlineBuyerOrderList> createState() => _OnlineBuyerOrderListState();
}

class _OnlineBuyerOrderListState extends State<OnlineBuyerOrderList> {
  String? festivalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 이전 화면으로부터 festivalName을 받아옴
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  String _formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else {
      return phone; // Return as is if formatting is not possible
    }
  }

  Future<String?> _getImageUrl(String imagePath) async {
    try {
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      return null; // 이미지가 없거나 에러 발생 시 null 반환
    }
  }

  Future<Map<String, List<dynamic>>> _fetchOrderList() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return {};

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_order_list')
        .doc(festivalName);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return {};

    final data = snapshot.data();
    if (data == null) return {};

    // 데이터 변환 및 타입 확인
    final Map<String, List<dynamic>> result = {};
    for (var entry in data.entries) {
      if (entry.value is List<dynamic>) {
        result[entry.key] = entry.value as List<dynamic>;
      } else {
        print('Invalid data format for key ${entry.key}');
      }
    }
    return result;
  }

  void _showBuyerInfo(Map<String, dynamic> buyerInfo) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buyerInfo['name'] ?? '이름 없음',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('전화번호: ${_formatPhone(buyerInfo['phone'] ?? '')}'),
                    const SizedBox(height: 8),
                    Text('우편번호: ${buyerInfo['zipcode'] ?? ''}'),
                    const SizedBox(height: 8),
                    Text('주소: ${buyerInfo['address'] ?? ''}'),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
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
        title: Column(
          children: [
            const Text('주문 목록'),
            const Text('(부스별로 나눠져 표시됩니다.)', style: TextStyle(fontSize: 15),)
          ],
        ),
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 1; i < orderItems.length; i++) ...[
                              FutureBuilder<String?>(
                                future: _getImageUrl(orderItems[i]['imagePath']),
                                builder: (context, imageSnapshot) {
                                  final imageUrl = imageSnapshot.data;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: imageUrl != null
                                        ? Image.network(
                                      imageUrl,
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    )
                                        : Image.asset(
                                      'assets/catcul_w.jpg',
                                      height: 60,
                                      width: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 1; i < orderItems.length; i++) ...[
                              Text('상품명: ${orderItems[i]['itemName'] ?? ''}'),
                              Text('가격: ₩${orderItems[i]['sellingPrice'] ?? 0}'),
                              Text('수량: ${orderItems[i]['quantity'] ?? 0}개'),
                              const Divider(height: 16, thickness: 1),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          TextButton(
                            onPressed: () => _showBuyerInfo(buyerInfo),
                            child: const Text(
                              '주문자 정보',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
