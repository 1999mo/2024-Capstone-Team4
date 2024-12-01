import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdjustmentDetail extends StatefulWidget {
  const AdjustmentDetail({super.key});

  @override
  State<AdjustmentDetail> createState() => _AdjustmentDetailState();
}

class _AdjustmentDetailState extends State<AdjustmentDetail> {
  String? boothId;
  String? artistId;
  List<String> itemTypes = ['전체'];
  String selectedFilter = '전체';
  Map<String, dynamic> soldItems = {};
  int totalSales = 0;
  int totalProfit = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // boothId와 artistId 추출
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null || !args.containsKey('boothId') || !args.containsKey('artistId')) {
      throw ArgumentError('boothId and artistId are required as arguments.');
    }

    boothId = args['boothId'];
    artistId = args['artistId'];

    // 데이터 로드
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('User is not authenticated.');
    }

    final artistDocRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId!)
        .collection('sales')
        .doc('adjustment')
        .collection('artist')
        .doc(artistId);

    final itemsCollectionRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId!)
        .collection('items');

    // 데이터 가져오기
    final artistDoc = await artistDocRef.get();
    if (artistDoc.exists) {
      final data = artistDoc.data()!;
      setState(() {
        totalSales = data['totalSales'] as int? ?? 0;
        totalProfit = data['totalProfit'] as int? ?? 0;
        soldItems = Map<String, dynamic>.from(data['soldItems'] ?? {});
      });
    }

    // itemType 리스트 가져오기
    final itemsSnapshot = await itemsCollectionRef.get();
    final types = <String>{'전체'};
    for (final doc in itemsSnapshot.docs) {
      final itemType = doc['itemType'] as String?;
      if (itemType != null) {
        types.add(itemType);
      }
    }
  }


  Future<List<MapEntry<String, Map<String, dynamic>>>> _getFilteredItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return [];

    // items 컬렉션 참조
    final itemsCollectionRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId!)
        .collection('items');

    final filteredItems = <MapEntry<String, Map<String, dynamic>>>[];

    for (final entry in soldItems.entries) {
      final itemId = entry.key;
      final soldQuantity = entry.value as int;

      final doc = await itemsCollectionRef.doc(itemId).get();
      if (doc.exists) {
        final sellingPrice = doc['sellingPrice'] ?? 0;
        final itemType = doc['itemType'] ?? 'Unknown';

        if (selectedFilter == '전체' || itemType == selectedFilter) {
          filteredItems.add(MapEntry(itemId, {
            'quantity': soldQuantity,
            'sales': sellingPrice * soldQuantity,
            'itemName': doc['itemName'] ?? 'Unknown',
          }));
        }
      }
    }


    // 매출순으로 정렬
    filteredItems.sort((a, b) => b.value['sales'].compareTo(a.value['sales']));
    return filteredItems;
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('작가별 매출 상세'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Text(
                    artistId ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('총 매출: ₩${numberFormat.format(totalSales)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('총 순수익: ₩${numberFormat.format(totalProfit)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: selectedFilter,
              items: itemTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFilter = value!;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
              future: _getFilteredItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final filteredItems = snapshot.data!;

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final entry = filteredItems[index];
                    final itemName = entry.value['itemName'];
                    final quantity = entry.value['quantity'];
                    final sales = entry.value['sales'];

                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(16.0),
                        color: Color(0xFFFFF2F2)
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center, // 세로로 가운데 정렬
                        children: [
                          Expanded(child: Text(itemName, textAlign: TextAlign.center, style: TextStyle(fontSize: 16,))),
                          Container(
                            height: 20, // VerticalDivider의 높이 설정
                            child: const VerticalDivider(color: Colors.grey, thickness: 1),
                          ),
                          Expanded(
                            child: Text('수량: ${numberFormat.format(quantity)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16,)),
                          ),
                          Container(
                            height: 20, // VerticalDivider의 높이 설정
                            child: const VerticalDivider(color: Colors.grey, thickness: 1),
                          ),
                          Expanded(
                            child: Text('매출: ₩${numberFormat.format(sales)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 16,)),
                          ),
                        ],
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
