import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class PreboothListScreen extends StatefulWidget {
  const PreboothListScreen({super.key});

  @override
  State<PreboothListScreen> createState() => _PreboothListScreenState();
}

class _PreboothListScreenState extends State<PreboothListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  String? festivalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<List<Map<String, dynamic>>> _fetchSellers() async {
    if (festivalName == null) return [];
    try {
      final docSnapshot = await FirebaseFirestore.instance.collection('Festivals').doc(festivalName).get();

      final sellers = (docSnapshot['sellers'] as List<dynamic>).cast<String>();
      final sellerData = await Future.wait(sellers.map((sellerUid) async {
        final boothDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerUid)
            .collection('booths')
            .doc(festivalName)
            .get();

        if (!boothDoc.exists) return null;

        final boothData = boothDoc.data()!;
        final imageUrl =
            await FirebaseStorage.instance.ref('$sellerUid/profile_image.jpg').getDownloadURL().catchError((_) => null);

        final isPreSell = boothData['isPreSell'] ?? false;
        final preSellStart = (boothData['preSellStart'] as Timestamp?)?.toDate();
        final preSellEnd = (boothData['preSellEnd'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        final isValidPreSellPeriod = isPreSell &&
            preSellStart != null &&
            preSellEnd != null &&
            now.isAfter(preSellStart) &&
            now.isBefore(preSellEnd);

        return {
          'sellerUid': sellerUid,
          'boothName': boothData['boothName'] ?? '이름 없음',
          'painters': (boothData['painters'] as List<dynamic>? ?? []).join(', '),
          'imageUrl': imageUrl,
          'isValidPreSellPeriod': isValidPreSellPeriod,
        };
      }).toList());

      return sellerData.where((seller) => seller != null).cast<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('Error fetching sellers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? '사전구매'),
      ),
      body: Column(
        children: [
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
                hintText: '부스명 또는 작가명을 검색하세요',
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
              future: _fetchSellers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('사전구매 가능한 부스가 없습니다.'));
                }
            
                final sellers = snapshot.data!;
                final filteredSellers = sellers.where((seller) {
                  final boothName = (seller['boothName'] ?? '').toLowerCase();
                  final painters = (seller['painters'] ?? '').toLowerCase();
                  return boothName.contains(searchQuery) || painters.contains(searchQuery);
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 한 줄에 2개씩 배치
                    crossAxisSpacing: 8, // 카드 간의 가로 간격
                    mainAxisSpacing: 8, // 카드 간의 세로 간격
                  ),
                  itemCount: filteredSellers.length,
                  itemBuilder: (context, index) {
                    final seller = filteredSellers[index];
                    final isClickable = seller['isValidPreSellPeriod'] as bool;
                    return GestureDetector(
                      onTap: isClickable
                          ? () {
                              Navigator.pushNamed(
                                context,
                                '/buyer_screens/preBooth_item_list',
                                arguments: {
                                  'sellerUid': seller['sellerUid'],
                                  'festivalName': festivalName,
                                },
                              );
                            }
                          : null,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Stack(alignment: Alignment.center, children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: seller['imageUrl'] ?? '',
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                seller['boothName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                seller['painters'] ?? '',
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          if (!isClickable)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: const Center(
                                child: Text(
                                  '사전구매 기간이 아닙니다.',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ]),
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
}
