import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId);

    final boothDoc = await boothRef.get();
    if (boothDoc.exists) {
      final data = boothDoc.data() as Map<String, dynamic>;
      setState(() {
        painters = ['작가 전체', ...List<String>.from(data['painters'] ?? [])];
      });
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || boothId == null) return;

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('booths')
          .doc(boothId)
          .collection('items')
          .doc(itemId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 삭제 중 오류가 발생했습니다: $e')),
      );
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 16),
                Text('상품명: ${itemData['itemName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('작가정보: ${itemData['artist'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('원가: ${itemData['costPrice'] ?? ''}'),
                Text('판매가: ${itemData['sellingPrice'] ?? ''}'),
                Text('재고수: ${itemData['stockQuantity'] ?? ''}'),
                Text('상품종류: ${itemData['itemType'] ?? ''}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('상품 삭제'),
                              content: const Text('정말 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context); // 팝업 닫기
                                  },
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _deleteItem(itemId);
                                    Navigator.pop(context); // 삭제 확인 팝업 닫기
                                    Navigator.pop(context); // 상세보기 팝업 닫기
                                  },
                                  child: const Text('삭제'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: const Text('삭제'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/seller_screens/edit_item', arguments: [boothId, itemId]);
                      },
                      child: const Text('수정'),
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
                  searchKeyword = value.trim(); // 검색어 상태 업데이트
                });
              },
              decoration: InputDecoration(
                labelText: '상품 검색',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
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
                  items: painters
                      .map((painter) =>
                      DropdownMenuItem(value: painter, child: Text(painter)))
                      .toList(),
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
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('등록된 상품이 없습니다.'));
                }
                final items = snapshot.data!.docs
                    .where((doc) {
                  final docData = doc.data() as Map<String, dynamic>;
                  final itemName = docData['itemName']?.toLowerCase() ?? '';
                  return (selectedPainter == '작가 전체' ||
                      (docData['artist'] ?? '') == selectedPainter) &&
                      itemName.contains(searchKeyword.toLowerCase());
                })
                    .toList();

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
                    final itemData =
                    items[index].data() as Map<String, dynamic>;
                    final itemId = items[index].id;

                    return GestureDetector(
                      onTap: () {
                        _showItemDetails(itemData, itemId);
                      },
                      child: Card(
                        elevation: 3,
                        child: Column(
                          children: [
                            Expanded(
                              child: Image.network(
                                itemData['imagePath'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image_not_supported);
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                itemData['itemName'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
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
          Navigator.pushNamed(context, '/seller_screens/add_item',
              arguments: boothId);
        },
        child: const Icon(Icons.add),
        tooltip: '상품 추가하기',
      ),
    );
  }
}
