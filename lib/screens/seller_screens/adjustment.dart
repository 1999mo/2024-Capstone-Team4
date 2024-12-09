import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // NumberFormat 사용을 위한 패키지

class Adjustment extends StatefulWidget {
  const Adjustment({super.key});

  @override
  State<Adjustment> createState() => _AdjustmentState();
}

class _AdjustmentState extends State<Adjustment> {
  String? boothId;
  late CollectionReference artistCollection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ModalRoute로 boothId를 안전하게 추출
    final args = ModalRoute.of(context)?.settings.arguments as String?;
    if (args == null) {
      throw ArgumentError('boothId is required as an argument.');
    }

    boothId = args;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('User is not authenticated.');
    }

    artistCollection = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId!)
        .collection('sales')
        .doc('adjustment')
        .collection('artist');
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###'); // 숫자 포맷 정의

    return Scaffold(
      appBar: AppBar(
        title: const Text('작가별 매출'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/seller_screens/sale_record', arguments: boothId);
            },
            child: const Text('판매기록', style: TextStyle(color: Colors.blue),),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
            future: artistCollection.get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text('Error loading data'),
                );
              } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('아직 판매된 상품이 없습니다.'),
                );
              }

              final artistDocs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: artistDocs.length,
                itemBuilder: (context, index) {
                  final artistDoc = artistDocs[index];
                  final artistName = artistDoc.id;
                  final totalSales = artistDoc['totalSales'] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/seller_screens/adjustment_detail',
                        arguments: {
                          'boothId': boothId,
                          'artistId': artistName,
                        },
                      );
                    },

                    child: Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              artistName,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Text(
                              '₩${numberFormat.format(totalSales)}', // 숫자를 포맷 적용
                              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.red),
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
          ),
        ],
      ),
    );
  }
}
