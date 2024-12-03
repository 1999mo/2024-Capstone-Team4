import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class BagListScreen extends StatefulWidget {
  const BagListScreen({super.key});

  @override
  State<BagListScreen> createState() => _BagListScreenState();
}

class _BagListScreenState extends State<BagListScreen> {
  String? festivalName;
  Map<String, List<Map<String, dynamic>>> basketData = {};
  int totalCost = 0;

  final numberFormat = NumberFormat('#,###');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
    _fetchBasketItems();
  }

  Future<void> _fetchBasketItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    try {
      final basketRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('basket')
          .doc(festivalName);
      final basketSnapshot = await basketRef.get();

      if (basketSnapshot.exists) {
        final data = basketSnapshot.data() as Map<String, dynamic>;
        final fetchedData = <String, List<Map<String, dynamic>>>{};

        for (var sellerUid in data.keys) {
          final items = (data[sellerUid] as List<dynamic>).cast<Map<String, dynamic>>();
          fetchedData[sellerUid] = items;
        }

        setState(() {
          basketData = fetchedData;
          _calculateTotalCost();
        });
      }
    } catch (e) {
      debugPrint('Error fetching basket items: $e');
    }
  }

  void _calculateTotalCost() {
    totalCost = basketData.values
        .expand((items) => items)
        .fold(0, (sum, item) => sum + (item['sellingPrice'] as int) * (item['quantity'] as int));
    setState(() {});
  }

  Future<void> _updateQuantity(String sellerUid, int index, int quantity) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    basketData[sellerUid]![index]['quantity'] = quantity;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('basket')
        .doc(festivalName)
        .set(basketData);

    _calculateTotalCost();
  }

  Future<void> _removeItem(String sellerUid, int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    basketData[sellerUid]!.removeAt(index);
    if (basketData[sellerUid]!.isEmpty) {
      basketData.remove(sellerUid);
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('basket')
        .doc(festivalName)
        .set(basketData);

    _calculateTotalCost();
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = basketData.entries.toList();
    sortedEntries.sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? '장바구니'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: sortedEntries.length,
            itemBuilder: (context, sellerIndex) {
              final sellerUid = sortedEntries[sellerIndex].key;
              final items = sortedEntries[sellerIndex].value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(sellerUid)
                    .collection('booths')
                    .doc(festivalName)
                    .get(),
                builder: (context, snapshot) {
                  final boothName = snapshot.data?['boothName'] ?? '부스명 없음';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '$boothName',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item['imagePath'] ?? '',
                                        placeholder: (context, url) => const CircularProgressIndicator(),
                                        errorWidget: (context, url, error) => Image.asset('assets/catcul_w.jpg'),
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: item['quantity'] > 1
                                              ? () {
                                            _updateQuantity(sellerUid, index, item['quantity'] - 1);
                                          }
                                              : null,
                                        ),
                                        Text('${item['quantity']}'),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            _updateQuantity(sellerUid, index, item['quantity'] + 1);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['itemName'] ?? '',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₩${numberFormat.format(item['sellingPrice'])}', // 상품 가격 표시
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.grey),
                                          onPressed: () {
                                            _removeItem(sellerUid, index);
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20), // 아래 요소와 간격 유지
                                    Text(
                                      '₩${numberFormat.format(item['sellingPrice'] * item['quantity'])}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            )

                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xfffdbe85),
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '₩${numberFormat.format(totalCost)} 결제하기',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                onTap: () {

                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
