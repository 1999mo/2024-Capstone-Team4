import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BoothListScreen extends StatefulWidget {
  const BoothListScreen({super.key});

  @override
  State<BoothListScreen> createState() => _BoothListScreenState();
}

class _BoothListScreenState extends State<BoothListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String boothSearchQuery = '';
  String characterSearchQuery = '';
  String? festivalName;
  bool isLoadingCharacters = false;
  bool hasMoreCharacters = true;
  List<DocumentSnapshot> characterResults = [];
  DocumentSnapshot? lastCharacterDocument;
  final _boothSearchController = TextEditingController();
  final _characterSearchController = TextEditingController();
  int visibleCharacterCount = 10;
  final _scrollController = ScrollController();

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
    _boothSearchController.dispose();
    _characterSearchController.dispose();
    super.dispose();
  }

  void _resetBoothSearch() {
    _boothSearchController.clear();
    setState(() {
      boothSearchQuery = '';
    });
  }

  // 검색어 초기화 함수
  void _resetCharacterSearch() {
    _characterSearchController.clear();
    setState(() {
      characterSearchQuery = '';
      visibleCharacterCount = 10; // 초기화
    });
  }

  Future<void> _fetchCharacterResults() async {
    if (!hasMoreCharacters || isLoadingCharacters || festivalName == null)
      return;

    setState(() {
      isLoadingCharacters = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collectionGroup('items')
          .where('itemName',
              isGreaterThanOrEqualTo: characterSearchQuery.toLowerCase())
          .where('itemName',
              isLessThan: '${characterSearchQuery.toLowerCase()}z')
          .limit(10);

      QuerySnapshot snapshot;
      if (lastCharacterDocument == null) {
        snapshot = await query.get();
      } else {
        snapshot = await query.startAfterDocument(lastCharacterDocument!).get();
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          hasMoreCharacters = false;
        });
      } else {
        setState(() {
          characterResults.addAll(snapshot.docs);
          lastCharacterDocument = snapshot.docs.last;
        });
      }
    } catch (e) {
      debugPrint('Error fetching character results: $e');
    } finally {
      setState(() {
        isLoadingCharacters = false;
      });
    }
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
              icon: Icon(Icons.card_giftcard),
              text: '상품별 보기',
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
            controller: _boothSearchController,
            onChanged: (value) {
              setState(() {
                boothSearchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: '부스명 또는 작가명으로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: boothSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _resetBoothSearch,
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Festivals')
                .doc(festivalName)
                .get(),
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
                    final boothName =
                        data['boothName']?.toString().toLowerCase() ?? '';
                    final painters = (data['painters'] as List<dynamic>? ?? [])
                        .map((painter) => painter.toString().toLowerCase())
                        .toList();

                    if (boothSearchQuery.isNotEmpty &&
                        !boothName.contains(boothSearchQuery) &&
                        !painters.any(
                            (painter) => painter.contains(boothSearchQuery))) {
                      return null;
                    }

                    return {'sellerUid': sellerUid, 'data': data};
                  }).toList(),
                ).then((results) => results
                    .whereType<Map<String, dynamic>>()
                    .toList()), // 수정된 부분
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final sellerUid =
                          filteredData[index]['sellerUid'] as String;
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
                radius: 50,
                child: CircularProgressIndicator(),
              );
            } else if (imageSnapshot.hasError || !imageSnapshot.hasData) {
              avatar = const CircleAvatar(
                radius: 50,
                child: Icon(Icons.error),
              );
            } else {
              avatar = CircleAvatar(
                radius: 50,
                backgroundImage:
                    CachedNetworkImageProvider(imageSnapshot.data!),
              );
            }

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/buyer_screens/booth_items_list',
                  arguments: {
                    'sellerUid': sellerUid,
                    'festivalName': festivalName,
                  },
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFD1D1D1), width: 1),
                ),
                elevation: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    avatar,
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        boothName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        painters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildCharacterView() {
    if (festivalName == null) {
      return const Center(
        child: Text('축제 이름을 불러오지 못했습니다.'),
      );
    }

    List<Map<String, dynamic>>? _cachedItems;

    Future<List<Map<String, dynamic>>> _fetchItemsWithCache() async {
      if (_cachedItems != null) {
        return _cachedItems!;
      }
      _cachedItems = await _fetchItemsFromReferences();
      return _cachedItems!;
    }

    Future<void> loadMoreItems() async {
      setState(() {
        visibleCharacterCount += 10; // 아이템 10개씩 더 보기
      });
    }

    void resetVisibleItems() {
      setState(() {
        visibleCharacterCount = 10; // 초기 상태
      });
    }

    return Column(
      children: [
        // 검색 텍스트 필드
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _characterSearchController,
            onChanged: (value) {
              setState(() {
                characterSearchQuery = value.toLowerCase();
                _cachedItems = null; // 캐시 초기화
              });
            },
            decoration: InputDecoration(
              hintText: '캐릭터명으로 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: characterSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _resetCharacterSearch,
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchItemsWithCache(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('오류 발생'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('상품이 없습니다.'));
              }

              final filteredItems = snapshot.data!
                  .where((item) =>
                      item['itemName']
                          ?.toString()
                          .toLowerCase()
                          .contains(characterSearchQuery) ??
                      false)
                  .toList();

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      key: const PageStorageKey('characterGridView'),
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredItems.length > visibleCharacterCount
                          ? visibleCharacterCount
                          : filteredItems.length,
                      itemBuilder: (context, index) {
                        if (index < filteredItems.length) {
                          final item = filteredItems[index];
                          return _buildCharacterCard(item);
                        }
                        return Container(); //버튼
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDBE85),
                      ),
                      onPressed: filteredItems.length > visibleCharacterCount
                          ? loadMoreItems
                          : resetVisibleItems,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center, // 중앙 정렬
                        children: [
                          Text(
                            filteredItems.length > visibleCharacterCount
                                ? '더 보기'
                                : '접기',
                            style: const TextStyle(color: Colors.black),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            filteredItems.length > visibleCharacterCount
                                ? Icons.expand_more
                                : Icons.expand_less,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // 각 배열에서 참조된 문서의 데이터를 가져오는 함수
  Future<List<Map<String, dynamic>>> _fetchItemsFromReferences() async {
    try {
      // 'Items' 컬렉션의 festivalName 문서 가져오기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Items')
          .doc(festivalName)
          .get();

      if (!querySnapshot.exists) return [];

      final data = querySnapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> items = [];

      for (var arrayKey in data.keys) {
        final references = data[arrayKey] as List<dynamic>? ?? [];
        for (var referencePath in references) {
          // 참조된 문서 데이터 가져오기
          final referenceDoc = await referencePath.get();
          if (referenceDoc.exists) {
            items.add({
              ...referenceDoc.data() as Map<String, dynamic>,
              'sellerUid': arrayKey,
            });
          }
        }
      }

      return items;
    } catch (e) {
      debugPrint('Error fetching items: $e');
      return [];
    }
  }

// 캐릭터 카드 생성 함수
  Widget _buildCharacterCard(Map<String, dynamic> item) {
    return GestureDetector(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: const Color(0xFFD1D1D1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    width: double.infinity,
                    fit: BoxFit.cover,
                    item['imagePath'] ?? '',
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset('assets/catcul_w.jpg'), // 대체 이미지
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['itemName'] ?? '',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      onTap: () async {
        final ref = await FirebaseFirestore.instance
            .collection('Users')
            .doc(item['sellerUid'])
            .collection('booths')
            .doc(festivalName)
            .get();

        if (!ref.exists) {
          return;
        }

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref['boothName'] ?? '부스명 없음',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ref['location'] ?? '위치 정보 없음',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.68,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Color(0xFFD1D1D1), width: 1),
                        ),

                        // 사진
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            item['imagePath'] ?? '',
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/catcul_w.jpg',
                                width: double.infinity,
                                height: 250,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),


                      const SizedBox(height: 20),
                      Text(
                        item['itemName'] ?? '상품명 없음',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
                      const SizedBox(height: 8),
                      Text(
                          '작가: ${item['artist'] ?? '정보 없음'}',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          '상품 종류: ${item['itemType'] ?? '정보 없음'}',
                          style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 25),
                      Text(
                          '${item['sellingPrice'] ?? '가격 없음'}원',
                          style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
