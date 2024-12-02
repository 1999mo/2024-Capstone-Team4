import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BoothListScreen extends StatefulWidget {
  const BoothListScreen({super.key});

  @override
  State<BoothListScreen> createState() => _BoothListScreenState();
}

class _BoothListScreenState extends State<BoothListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String searchQuery = '';
  String? festivalName;
  bool isLoading = false;
  List<DocumentSnapshot> characterResults = [];
  bool hasMoreResults = true;
  DocumentSnapshot? lastDocument;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCharacterResults() async {
    if (!hasMoreResults || isLoading || festivalName == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collectionGroup('items')
          .where('itemName', isGreaterThanOrEqualTo: searchQuery.toLowerCase())
          .where('itemName', isLessThan: '${searchQuery.toLowerCase()}z')
          .limit(10);

      QuerySnapshot snapshot;
      if (lastDocument == null) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(lastDocument!).get();
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasMoreResults = false;
        });
      } else {
        setState(() {
          characterResults.addAll(snapshot.docs);
          lastDocument = snapshot.docs.last;
        });
      }
    } catch (e) {
      debugPrint('Error fetching character results: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _searchCharacters() {
    setState(() {
      characterResults.clear();
      lastDocument = null;
      hasMoreResults = true;
    });
    _fetchCharacterResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? 'Festival'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.store),
              text: '부스별 보기',
            ),
            Tab(
              icon: Icon(Icons.person),
              text: '캐릭터별 보기',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBoothView(),
          _buildCharacterView(),
        ],
      ),
    );
  }

  Widget _buildBoothView() {
    if (festivalName == null) {
      return const Center(
        child: Text('축제 이름을 불러오지 못했습니다.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: const InputDecoration(
              hintText: '부스명 또는 작가명으로 검색',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Festivals')
                .doc(festivalName)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !(snapshot.data?.exists ?? false)) {
                return const Center(child: Text('등록된 판매자가 없습니다.'));
              }

              final sellers = snapshot.data!['sellers'] as List<dynamic>;
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: Future.wait(
                  sellers.map((sellerUid) async {
                    final doc = await FirebaseFirestore.instance
                        .collection('Users')
                        .doc(sellerUid)
                        .collection('booths')
                        .doc(festivalName)
                        .get();

                    if (!doc.exists) return null;

                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final boothName = data['boothName']?.toString().toLowerCase() ?? '';
                    final painters = (data['painters'] as List<dynamic>? ?? [])
                        .map((painter) => painter.toString().toLowerCase())
                        .toList();

                    // 검색 조건 확인: 검색어가 포함되지 않으면 제외
                    if (searchQuery.isNotEmpty &&
                        !boothName.contains(searchQuery) &&
                        !painters.any((painter) => painter.contains(searchQuery))) {
                      return null;
                    }

                    return {'sellerUid': sellerUid, 'data': data}; // 조건에 맞는 데이터만 반환
                  }).toList(),
                ).then(
                      (results) => results
                      .where((element) => element != null) // null 값 필터링
                      .map((element) => element!) // null 값이 아님을 명시적으로 선언
                      .toList(),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('조건에 맞는 부스가 없습니다.'));
                  }

                  final filteredData = snapshot.data!;

                  return GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final sellerUid = filteredData[index]['sellerUid'] as String;
                      return _buildBoothCard(sellerUid);
                    },
                  );
                },
              );



            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoothCard(String sellerUid) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerUid)
          .collection('booths')
          .doc(festivalName)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final boothName = data['boothName'] ?? '이름 없음';
        final painters = (data['painters'] as List<dynamic>? ?? []).join(', ');

        return FutureBuilder<String>(
          future: FirebaseStorage.instance
              .ref('$sellerUid/profile_image.jpg')
              .getDownloadURL(),
          builder: (context, imageSnapshot) {
            Widget avatar;
            if (imageSnapshot.connectionState == ConnectionState.waiting) {
              avatar = const CircleAvatar(
                radius: 40,
                child: CircularProgressIndicator(),
              );
            } else if (imageSnapshot.hasError || !imageSnapshot.hasData) {
              avatar = const CircleAvatar(
                radius: 40,
                child: Icon(Icons.error),
              );
            } else {
              avatar = CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(imageSnapshot.data!),
              );
            }

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/buyer_screens/booth_items_list',
                  arguments: {
                    'uid': sellerUid,
                    'festivalName': festivalName,
                  },
                );
              },
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(height: 8),
                    Text(
                      boothName,
                      style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      painters,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

  }


  Widget _buildCharacterView() {
    if (festivalName == null) {
      return const Center(
        child: Text('축제 이름을 불러오지 못했습니다.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) {
              searchQuery = value.toLowerCase();
            },
            decoration: InputDecoration(
              hintText: '캐릭터명으로 검색',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searchCharacters,
              ),
            ),
          ),
        ),
        Expanded(
          child: characterResults.isEmpty
              ? const Center(child: Text('나의 최애케를 검색해보세요!'))
              : ListView.builder(
            itemCount: characterResults.length + 1,
            itemBuilder: (context, index) {
              if (index == characterResults.length) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return hasMoreResults
                    ? ElevatedButton(
                  onPressed: _fetchCharacterResults,
                  child: const Text('더 보기'),
                )
                    : const Center(
                  child: Text('더 이상 검색 결과가 없습니다.'),
                );
              }

              final item = characterResults[index].data()
              as Map<String, dynamic>;
              return _buildCharacterCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard(Map<String, dynamic> item) {
    final stock = item['stockQuantity'] ?? 0;
    return Card(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              item['imagePath'] ?? '',
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset('assets/catcul_w.jpg'),
            ),
          ),
          const SizedBox(height: 8),
          Text(item['itemName'] ?? '',
          ),
          const SizedBox(height: 4),
          Text(
            '${item['sellingPrice']}원',
          ),
          Text(
            stock > 0 ? '남은 수 $stock' : '품절',
            style: TextStyle(color: stock > 0 ? Colors.black : Colors.red),
          ),
        ],
      ),
    );
  }
}
