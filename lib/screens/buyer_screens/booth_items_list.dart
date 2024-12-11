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
  String? mapImageUrl;
  String? location;
  bool isFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, String?>;
    sellerUid = arguments['sellerUid'] ?? '';
    festivalName = arguments['festivalName'] ?? '';
    _fetchMapImage();
  }

  Future<void> _fetchMapImage() async {
    if (isFetched) return;
    try {
      final formattedName = festivalName!.replaceAll(' ', '_');
      final ref = FirebaseStorage.instance.ref('maps/$formattedName.jpg');
      final url = await ref.getDownloadURL();
      setState(() {
        mapImageUrl = url;
        isFetched = true;
      });
    } catch (e) {
      setState(() {
        mapImageUrl = null;
      });
    }
  }

  Future<List<String>> _fetchBoothName() async {
    final doc = await FirebaseFirestore.instance.collection('Users').doc(sellerUid).collection('booths').doc(festivalName).get();

    return [doc.data()?['boothName'] ?? 'Unknown Booth', doc.data()?['location'] ?? 'x'];
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

  void _showFullScreenImage(String imageUrl, String location) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // 화면 전체에 꽉 차게
          child: Column(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.only(top: 16, right: 16),
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  maxScale: 10.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // 이미지의 원본 비율 계산
                      double imageAspectRatio = 1.5; // 예: 가로:세로 비율이 3:2인 경우
                      double imageWidth = constraints.maxWidth; // 이미지의 최대 너비
                      double imageHeight = imageWidth / imageAspectRatio;

                      // 이미지가 컨테이너보다 높거나 넓을 경우 처리
                      if (imageHeight > constraints.maxHeight) {
                        imageHeight = constraints.maxHeight;
                        imageWidth = imageHeight * imageAspectRatio;
                      }

                      // 실제 이미지가 렌더링될 위치의 시작 좌표
                      double imageLeft = (constraints.maxWidth - imageWidth) / 2;
                      double imageTop = (constraints.maxHeight - imageHeight) / 2;

                      // locationRatio 계산
                      int locationRatio = 0;

                      // 첫 글자 가져오기
                      String firstLetter = location[0].toLowerCase();
                      // 첫 글자의 알파벳 순서 계산
                      int offset = firstLetter.codeUnitAt(0) - 'a'.codeUnitAt(0);

                      // locationRatio 계산 (7과 4를 번갈아 더하기)
                      for (int i = 1; i <= offset; i++) {
                        // 'b'부터 시작하므로 i는 1부터
                        locationRatio += (i % 2 == 1) ? 7 : 4; // 홀수 번째는 7, 짝수 번째는 4
                      }

                      // 위치 계산
                      double leftPosition = imageLeft + (imageWidth / 320) * (8 + locationRatio);
                      double topPosition = imageTop + (imageHeight / 3) * 1.01;

                      return Stack(
                        children: [
                          // 이미지
                          Center(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                          // 빨간 사각형
                          Positioned(
                            left: leftPosition - 4.0, // 사각형 중심 맞추기
                            top: topPosition - 40.0, // 사각형 중심 맞추기
                            child: Container(
                              width: 8.0,
                              height: 85.0,
                              decoration: BoxDecoration(
                                color: Colors.transparent, // 투명한 배경
                                border: Border.all(color: Colors.red, width: 2.0), // 빨간 테두리
                                shape: BoxShape.rectangle, // 사각형 모양
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<List<String>>(
          future: _fetchBoothName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            location = snapshot.data?[1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(snapshot.data?[0].toUpperCase() ?? 'Booth'),
                Text(
                  '부스위치 : ${snapshot.data?[1]}' ?? 'x',
                  style: TextStyle(fontSize: 15, color: Colors.blue),
                  textAlign: TextAlign.start,
                )
              ],
            );
          },
        ),
        actions: [
          Column(
            children: [
              IconButton(
                  onPressed: () {
                    _showFullScreenImage(mapImageUrl!, location!);
                  },
                  icon: Icon(Icons.map)),
            ],
          )
        ],
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
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220, // 각 카드의 최대 가로 길이
              crossAxisSpacing: 8, // 그리드 간의 가로 간격
              mainAxisSpacing: 8, // 그리드 간의 세로 간격
              childAspectRatio: 0.85, // 카드의 세로 비율
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
                              height: MediaQuery.of(context).size.height * 0.55,
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
                                            height: 270,
                                            child: CachedNetworkImage(
                                              imageUrl: item['imagePath'] ?? 'assets/catcul_w.jpg',
                                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
                                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text('작가: ${item['artist'] ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('상품 종류: ${item['itemType'] ?? 'Unknown'}',
                                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      stockQuantity > 0 ? '재고: ${stockQuantity}' : '품절',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: stockQuantity > 0 ? Colors.grey : Colors.red,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 20),
                                    Text('${item['sellingPrice'] ?? 0}원',
                                        style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.green)),
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
                                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
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
                              style: itemName.length > 10
                                  ? const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                                  : const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
