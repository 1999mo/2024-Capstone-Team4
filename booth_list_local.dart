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
  String boothSearchQuery = '';
  String characterSearchQuery = '';
  String? festivalName;
  bool isLoadingCharacters = false;
  bool hasMoreCharacters = true;
  List<DocumentSnapshot> characterResults = [];
  DocumentSnapshot? lastCharacterDocument;
  final _boothSearchController=TextEditingController();
  final _characterSearchController=TextEditingController();
  int visibleCharacterCount=10;
  final _scrollController=ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // festivalName 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        festivalName = ModalRoute.of(context)?.settings.arguments as String?;
      });
    });
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
    if (!hasMoreCharacters || isLoadingCharacters || festivalName == null) return;

    setState(() {
      isLoadingCharacters = true;
    });

    try {
      final query = FirebaseFirestore.instance
          .collectionGroup('items')
          .where('itemName', isGreaterThanOrEqualTo: characterSearchQuery.toLowerCase())
          .where('itemName', isLessThan: '${characterSearchQuery.toLowerCase()}z')
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
                ).then((results) =>
                    results.whereType<Map<String, dynamic>>().toList()), // 수정된 부분
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
                    'sellerUid': sellerUid,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      painters,
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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
        // 검색 텍스트 필드
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _characterSearchController,
            onChanged: (value) {
              setState(() {
                characterSearchQuery = value.toLowerCase();
                characterResults.clear();
                lastCharacterDocument = null;
                hasMoreCharacters = true;
              });
              _fetchCharacterResults();
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
        // 그리드뷰 표시
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchItemsFromReferences(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if(snapshot.hasError) {
                return const Center(child: Text('오류 발생'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('상품이 없습니다.'));
              }

              final items = snapshot.data!;

              // 검색어 필터링
              final filteredItems = items.where((item) {
                final itemName = item['itemName']?.toString().toLowerCase() ?? '';
                return characterSearchQuery.isEmpty || itemName.contains(characterSearchQuery);
              }).toList();

              // "더 보기"를 위해 보여줄 개수 제한
              final displayedItems = filteredItems.take(visibleCharacterCount).toList();

              return Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: filteredItems.length > visibleCharacterCount
                          ? visibleCharacterCount + 1 // "더 보기" 버튼 포함
                          : filteredItems.length,
                      itemBuilder: (context, index) {
                        // "더 보기" 버튼
                        if (index == visibleCharacterCount && filteredItems.length > visibleCharacterCount) {
                          return Center(
                            child: ElevatedButton(
                              onPressed: () {
                                final currentScrollPosition = _scrollController.offset; // 현재 스크롤 위치 저장

                                setState(() {
                                  visibleCharacterCount += 10; // 추가로 10개 더 보기
                                });

                                // 스크롤 위치 유지
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(currentScrollPosition);
                                  }
                                });
                              },
                              child: const Text('더 보기'),
                            ),
                          );
                        }

                        // 일반 캐릭터 카드
                        final item = displayedItems[index];
                        return _buildCharacterCard(item);
                      },
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
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
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
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            return Dialog(
              insetPadding: const EdgeInsets.all(16.0), // 양옆 마진
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // X 버튼
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop(); // 다이어로그 닫기
                      },
                    ),
                  ),
                  // 부스명과 위치
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ref['boothName'] ?? '부스명 없음',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ref['location'] ?? '위치 정보 없음',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 사진
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          item['imagePath'] ?? '',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/catcul_w.jpg',
                              fit: BoxFit.contain,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 상품 종류
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '상품 종류: ${item['itemType'] ?? '정보 없음'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 상품명
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      item['itemName'] ?? '상품명 없음',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 작가명
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '작가명: ${item['artist'] ?? '정보 없음'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 판매가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      '판매가: ${item['sellingPrice'] ?? '가격 없음'}원',
                      style: const TextStyle(fontSize: 18, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}