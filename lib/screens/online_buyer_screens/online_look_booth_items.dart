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
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    if (args != null) {
      festivalName = args['festivalName'] as String?;
      sellerUid = args['sellerUid'] as String?;
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
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220, // 각 카드의 최대 가로 길이
                  crossAxisSpacing: 8, // 그리드 간의 가로 간격
                  mainAxisSpacing: 8, // 그리드 간의 세로 간격
                  childAspectRatio: 0.85, // 카드의 세로 비율
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
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('상품 정보'),
                                        IconButton(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close),
                                        ),
                                      ],
                                    ),
                                    content: SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.65,
                                      height: MediaQuery.of(context).size.height * 0.6, // 세로 길이 조정
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // 상품 이미지
                                                  Container(
                                                    height: 270,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Color(0xFFD1D1D1), width: 1),
                                                    ),
                                                    child: imageUrl != null
                                                        ? ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.network(
                                                        imageUrl,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Image.asset('assets/catcul_w.jpg');
                                                        },
                                                      ),
                                                    )
                                                        : ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.asset(
                                                        'assets/catcul_w.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    '${itemData['itemName'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 22, fontWeight: FontWeight.bold), // 폰트 크기 조정
                                                  ),
                                                  Text(
                                                    '작가: ${itemData['artist'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    '상품 종류: ${itemData['itemType'] ?? 'N/A'}',
                                                    style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                        fontWeight: FontWeight.bold),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    '${itemData['sellingPrice'] ?? 'N/A'}원',
                                                    style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.green),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      // 수량 선택 위젯
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Color(0xFFD1D1D1)),
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
                                                          icon: const Icon(Icons.remove, color: Colors.blue),
                                                          iconSize: 18,
                                                          padding: EdgeInsets.zero,
                                                          constraints: BoxConstraints(),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text('$quantity', style: const TextStyle(fontSize: 16)),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Color(0xFFD1D1D1)),
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
                                                          constraints: BoxConstraints(),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          GestureDetector(
                                            onTap: () async {
                                              // 장바구니 추가 로직
                                            },
                                            child: Container(
                                             width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFFDBE85),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  '장바구니에 추가',
                                                  style: TextStyle(color: Colors.black, fontSize: 16),
                                                ),
                                              ),
                                            ),
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
                              //crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // 작가명
                                Text(
                                  itemData['artist'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // 판매가
                                Text(
                                  '${itemData['sellingPrice'] ?? 'N/A'}원',
                                  style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w600),
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
