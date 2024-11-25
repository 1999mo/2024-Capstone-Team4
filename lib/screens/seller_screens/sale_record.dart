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
  String? boothId; // 이전 라우트에서 받은 boothId
  late CollectionReference salesCollection; // Firestore 참조

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // boothId를 ModalRoute로 안전하게 추출
    boothId = ModalRoute.of(context)?.settings.arguments as String?;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && boothId != null) {
      salesCollection = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('booths')
          .doc(boothId!)
          .collection('sales');
    } else {
      throw StateError('User is not authenticated or boothId is missing.');
    }
  }

  Future<void> _deleteSaleRecord(String documentId) async {
    try {
      await salesCollection.doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('판매 기록이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###'); // 숫자 포맷 정의

    return Scaffold(
      appBar: AppBar(
        title: const Text('판매 기록'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: salesCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('오류 발생: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('판매 기록이 없습니다.'),
            );
          }

          final saleDocs = snapshot.data!.docs
              .where((doc) => doc.id.startsWith('sale')) // 문서 ID가 'sale'로 시작하는 것만 필터링
              .toList();

          return ListView.builder(
            itemCount: saleDocs.length,
            itemBuilder: (context, index) {
              final saleDoc = saleDocs[index];
              final saleData = saleDoc.data() as Map<String, dynamic>;
              final itemSold = saleData['itemsSold'] as Map<String, dynamic>? ?? {};
              final totalAmount = saleData['totalAmount'] ?? 0;
              final time = saleData['time'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                  .format((saleData['time'] as Timestamp).toDate())
                  : '시간 정보 없음';

              return GestureDetector(
                onLongPress: () {
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
                              _deleteSaleRecord(saleDoc.id);
                              Navigator.pop(context);
                            },
                            child: const Text('확인'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Padding(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}