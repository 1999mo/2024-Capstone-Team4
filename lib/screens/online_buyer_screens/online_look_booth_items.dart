import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnlineLookBoothItems extends StatefulWidget {
  const OnlineLookBoothItems({super.key});

  @override
  State<OnlineLookBoothItems> createState() => _OnlineLookBoothItemsState();
}

class _OnlineLookBoothItemsState extends State<OnlineLookBoothItems> {
  String? festivalName;
  String? sellerUid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, String?>;
    if (args != null) {
      festivalName = args['festivalName'];
      sellerUid = args['sellerUid'];
    }
  }

  Future<String?> _getImageUrl(String itemId) async {
    try {
      final processedItemId = itemId.replaceAll(' ', '_');
      final ref =
          FirebaseStorage.instance.ref('$sellerUid/$processedItemId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null; // 이미지가 없거나 에러가 발생한 경우
    }
  }

  @override
  Widget build(BuildContext context) {
    if (festivalName == null || sellerUid == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상품 둘러보기'),
          centerTitle: true,
        ),
        body: const Center(child: Text('필수 데이터를 불러오지 못했습니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 둘러보기'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('OnlineStore')
            .doc(festivalName)
            .collection(sellerUid!)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('등록된 상품이 없습니다.'));
          }

          final items = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final itemData = items[index].data() as Map<String, dynamic>;
                  final itemId = items[index].id;

                  return FutureBuilder<String?>(
                    future: _getImageUrl(itemId),
                    builder: (context, imageSnapshot) {
                      final imageUrl = imageSnapshot.data;

                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              int quantity = 1;

                              return StatefulBuilder(
                                builder: (context, setState) {
                                  return AlertDialog(
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('상품 정보'),
                                        IconButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                    content: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.65,
                                      height: MediaQuery.of(context).size.height * 0.5,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // 상품 이미지
                                            Container(
                                              height: 250,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.grey,
                                                    width: 1),
                                              ),
                                              child: imageUrl != null
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return Image.asset(
                                                              'assets/catcul_w.jpg');
                                                        },
                                                      ),
                                                    )
                                                  : ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      child: Image.asset(
                                                          'assets/catcul_w.jpg'),
                                                    ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                                '${itemData['itemName'] ?? 'N/A'}',
                                                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                                            //const SizedBox(height: 2),
                                            Text(
                                                '작가: ${itemData['artist'] ?? 'N/A'}',
                                                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            //const SizedBox(height: 2),
                                            Text(
                                                '상품 종류: ${itemData['itemType'] ?? 'N/A'}',
                                                style: TextStyle(fontSize: 16, color: Colors.grey, )),
                                            const SizedBox(height: 16),
                                            Text(
                                                '${itemData['sellingPrice'] ?? 'N/A'}원',
                                                style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                // 수량 선택 위젯
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Color(0xFFD1D1D1)),
                                                    shape: BoxShape.circle,
                                                    color: quantity == 1 ? Color(0x91D1D1D1) : null,
                                                  ),
                                                  height: 30,
                                                  width: 30,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      if (quantity > 1) {
                                                        setState(() {
                                                          quantity--;
                                                        });
                                                      }
                                                    },
                                                    icon: const Icon(
                                                        Icons.remove,
                                                        color: Colors.blue),
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text('$quantity',
                                                    style: const TextStyle(
                                                        fontSize: 16)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Color(0xFFD1D1D1)),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  height: 30,
                                                  width: 30,
                                                  child: IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        quantity++;
                                                      });
                                                    },
                                                    icon: const Icon(Icons.add, color: Colors.red),
                                                    iconSize: 18,
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        BoxConstraints(),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      GestureDetector(
                                        onTap: () async {
                                          final uid = FirebaseAuth
                                              .instance.currentUser?.uid;
                                          if (uid == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text('로그인이 필요합니다.')),
                                            );
                                            return;
                                          }

                                          try {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text('상품이 장바구니에 추가되었습니다.'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );

                                            final basketRef = FirebaseFirestore
                                                .instance
                                                .collection('Users')
                                                .doc(uid)
                                                .collection('online_basket')
                                                .doc(
                                                    festivalName); // 축제 이름에 해당하는 문서

                                            // 새로 추가할 상품 정보
                                            final newItem = {
                                              'itemName': itemData['itemName'],
                                              'artist': itemData['artist'],
                                              'quantity': quantity, // 선택된 수량
                                              'sellingPrice':
                                                  itemData['sellingPrice'],
                                              'itemType': itemData['itemType'],
                                              'imagePath':
                                                  '${sellerUid}/${itemId.replaceAll(' ', '_')}.jpg',
                                            };

                                            // 기존 데이터 확인
                                            final snapshot =
                                                await basketRef.get();
                                            if (snapshot.exists) {
                                              // 문서가 존재할 경우
                                              final currentData =
                                                  snapshot.data() as Map<String,
                                                          dynamic>? ??
                                                      {};

                                              if (currentData
                                                  .containsKey(sellerUid)) {
                                                // 해당 sellerId 필드가 존재하면 기존 배열에서 itemName 비교
                                                final List<dynamic>
                                                    currentItems =
                                                    currentData[sellerUid]
                                                        as List<dynamic>;

                                                // 동일한 itemName을 가진 항목이 있는지 확인
                                                currentItems.removeWhere(
                                                    (item) =>
                                                        item['itemName'] ==
                                                        itemData['itemName']);

                                                // 새로운 항목 추가
                                                currentItems.add(newItem);

                                                // 업데이트
                                                await basketRef.update({
                                                  sellerUid!: currentItems,
                                                });
                                              } else {
                                                // 해당 sellerId 필드가 없으면 새 필드 생성
                                                await basketRef.update({
                                                  sellerUid!: [newItem],
                                                });
                                              }
                                            } else {
                                              // 문서가 존재하지 않을 경우 새로 생성
                                              await basketRef.set({
                                                sellerUid!: [newItem],
                                              });
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      '장바구니 추가 중 오류가 발생했습니다: $e')),
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFDBE85),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            '장바구니에 추가',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side:
                                BorderSide(color: Color(0xFFD1D1D1), width: 1),
                          ),
                          //elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 상품 이미지
                                Expanded(
                                  child: Container(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                    'assets/catcul_w.jpg');
                                              },
                                            )
                                          : Container(width: double.infinity, child: Image.asset('assets/catcul_w.jpg',fit: BoxFit.cover,)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 상품명
                                Text(
                                  itemData['itemName'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // 작가명
                                Text(
                                  itemData['artist'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // 판매가
                                Text(
                                  '${itemData['sellingPrice'] ?? 'N/A'}원',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
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
            ],
          );
        },
      ),
    );
  }
}
