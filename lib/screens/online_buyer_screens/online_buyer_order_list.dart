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

    final docRef =
        FirebaseFirestore.instance.collection('Users').doc(uid).collection('online_order_list').doc(festivalName);

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

  Future<String> _getBoothName(String sellerId) async {
    final refGetBoothName =
        await FirebaseFirestore.instance.collection('Users').doc(sellerId).collection('booths').doc(festivalName).get();
    return refGetBoothName['sellerId'];
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
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 0,
                    maxHeight: double.infinity, // 높이 제한 없음
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      const Text('주문자 정보 확인', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                              width: 70,
                              child: const Text('주문자',
                                  style: TextStyle(
                                    color: Colors.grey,
                                      fontWeight: FontWeight.w600
                                  ))),
                          Text('${buyerInfo['name'] ?? '이름 없음'}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 70,
                              child: const Text('연락처',
                                  style: TextStyle(
                                    color: Colors.grey,
                                      fontWeight: FontWeight.w600
                                  ))),
                          Text('${_formatPhone(buyerInfo['phone'] ?? '')}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 70,
                              child: const Text('우편번호',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600
                                  ))),
                          Text('${buyerInfo['zipcode'] ?? ''}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                              width: 70,
                              child: Text('주소',
                                  style: TextStyle(
                                    color: Colors.grey,
                                      fontWeight: FontWeight.w600
                                  ))),
                          Container(
                            width: 200,
                            child: Text(
                              '${buyerInfo['address'] ?? ''}',
                              softWrap: true, // 텍스트가 줄 바꿈되도록 설정
                              maxLines: 5, // 최대 5줄까지만 표시
                              overflow: TextOverflow.ellipsis, // 5줄을 초과하면 "..."으로 표시
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
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
        actions: [
          IconButton(
              onPressed: () {
                //실험용 실험용
              },
              icon: Icon(Icons.ac_unit_outlined))
        ],
        title: Column(
          children: [
            const Text('주문 목록'),
            const Text(
              '(부스별로 나눠져 표시됩니다.)',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(
              height: 8,
            )
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

              return Column(
                children: [
                  Container(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                buyerInfo['boothName']??'이름 없는 부스',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              TextButton(
                                onPressed: () => _showBuyerInfo(buyerInfo),
                                child: const Row(
                                  children: [
                                    Text(
                                      '주문자 정보',
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
                        ),
                        for (var i = 1; i < orderItems.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                FutureBuilder<String?>(
                                  future: _getImageUrl(orderItems[i]['imagePath']),
                                  builder: (context, imageSnapshot) {
                                    final imageUrl = imageSnapshot.data;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8), // 둥근 모서리 유지
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
                                    Text('${orderItems[i]['sellingPrice'] ?? 0}원',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                    Text('수량: ${orderItems[i]['quantity'] ?? 0}개',
                                        style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (i < orderItems.length - 1) // 마지막 아이템에는 경계선 제외
                            const Divider(
                              height: 0,
                              thickness: 1,
                              color: Color(0x7BD1D1D1),
                            ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(
                    height: 8,
                    thickness: 8,
                    color: Color(0x8BD1D1D1),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }
}
