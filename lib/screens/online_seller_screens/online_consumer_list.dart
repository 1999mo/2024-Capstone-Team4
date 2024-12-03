import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnlineConsumerList extends StatefulWidget {
  const OnlineConsumerList({super.key});

  @override
  State<OnlineConsumerList> createState() => _OnlineConsumerListState();
}

class _OnlineConsumerListState extends State<OnlineConsumerList> {
  String? festivalName;
  Map<String, List<dynamic>>? cachedConsumerData; // 데이터를 캐싱할 변수

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<Map<String, int>> _calculateTotalOrders() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return {};

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_consumer_list')
        .doc(festivalName);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return {};

    final data = docSnapshot.data();
    if (data == null) return {};

    final Map<String, int> totalOrders = {};

    for (var field in data.values) {
      if (field is List<dynamic>) {
        for (var i = 1; i < field.length; i++) {
          final orderItem = field[i];
          if (orderItem is Map<String, dynamic>) {
            final String itemName = orderItem['itemName'] ?? '';
            final int quantity = orderItem['quantity'] ?? 0;

            if (itemName.isNotEmpty) {
              totalOrders[itemName] = (totalOrders[itemName] ?? 0) + quantity;
            }
          }
        }
      }
    }
    return totalOrders;
  }

  Future<Map<String, List<dynamic>>> _fetchConsumerData() async {
    if (cachedConsumerData != null) {
      return cachedConsumerData!; // 이미 데이터를 가져왔으면 캐시된 데이터 반환
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return {};

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_consumer_list')
        .doc(festivalName);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return {};

    final data = docSnapshot.data();
    if (data == null) return {};

    final Map<String, List<dynamic>> result = {};
    for (var entry in data.entries) {
      if (entry.value is List<dynamic>) {
        result[entry.key] = entry.value as List<dynamic>;
      } else {
        print('Invalid data format for key ${entry.key}');
      }
    }

    cachedConsumerData = result; // 데이터 캐싱
    return result;
  }

  String _formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11) {
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 7)}-${cleaned.substring(7)}';
    } else {
      return phone;
    }
  }

  void _showTotalOrdersPopup() async {
    final totalOrders = await _calculateTotalOrders();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '총 주문 물품',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        padding: EdgeInsets.all(8),
                        itemCount: totalOrders.length,
                        itemBuilder: (context, index) {
                          final itemName = totalOrders.keys.elementAt(index);
                          final quantity = totalOrders[itemName]!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0), // 간격 조정
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('$itemName', style: TextStyle(fontSize: 16),),
                                Text('$quantity개', style: TextStyle(fontSize: 16),),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
        title: const Text('소비자 주문 목록'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: _fetchConsumerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('주문 목록이 없습니다.'));
          }

          final consumerData = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDBE85),
                  ),
                  onPressed: _showTotalOrdersPopup,
                  child: const Text(
                    '총 주문 물품',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    // decoration: BoxDecoration(
                    //   color: Color(0xFFFFFFFF),
                    //   borderRadius: BorderRadius.circular(8.0),
                    // ),
                    child: ListView.builder(
                      itemCount: consumerData.length,
                      itemBuilder: (context, index) {
                        final consumerId = consumerData.keys.elementAt(index);
                        final List<dynamic> orders = consumerData[consumerId]!;
                        final Map<String, dynamic> consumerInfo =
                            orders.first as Map<String, dynamic>;
                        final String name = consumerInfo['name'] ?? '';
                        final String phone =
                            _formatPhone(consumerInfo['phone'] ?? '');
                        final String zipcode = consumerInfo['zipcode'] ?? '';
                        final String address = consumerInfo['address'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0)),
                          child: ExpansionTile(
                            title: Text(
                              '주문자 정보',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text('$name'),
                                const SizedBox(
                                  height: 15,
                                  child: VerticalDivider(
                                    thickness: 1,
                                    color: Colors.grey,
                                    width: 20,
                                  ),
                                ),
                                Text('$phone'),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          child: const Text(
                                            '주문자',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text('$name'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          child: const Text(
                                            '주소',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '$address',
                                            softWrap: true,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          child: const Text(
                                            '연락처',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text('$phone'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 70,
                                          child: const Text(
                                            '우편번호',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text('$zipcode'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Divider(),
                                    const SizedBox(height: 4),
                                    const Text(
                                      '구매 정보',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    for (var i = 1; i < orders.length; i++)
                                      if (orders[i] is Map<String, dynamic>)
                                        Column(
                                          children: [
                                            Text(
                                              '${orders[i]['itemName'] ?? ''} : ${orders[i]['quantity'] ?? 0}개',
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )),
              )
            ],
          );
        },
      ),
    );
  }
}
