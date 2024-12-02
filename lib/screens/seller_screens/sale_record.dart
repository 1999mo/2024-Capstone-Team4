import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 형식 변환용

class SaleRecord extends StatefulWidget {
  const SaleRecord({super.key});

  @override
  State<SaleRecord> createState() => _SaleRecordState();
}

class _SaleRecordState extends State<SaleRecord> {
  String? boothId;
  late CollectionReference salesCollection;
  List<DocumentSnapshot> saleDocs = []; // 판매 기록 저장

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
      _loadSalesData(); // 초기 데이터 로드
    } else {
      throw StateError('User is not authenticated or boothId is missing.');
    }
  }

  /// 판매 기록 삭제 함수
  Future<void> _deleteSaleRecord(String documentId, Map<String, dynamic> itemSold) async {
    try {
      // 1. 판매 기록 문서 삭제
      await salesCollection.doc(documentId).delete();

      // 2. 삭제된 판매 기록을 기반으로 다른 컬렉션 데이터 업데이트
      for (var entry in itemSold.entries) {
        final itemName = entry.key;
        final itemCount = entry.value;

        // 판매된 상품의 데이터를 가져옴
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

          // Artist 문서 참조
          final artistDocRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('booths')
              .doc(boothId!)
              .collection('sales')
              .doc('adjustment')
              .collection('artist')
              .doc(artistName);

          // Artist 문서 업데이트
          final artistDocSnapshot = await artistDocRef.get();
          if (artistDocSnapshot.exists) {
            final artistData = artistDocSnapshot.data() as Map<String, dynamic>;

            final soldItems = Map<String, dynamic>.from(artistData['soldItems'] ?? {});
            final totalProfit = artistData['totalProfit'] ?? 0;
            final totalSales = artistData['totalSales'] ?? 0;

            // 판매된 상품 수량 감소
            if (soldItems.containsKey(itemName)) {
              soldItems[itemName] = (soldItems[itemName] ?? 0) - itemCount;
              if (soldItems[itemName] <= 0) soldItems.remove(itemName); // 수량이 0 이하라면 제거
            }

            // 총 판매 금액 및 총 수익 업데이트
            final updatedTotalSales = totalSales - (sellingPrice * itemCount);
            final updatedTotalProfit = totalProfit - ((sellingPrice - costPrice) * itemCount);

            // Artist 문서 업데이트
            await artistDocRef.update({
              'soldItems': soldItems,
              'totalProfit': updatedTotalProfit,
              'totalSales': updatedTotalSales,
            });
          }
        }
      }

      // 3. UI 데이터 다시 로드
      await _loadSalesData();

      // 삭제 완료 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('판매 기록이 삭제되었습니다.')),
      );
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  /// 판매 기록 로드 함수
  Future<void> _loadSalesData() async {
    final snapshot = await salesCollection.orderBy('time', descending: true).get();
    setState(() {
      saleDocs = snapshot.docs; // 판매 기록 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 기록'),
        centerTitle: true,
      ),
      body: saleDocs.isEmpty
          ? const Center(child: CircularProgressIndicator())
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
                                  _deleteSaleRecord(saleDoc.id, itemSold); // 삭제 로직 호출
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

