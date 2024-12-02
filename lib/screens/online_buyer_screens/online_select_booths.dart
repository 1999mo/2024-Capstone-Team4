import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class OnlineSelectBooths extends StatefulWidget {
  const OnlineSelectBooths({super.key});

  @override
  State<OnlineSelectBooths> createState() => _OnlineSelectBoothsState();
}

class _OnlineSelectBoothsState extends State<OnlineSelectBooths> {
  String? festivalName; // 이전 화면에서 받아온 festivalName
  String searchQuery = ''; // 검색어 상태

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // festivalName을 arguments로부터 추출
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<String?> _getProfileImageUrl(String sellerUid) async {
    try {
      final ref = FirebaseStorage.instance.ref('$sellerUid/profile_image.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null; // 이미지가 없거나 에러가 발생한 경우
    }
  }

  @override
  Widget build(BuildContext context) {
    if (festivalName == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('온라인 상품 둘러보기')),
        body: const Center(
          child: Text('축제 이름을 불러오지 못했습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName!),
      ),
      body: _buildBoothList(),
    );
  }

  Widget _buildBoothList() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // 검색 필드
          TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.trim().toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: '부스명 혹은 작가명으로 검색',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 부스 목록 표시
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('Festivals').doc(festivalName).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
                  return const Center(child: Text('등록된 판매자가 없습니다.'));
                }

                final festivalData = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> sellers = festivalData['sellers'] ?? [];

                if (sellers.isEmpty) {
                  return const Center(child: Text('등록된 판매자가 없습니다.'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: sellers.length,
                  itemBuilder: (context, index) {
                    final sellerUid = sellers[index] as String;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(sellerUid)
                          .collection('booths')
                          .doc(festivalName)
                          .get(),
                      builder: (context, boothSnapshot) {
                        if (boothSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!boothSnapshot.hasData || !(boothSnapshot.data?.exists ?? false)) {
                          return const SizedBox.shrink(); // 부스 정보가 없으면 표시하지 않음
                        }

                        final boothData = boothSnapshot.data!.data() as Map<String, dynamic>;
                        final String boothName = boothData['boothName'] ?? '이름 없음';
                        final List<dynamic> painters = boothData['painters'] ?? [];
                        final String painterList = painters.join(', ');

                        // 검색 조건
                        if (searchQuery.isNotEmpty &&
                            !boothName.toLowerCase().contains(searchQuery) &&
                            !painters.any((painter) => painter.toString().toLowerCase().contains(searchQuery))) {
                          return const SizedBox.shrink();
                        }

                        return FutureBuilder<String?>(
                          future: _getProfileImageUrl(sellerUid),
                          builder: (context, imageSnapshot) {
                            final imageUrl = imageSnapshot.data;

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/online_buyer_screens/online_look_booth_items',
                                  arguments: {'sellerUid': sellerUid, 'festivalName': festivalName},
                                );
                              },
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Color(0xFFD1D1D1), width: 1),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // 원형 이미지
                                      CircleAvatar(
                                        backgroundImage: imageUrl != null
                                            ? NetworkImage(imageUrl)
                                            : const AssetImage('assets/catcul_w.jpg') as ImageProvider,
                                        radius: 50,
                                        backgroundColor: Colors.grey[200],
                                      ),
                                      const SizedBox(height: 8),
                                      // 부스 이름
                                      Text(
                                        boothName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // 작가 목록
                                      Text(
                                        painterList,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 14),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
