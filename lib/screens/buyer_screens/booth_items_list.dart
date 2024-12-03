import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BoothItemsList extends StatefulWidget {
  const BoothItemsList({super.key});

  @override
  State<BoothItemsList> createState() => _BoothItemsListState();
}

class _BoothItemsListState extends State<BoothItemsList> {
  late String sellerUid;
  late String festivalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, String?>;
    sellerUid = arguments['sellerUid'] ?? '';
    festivalName = arguments['festivalName'] ?? '';
  }

  Future<String> _fetchBoothName() async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(sellerUid).collection('booths').doc(festivalName).get();

    return doc.data()?['boothName'] ?? 'Unknown Booth';
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      // 이미 URL인지 확인
      if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
        return imagePath;
      }

      // URL이 아니라면 Firebase Storage에서 가져오기
      return await FirebaseStorage.instance.ref(imagePath).getDownloadURL();
    } catch (e) {
      // 에러 발생 시 로컬 이미지 경로 반환
      return 'assets/catcul_w.jpg';
    }
  }

  Future<bool> _isOnlineSelling(String itemId) async {
    final docRef = FirebaseFirestore.instance.collection('OnlineStore').doc(festivalName).collection(sellerUid).doc(itemId);

    final docSnapshot = await docRef.get();
    return docSnapshot.exists;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _fetchBoothName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            return Text(snapshot.data ?? 'Booth');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerUid)
            .collection('booths')
            .doc(festivalName)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No items available.'));
          }

          final items = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index].data() as Map<String, dynamic>;
              final itemId = items[index].id;
              final itemName = item['itemName'] ?? 'Unknown';
              final sellingPrice = item['sellingPrice'] ?? 0;
              int stockQuantity = item['stockQuantity'] ?? 0;
              final imagePath = item['imagePath'] ?? '';
              final expect = item['expect'];
              final userId = FirebaseAuth.instance.currentUser?.uid;

              return FutureBuilder<bool>(
                future: _isOnlineSelling(itemId),
                builder: (context, sellingSnapshot) {
                  final isOnlineSelling = sellingSnapshot.data ?? false;

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return Dialog(
                            insetPadding: const EdgeInsets.all(16.0),
                            child: ListView(children: [
                              Column(
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
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: CachedNetworkImage(
                                          imageUrl: item['imagePath'] ?? 'assets/catcul_w.jpg',
                                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => Image.asset('assets/catcul_w.jpg', fit: BoxFit.contain),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 상품명
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item['itemName'] ?? 'Unknown',
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  // 상품타입
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      '상품 타입: ${item['itemType'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  // 작가명
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      '작가: ${item['artist'] ?? 'Unknown'}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  // 재고수
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Text(
                                      stockQuantity > 0 ? '재고 수: ${stockQuantity}' : '품절',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: stockQuantity > 0 ? Colors.black : Colors.red,
                                      ),
                                    ),
                                  ),
                                  Text('판매가: ${sellingPrice}'),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ]),
                          );
                        },
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: FutureBuilder<String>(
                                future: _getImageUrl(imagePath),
                                builder: (context, imageSnapshot) {
                                  if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  final imageUrl = imageSnapshot.data ?? 'assets/catcul_w.jpg';
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => Image.asset('assets/catcul_w.jpg'),
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            itemName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text('$sellingPrice원'),
                          const SizedBox(height: 4),
                          Text(
                            stockQuantity > 0 ? '수량: $stockQuantity' : '품절',
                            style: TextStyle(color: stockQuantity > 0 ? Colors.black : Colors.red),
                          ),
                          const SizedBox(height: 8),
                          if (isOnlineSelling)
                            const Text(
                              '현재 온라인 판매중!',
                              style: TextStyle(color: Colors.green),
                            )
                          else if (stockQuantity == 0 && expect != null)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(sellerUid)
                                  .collection('booths')
                                  .doc(festivalName)
                                  .collection('items')
                                  .doc(itemId)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                                final clicks = List<String>.from(data['clicks'] ?? []);

                                final hasClicked = clicks.contains(userId);

                                return Column(
                                  children: [
                                    Text('구매 희망자 수: $expect'),
                                    ElevatedButton(
                                      onPressed: hasClicked
                                          ? null
                                          : () async {
                                              final docRef = FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(sellerUid)
                                                  .collection('booths')
                                                  .doc(festivalName)
                                                  .collection('items')
                                                  .doc(itemId);

                                              await docRef.update({
                                                'expect': FieldValue.increment(1),
                                                'clicks': FieldValue.arrayUnion([userId]),
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: hasClicked ? Colors.grey : Colors.blue,
                                      ),
                                      child: Text(
                                        hasClicked ? '신청 완료' : '구매 희망하기',
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
