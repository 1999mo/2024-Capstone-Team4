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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the festivalName from the previous screen
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

    // Safely process each field's data
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

    // Ensure all values in the map are List<dynamic>
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

  void _showTotalOrdersPopup() async {
    final totalOrders = await _calculateTotalOrders();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '총 주문 물품',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.maxFinite,
                      height: 300, // 최대 높이 제한
                      child: ListView.builder(
                        itemCount: totalOrders.length,
                        itemBuilder: (context, index) {
                          final itemName = totalOrders.keys.elementAt(index);
                          final quantity = totalOrders[itemName]!;
                          return ListTile(
                            title: Text('$itemName : $quantity개'),
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
            print('Error in FutureBuilder: ${snapshot.error}');
            return const Center(child: Text('오류가 발생했습니다.'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('주문 목록이 없습니다.'));
          }

          final consumerData = snapshot.data!;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _showTotalOrdersPopup,
                  child: const Text('총 주문 물품'),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListView.builder(
                    itemCount: consumerData.length,
                    itemBuilder: (context, index) {
                      final consumerId = consumerData.keys.elementAt(index);
                      final List<dynamic> orders = consumerData[consumerId]!;
                      final Map<String, dynamic> consumerInfo = orders.first as Map<String, dynamic>;
                      final String name = consumerInfo['name'] ?? '';
                      final String phone = _formatPhone(consumerInfo['phone'] ?? '');
                      final String zipcode = consumerInfo['zipcode'] ?? '';
                      final String address = consumerInfo['address'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(phone),
                                    const SizedBox(height: 4),
                                    Text(zipcode),
                                    const SizedBox(height: 4),
                                    Text(address),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 1; i < orders.length; i++)
                                      if (orders[i] is Map<String, dynamic>)
                                        Text(
                                          '${orders[i]['itemName'] ?? ''} : ${orders[i]['quantity'] ?? 0}개',
                                        ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
