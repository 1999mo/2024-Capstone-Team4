import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreboothItemsList extends StatefulWidget {
  const PreboothItemsList({super.key});

  @override
  State<PreboothItemsList> createState() => _PreboothItemsListState();
}

class _PreboothItemsListState extends State<PreboothItemsList> {
  late String sellerUid;
  late String festivalName;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    sellerUid = arguments['sellerUid']!;
    festivalName = arguments['festivalName']!;
  }

  Future<List<Map<String, dynamic>>> _fetchItems() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(sellerUid)
          .collection('booths')
          .doc(festivalName)
          .collection('items')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$festivalName - Items'),
      ),
      body: Column(
        children: [
          // 검색 입력 필드
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: '상품명을 검색하세요',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('등록된 상품이 없습니다.'));
                }

                final items = snapshot.data!;
                final filteredItems = items.where((item) {
                  final itemName = (item['itemName'] ?? '').toLowerCase();
                  return searchQuery.isEmpty || itemName.contains(searchQuery);
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 한 줄에 2개씩 배치
                    crossAxisSpacing: 8, // 카드 간의 가로 간격
                    mainAxisSpacing: 8, // 카드 간의 세로 간격
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return GestureDetector(
                      onTap: () => _showItemDialog(context, item),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                                child: Image.network(
                                  item['imagePath'] ?? '',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset('assets/catcul_w.jpg', fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    item['itemName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item['sellingPrice'] ?? 0}원',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  void _showItemDialog(BuildContext context, Map<String, dynamic> item) {
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.0),
                            child: Image.network(
                              item['imagePath'] ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/catcul_w.jpg', fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 상품명
                          Text(
                            item['itemName'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // 상품 타입
                          Text(
                            '상품 타입: ${item['itemType'] ?? '정보 없음'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // 작가
                          Text(
                            '작가: ${item['artist'] ?? '정보 없음'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // 판매가
                          Text(
                            '판매가: ${item['sellingPrice'] ?? 0}원',
                            style: const TextStyle(fontSize: 16, color: Colors.green),
                          ),
                          const SizedBox(height: 16),
                          // 수량 조절 버튼
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: quantity > 1
                                    ? () {
                                        setState(() {
                                          quantity--;
                                        });
                                      }
                                    : null,
                              ),
                              Text('$quantity', style: const TextStyle(fontSize: 18)),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // 장바구니 담기 버튼
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                // 현재 접속 중인 계정의 uid 가져오기
                                final uid = FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('로그인이 필요합니다.')),
                                  );
                                  return;
                                }

                                // Firebase Firestore reference 생성
                                final basketRef = FirebaseFirestore.instance
                                    .collection('Users')
                                    .doc(uid)
                                    .collection('basket')
                                    .doc(festivalName);

                                final documentSnapshot = await basketRef.get();

                                // 현재 sellerUid에 해당하는 배열 가져오기
                                Map<String, dynamic> basketData =
                                    documentSnapshot.exists ? documentSnapshot.data() as Map<String, dynamic> : {};

                                List<dynamic> sellerItems = basketData[sellerUid] ?? [];

                                // 현재 문서 속성을 map으로 추가
                                final itemData = {
                                  'itemName': item['itemName'],
                                  'itemType': item['itemType'],
                                  'artist': item['artist'],
                                  'sellingPrice': item['sellingPrice'],
                                  'quantity': quantity,
                                  'imagePath': item['imagePath'] ?? ''
                                };

                                sellerItems.add(itemData);

                                // Firebase에 업데이트
                                basketData[sellerUid] = sellerItems;
                                await basketRef.set(basketData);

                                // 장바구니 추가 완료 스낵바 표시
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('장바구니에 추가되었습니다.'), duration: Duration(seconds: 1)),
                                );

                                // 다이얼로그 닫기
                                Navigator.of(context).pop();
                              } catch (e) {
                                // 오류 발생 시 스낵바로 알림
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                                );
                              }
                            },
                            child: const Text('장바구니 담기'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
