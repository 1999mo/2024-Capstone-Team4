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

                // 필터링된 데이터 생성
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getFilteredBoothData(sellers),
                  builder: (context, boothSnapshot) {
                    if (boothSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!boothSnapshot.hasData || boothSnapshot.data!.isEmpty) {
                      return const Center(child: Text('검색 결과가 없습니다.'));
                    }

                    final filteredBooths = boothSnapshot.data!;
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200, // 각 카드의 최대 가로 길이
                        crossAxisSpacing: 8, // 그리드 간의 가로 간격
                        mainAxisSpacing: 8, // 그리드 간의 세로 간격
                        childAspectRatio: 0.85, // 카드의 세로 비율
                      ),
                      itemCount: filteredBooths.length,
                      itemBuilder: (context, index) {
                        final boothData = filteredBooths[index];
                        final sellerUid = boothData['sellerUid'];
                        final boothName = boothData['boothName'];
                        final painterList = boothData['painters'];
                        final imageUrl = boothData['imageUrl'];

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
                              side: BorderSide(color: const Color(0xFFD1D1D1), width: 1),
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Text(
                                      boothName,
                                      textAlign: TextAlign.center,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // 작가 목록
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Text(
                                      painterList,
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
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
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getFilteredBoothData(List<dynamic> sellers) async {
    final List<Map<String, dynamic>> filteredBooths = [];

    for (final sellerUid in sellers) {
      final boothDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerUid)
          .collection('booths')
          .doc(festivalName)
          .get();

      if (!boothDoc.exists) continue;

      final boothData = boothDoc.data()!;
      final String boothName = boothData['boothName'] ?? '이름 없음';
      final List<dynamic> painters = boothData['painters'] ?? [];
      final String painterList = painters.join(', ');

      // 검색 조건 확인
      if (searchQuery.isNotEmpty &&
          !boothName.toLowerCase().contains(searchQuery) &&
          !painters.any((painter) => painter.toString().toLowerCase().contains(searchQuery))) {
        continue;
      }

      // 이미지 URL 가져오기
      final imageUrl = await _getProfileImageUrl(sellerUid);

      filteredBooths.add({
        'sellerUid': sellerUid,
        'boothName': boothName,
        'painters': painterList,
        'imageUrl': imageUrl,
      });
    }

    return filteredBooths;
  }
}
