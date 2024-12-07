import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaleRecord extends StatefulWidget {
  const SaleRecord({super.key});

  @override
  State<SaleRecord> createState() => _SaleRecordState();
}

class _SaleRecordState extends State<SaleRecord> {
  String? boothId;
  late CollectionReference salesCollection;
  List<DocumentSnapshot> saleDocs = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    boothId = ModalRoute.of(context)?.settings.arguments as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && boothId != null) {
      salesCollection = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('booths')
          .doc(boothId!)
          .collection('sales');
      _loadSalesData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 인증 또는 boothId가 필요합니다.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _loadSalesData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final snapshot = await salesCollection.orderBy('time', descending: true).get();
      setState(() {
        saleDocs = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('판매 기록 로드 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteSaleRecord(String documentId, Map<String, dynamic> itemSold) async {
    setState(() {
      isLoading = true;
    });
    try {
      await salesCollection.doc(documentId).delete();
      for (var entry in itemSold.entries) {
        final itemName = entry.key;
        final itemCount = entry.value;

        final itemsSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('booths')
            .doc(boothId!)
            .collection('items')
            .where('itemName', isEqualTo: itemName)
            .get();

        if (itemsSnapshot.docs.isNotEmpty) {
          final itemData = itemsSnapshot.docs.first.data();
          final artistName = itemData['artist'];
          final sellingPrice = itemData['sellingPrice'];
          final costPrice = itemData['costPrice'];

          final artistDocRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('booths')
              .doc(boothId!)
              .collection('sales')
              .doc('adjustment')
              .collection('artist')
              .doc(artistName);

          final artistDocSnapshot = await artistDocRef.get();
          if (artistDocSnapshot.exists) {
            final artistData = artistDocSnapshot.data() as Map<String, dynamic>;

            final soldItems = Map<String, dynamic>.from(artistData['soldItems'] ?? {});
            final totalProfit = artistData['totalProfit'] ?? 0;
            final totalSales = artistData['totalSales'] ?? 0;

            if (soldItems.containsKey(itemName)) {
              soldItems[itemName] = (soldItems[itemName] ?? 0) - itemCount;
              if (soldItems[itemName] <= 0) soldItems.remove(itemName);
            }

            final updatedTotalSales = totalSales - (sellingPrice * itemCount);
            final updatedTotalProfit = totalProfit - ((sellingPrice - costPrice) * itemCount);

            await artistDocRef.update({
              'soldItems': soldItems,
              'totalProfit': updatedTotalProfit,
              'totalSales': updatedTotalSales,
            });
          }
        }
      }
      await _loadSalesData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('판매 기록이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 기록'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : saleDocs.isEmpty
          ? const Center(
        child: Text(
          '판매 기록이 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: saleDocs.length,
        itemBuilder: (context, index) {
          final saleDoc = saleDocs[index];
          final saleData = saleDoc.data() as Map<String, dynamic>;
          final itemSold = saleData['itemsSold'] as Map<String, dynamic>? ?? {};
          final totalAmount = saleData['totalAmount'] ?? 0;
          final time = saleData['time'] != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format((saleData['time'] as Timestamp).toDate())
              : '시간 정보 없음';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '판매 상품',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...itemSold.entries.map((entry) {
                        return Text(
                          '${entry.key}: ${numberFormat.format(entry.value)}개',
                          style: const TextStyle(fontSize: 14),
                        );
                      }).toList(),
                      const SizedBox(height: 8),
                      Text(
                        '총 금액: ₩${numberFormat.format(totalAmount)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '시간: $time',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('삭제 확인'),
                            content: const Text('정말로 삭제하시겠습니까?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteSaleRecord(saleDoc.id, itemSold);
                                  Navigator.pop(context);
                                },
                                child: const Text('확인'),
                              ),
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
        },
      ),
    );
  }
}
