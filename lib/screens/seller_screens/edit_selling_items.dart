import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditSellingItems extends StatefulWidget {
  const EditSellingItems({super.key});

  @override
  State<EditSellingItems> createState() => _EditSellingItemsState();
}

class _EditSellingItemsState extends State<EditSellingItems> {
  String? boothId;
  List<String> painters = [];
  String selectedPainter = '작가 전체';
  String searchKeyword = ''; // 검색어 상태 추가

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId = ModalRoute.of(context)?.settings.arguments as String?;
    boothId ??= 'Unknown';
    _initializePainters();
  }

  Future<void> _initializePainters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;

    final boothRef = FirebaseFirestore.instance.collection('Users').doc(uid).collection('booths').doc(boothId);

    final boothDoc = await boothRef.get();
    if (boothDoc.exists) {
      final data = boothDoc.data() as Map<String, dynamic>;
      setState(() {
        painters = ['작가 전체', ...List<String>.from(data['painters'] ?? [])];
      });
    }
  }

  Future<void> _deleteItem(String itemId, String? imagePath) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || boothId == null) return;

      // Firestore에서 문서 삭제
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('booths')
          .doc(boothId)
          .collection('items')
          .doc(itemId)
          .delete();

      // Firebase Storage에서 이미지 삭제
      if (imagePath != null && imagePath.isNotEmpty) {
        final ref = FirebaseStorage.instance.refFromURL(imagePath);
        await ref.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  void _showDeleteConfirmation(String itemId, String? imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('상품 삭제'),
          content: const Text('정말 이 상품을 삭제하시겠습니까? 삭제하면 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/seller_screens/edit_selling_items'),
                );
                _deleteItem(itemId, imagePath); // 실제 삭제 함수 호출
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDetails(Map<String, dynamic> itemData, String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, // 텍스트의 기본 정렬을 왼쪽으로 설정
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    itemData['imagePath'] ?? '',
                    fit: BoxFit.cover,
                    height: 150,
                    width: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                  ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '상품명: ${itemData['itemName'] ?? ''}',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '작가정보: ${itemData['artist'] ?? ''}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('재고수: ${itemData['stockQuantity'] ?? ''}', style: const TextStyle(fontSize: 14)),
                              Text('상품종류: ${itemData['itemType'] ?? ''}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('원가: ${itemData['costPrice'] ?? ''}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          Text('판매가: ${itemData['sellingPrice'] ?? ''}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF5353))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

            Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () {
                            _showDeleteConfirmation(itemId, itemData['imagePath']);
                          },
                          child: const Text('삭제', style: TextStyle(fontSize: 14, color: Colors.black)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDBE85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/seller_screens/edit_item', arguments: [boothId, itemId]);
                          },
                          child: const Text('수정', style: TextStyle(fontSize: 14, color: Colors.black)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 관리'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색 필드 추가
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchKeyword = value.trim();
                });
              },
              decoration: InputDecoration(
                labelText: '상품 검색',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          // 드롭다운 버튼
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text(
                  '작가 선택: ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: selectedPainter,
                  onChanged: (value) {
                    setState(() {
                      selectedPainter = value!;
                    });
                  },
                  items: painters.map((painter) => DropdownMenuItem(value: painter, child: Text(painter))).toList(),
                ),
              ],
            ),
          ),
          // 상품 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('booths')
                  .doc(boothId)
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  //처음에는 로딩화면을 띄우는 것으로 했으나 없는 것이 UX적으로 좋아보임
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('등록된 상품이 없습니다.'));
                }

                final items = snapshot.data!.docs.where((doc) {
                  final docData = doc.data() as Map<String, dynamic>;
                  final itemName = docData['itemName']?.toLowerCase() ?? '';
                  return (selectedPainter == '작가 전체' || (docData['artist'] ?? '') == selectedPainter) &&
                      itemName.contains(searchKeyword.toLowerCase());
                }).toList();

                if (items.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final itemData = items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;

                    return GestureDetector(
                      onTap: () {
                        _showItemDetails(itemData, itemId);
                      },
                      child: Card(
                        //elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey, width: 1),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: itemData['imagePath']?.isNotEmpty == true
                                    ? Image.network(
                                  itemData['imagePath'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/catcul_w.jpg',
                                      fit: BoxFit.cover,
                                    );
                                  },
                                )
                                    : Image.asset(
                                  'assets/catcul_w.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                itemData['itemName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/seller_screens/add_item', arguments: boothId);
        },
        child: const Icon(Icons.add),
        tooltip: '상품 추가하기',
      ),
    );
  }
}
