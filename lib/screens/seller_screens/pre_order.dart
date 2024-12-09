import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PreOrder extends StatefulWidget {
  const PreOrder({super.key});

  @override
  State<PreOrder> createState() => _PreOrderState();
}

class _PreOrderState extends State<PreOrder> {
  String? festivalName;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<Map<String, dynamic>> _fetchPreOrderList() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return {};

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('pre_order_consumer_list')
        .doc(festivalName);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return {};

    final data = snapshot.data();
    if (data == null) return {};
    return data;
  }

  Future<void> _deleteOrder(String orderId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('pre_order_consumer_list')
        .doc(festivalName);

    await docRef.update({orderId: FieldValue.delete()});
  }

  void _showQrDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '이 화면을 판매자에게 보여주세요',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Image.network(
                  order['qr_path'] ?? '',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/catcul_w.jpg', height: 200, width: 200),
                ),
                const SizedBox(height: 16),
                Text(
                  '주문 번호: ${order['pre_order_code'] ?? ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _processOrder(String orderId, List<dynamic> orderItems) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    final preOrderItems = <String, int>{};
    for (var i = 1; i < orderItems.length; i++) {
      preOrderItems[orderItems[i]['itemName']] = orderItems[i]['quantity'];
    }

    await Navigator.pushNamed(
      context,
      '/seller_screens/selling_details',
      arguments: {
        'boothId': festivalName,
        'soldItems': preOrderItems,
      },
    );

    await _deleteOrder(orderId);
  }

  void _scanQrCode() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: SizedBox(
          height: 400,
          child: Column(
            children: [
              AppBar(
                title: const Text('QR 코드 스캔'),
                automaticallyImplyLeading: false,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (BarcodeCapture capture) {
                    if (capture.barcodes.isNotEmpty) {
                      final String? code = capture.barcodes.first.rawValue;
                      if (code != null) {
                        setState(() {
                          searchQuery = code.toLowerCase();
                          if (_searchController.text != code) {
                            _searchController.text = code;
                          }
                        });
                        Navigator.pop(context); // QR 코드 스캔 화면 닫기
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? '사전 구매 목록'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQrCode,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: '주문 번호로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchPreOrderList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      '목록이 없습니다.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final orders = snapshot.data!;
                final filteredOrders = orders.entries.where((entry) {
                  final preOrderCode = (entry.value[0]['pre_order_code'] ?? '').toLowerCase();
                  return preOrderCode.contains(searchQuery);
                }).toList();

                if (filteredOrders.isEmpty) {
                  return const Center(
                    child: Text(
                      '이미 처리되었거나, 사전 구매자가 아닙니다.',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final orderId = filteredOrders[index].key;
                    final orderItems = filteredOrders[index].value as List<dynamic>;
                    final orderInfo = orderItems[0];

                    return Column(
                      children: [
                        ListTile(
                          title: Text('주문번호: ${orderInfo['pre_order_code']}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: TextButton(
                            onPressed: () => _processOrder(orderId, orderItems),
                            child: const Text(
                              '주문 진행',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        for (var i = 1; i < orderItems.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    orderItems[i]['imagePath'] ?? '',
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset('assets/catcul_w.jpg', height: 80, width: 80),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 220,
                                      child: Text(
                                        orderItems[i]['itemName'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${orderItems[i]['sellingPrice'] ?? 0}원',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '수량: ${orderItems[i]['quantity']}개',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (i < orderItems.length - 1)
                            const Divider(height: 1, thickness: 1, color: Colors.grey),
                        ],
                        const Divider(height: 8, thickness: 8, color: Color(0xFFE0E0E0)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
