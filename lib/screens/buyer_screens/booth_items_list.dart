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
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(sellerUid)
        .collection('booths')
        .doc(festivalName)
        .get();

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
    final docRef =
        FirebaseFirestore.instance.collection('OnlineStore').doc(festivalName).collection(sellerUid).doc(itemId);

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
                          return AlertDialog(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('상품 정보'),
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            content: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.7,
                              height: MediaQuery.of(context).size.height * 0.7,
                              //insetPadding: const EdgeInsets.all(16.0),
                              child: ListView(children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 이미지
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Color(0xFFD1D1D1), width: 1),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 250,
                                            child: CachedNetworkImage(
                                              imageUrl: item['imagePath'] ?? 'assets/catcul_w.jpg',
                                              placeholder: (context, url) =>
                                                  const Center(child: CircularProgressIndicator()),
                                              errorWidget: (context, url, error) => Container(
                                                  width: double.infinity,
                                                  child: Image.asset('assets/catcul_w.jpg', fit: BoxFit.cover)),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                    Text(
                                      item['itemName'] ?? 'Unknown',
                                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                                    const SizedBox(height: 8),
                                    Text(
                                        '작가: ${item['artist'] ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        '상품 종류: ${item['itemType'] ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        stockQuantity > 0 ? '재고: ${stockQuantity}' : '품절',
                                        style: TextStyle(fontSize: 18,  color: stockQuantity > 0 ? Colors.grey : Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                        '${item['sellingPrice'] ?? 0}원',
                                        style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold, color: Colors.green)),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Color(0xFFD1D1D1), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    FutureBuilder<String>(
                                      future: _getImageUrl(imagePath),
                                      builder: (context, imageSnapshot) {
                                        if (imageSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        final imageUrl = imageSnapshot.data ?? 'assets/catcul_w.jpg';
                                        return Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Color(0xFFD1D1D1), width: 1),
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            placeholder: (context, url) =>
                                                const Center(child: CircularProgressIndicator()),
                                            errorWidget: (context, url, error) => Container(
                                                width: double.infinity,
                                                child: Image.asset(
                                                  'assets/catcul_w.jpg',
                                                  fit: BoxFit.cover,
                                                )),
                                            width: double.infinity,
                                            height: 250,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                    if (stockQuantity == 0)
                                      Container(
                                        color: Colors.black.withOpacity(0.5),
                                        alignment: Alignment.center,
                                        child: Image.asset(
                                          'assets/sold-out.png',
                                          fit: BoxFit.contain,
                                          width: 65,
                                          height: 65,
                                        ),
                                        // child: const Text(
                                        //   '',
                                        //   style: TextStyle(
                                        //     color: Colors.white,
                                        //     fontWeight: FontWeight.w500,
                                        //     fontSize: 20,
                                        //   ),
                                        // ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            // const SizedBox(height: 4),
                            Text('$sellingPrice원'),
                            // const SizedBox(height: 4),
                            Text(
                              stockQuantity > 0 ? '수량: $stockQuantity' : '품절',
                              style: TextStyle(color: stockQuantity > 0 ? Colors.black : Colors.red),
                            ),
                            const SizedBox(height: 8),
                            if (isOnlineSelling)
                              const Text(
                                '현재 온라인 판매중!',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
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
                                          backgroundColor: hasClicked ? Colors.grey : Color(0xFFFDBE85),
                                        ),
                                        child: Text(
                                          hasClicked ? '신청 완료' : '구매 희망하기',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
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
