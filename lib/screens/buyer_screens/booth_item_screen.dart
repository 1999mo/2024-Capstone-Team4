import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoothItemScreen extends StatefulWidget {
  const BoothItemScreen({super.key});

  @override
  State<BoothItemScreen> createState() => _BoothItemScreenState();
}

class _BoothItemScreenState extends State<BoothItemScreen> {
  late final String itemId;
  late final String festivalName;
  late final String sellerUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    itemId = arguments?['itemId'] ?? '';
    festivalName = arguments?['festivalName'] ?? '';
    sellerUid = arguments?['sellerUid'] ?? '';
  }

  Future<Map<String, dynamic>> fetchItemDetails() async {
    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(sellerUid)
        .collection('booths')
        .doc(festivalName)
        .collection('items')
        .doc(itemId);

    final docSnapshot = await docRef.get();
    return docSnapshot.data() as Map<String, dynamic>? ?? {};
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: FutureBuilder<Map<String, dynamic>>(
        future: fetchItemDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          }

          final itemData = snapshot.data!;
          final imagePath = itemData['imagePath'] ?? '';
          final itemName = itemData['itemName'] ?? 'Unknown';
          final itemType = itemData['itemType'] ?? 'Unknown';
          final artist = itemData['artist'] ?? 'Unknown';
          final stockQuantity = itemData['stockQuantity'] ?? 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // X 버튼
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              // 이미지
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imagePath,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset('assets/catcul_w.jpg', height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ),
              // 상품명
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  itemName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              // 상품타입
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '상품 타입: $itemType',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              // 작가명
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  '작가: $artist',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              // 재고수
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  stockQuantity > 0 ? '재고 수: $stockQuantity' : '품절',
                  style: TextStyle(
                    fontSize: 16,
                    color: stockQuantity > 0 ? Colors.black : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
