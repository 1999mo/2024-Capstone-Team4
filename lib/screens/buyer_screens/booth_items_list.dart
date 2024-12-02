import 'package:catculator/screens/buyer_screens/booth_item_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BoothItemsList extends StatefulWidget {
  const BoothItemsList({Key? key}) : super(key: key);

  @override
  _BoothItemsListState createState() => _BoothItemsListState();
}

class _BoothItemsListState extends State<BoothItemsList> {
  late final String uid;
  late final String? festivalName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    uid = arguments?['uid'] ?? '';
    festivalName = arguments?['festivalName'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: BoothAppBar(uid: uid, festivalName: festivalName),
      ),
      body: BoothItemsListBody(uid: uid, festivalName: festivalName),
    );
  }
}

class BoothAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String uid;
  final String? festivalName;

  const BoothAppBar({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  _BoothAppBarState createState() => _BoothAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BoothAppBarState extends State<BoothAppBar> {
  late Future<Map<String, dynamic>> boothDetails;

  Future<Map<String, dynamic>> fetchBoothDetails() async {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.uid)
        .collection('booths')
        .doc(widget.festivalName)
        .get();

    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'boothName': data['boothName'] ?? 'Unknown Booth',
      'painters': List<String>.from(data['painters'] ?? []),
      'location': data['location'] ?? 'Unknown Location',
      'profileImage':
          await FirebaseStorage.instance.ref('${widget.uid}/profile_image.jpg').getDownloadURL().catchError((_) => ''),
    };
  }

  @override
  void initState() {
    super.initState();
    boothDetails = fetchBoothDetails();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: boothDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error loading booth details.'));
        }

        final boothName = snapshot.data!['boothName'];
        final location = snapshot.data!['location'];
        final profileImage = snapshot.data!['profileImage'];

        return AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                boothName,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: profileImage.isNotEmpty
                    ? NetworkImage(profileImage)
                    : const AssetImage('assets/catcul_w.jpg') as ImageProvider,
                onBackgroundImageError: (_, __) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '부스위치',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class BoothItemsListBody extends StatefulWidget {
  final String uid;
  final String? festivalName;

  const BoothItemsListBody({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  _BoothItemsListBodyState createState() => _BoothItemsListBodyState();
}

class _BoothItemsListBodyState extends State<BoothItemsListBody> {
  late Future<List<Map<String, dynamic>>> items;
  final Map<String, bool> isExpectedMap = {};
  final Map<String, int> expectCountMap = {};

  Future<List<Map<String, dynamic>>> fetchItems() async {
    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.uid)
        .collection('booths')
        .doc(widget.festivalName)
        .collection('items');

    final snapshot = await boothRef.get();
    return snapshot.docs
        .map((doc) => {
              ...doc.data(),
              'itemId': doc.id,
            })
        .toList();
  }

  String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  Future<bool> checkIfExpected(String itemId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.uid)
        .collection('booths')
        .doc(widget.festivalName)
        .collection('items')
        .doc(itemId);

    final docSnapshot = await docRef.get();
    final clicks = docSnapshot.data()?['clicks'] as List<dynamic>?;

    return clicks != null && clicks.contains(userId);
  }

  @override
  void initState() {
    super.initState();
    items = fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading items.'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No items found.'));
        }

        final items = snapshot.data!;

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: 0.6,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final itemId = item['itemId'];
            final imagePath = item['imagePath'] ?? '';
            final itemName = item['itemName'] ?? 'Unknown Item';
            final sellingPrice = item['sellingPrice'] ?? 0;
            final stockQuantity = item['stockQuantity'] ?? 0;
            int expectCount = item['expect'] ?? -1;
            final userId = FirebaseAuth.instance.currentUser!.uid;

            return FutureBuilder<bool>(
              future: checkIfExpected(itemId, userId),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final isExpected = asyncSnapshot.data ?? false;
                isExpectedMap[itemId] = isExpected;
                int count = expectCount;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoothItemScreen(
                          uid: widget.uid,
                          festivalName: widget.festivalName,
                          itemName: itemName,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imagePath,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/catcul_w.jpg',
                                fit: BoxFit.cover,
                                // height: 120.0,
                                width: double.infinity,
                              );
                            },
                          ),
                        ),
                        ),

                        const SizedBox(height: 6.0),
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          '가격: ${formatNumber(sellingPrice)}원',
                          style: const TextStyle(color: Colors.grey, fontSize: 14.0),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          stockQuantity > 0 ? '수량: ${formatNumber(stockQuantity)}' : '품절',
                          style: TextStyle(
                            color: stockQuantity > 0 ? Colors.grey : Colors.red,
                            fontSize: 14.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        if (expectCount != -1)
                          Column(
                            children: [
                              Text(
                                '구매 희망자 수 : $count',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isExpected ? Colors.red[200] : Colors.green[200],
                                ),
                                onPressed: isExpected
                                    ? null
                                    : () async {
                                        setState(() {
                                          isExpectedMap[itemId] = true;
                                          count++;
                                        });
                                        final docRef = FirebaseFirestore.instance
                                            .collection('Users')
                                            .doc(widget.uid)
                                            .collection('booths')
                                            .doc(widget.festivalName)
                                            .collection('items')
                                            .doc(itemId);

                                        await docRef.update({
                                          'clicks': FieldValue.arrayUnion([userId]),
                                          'expect': FieldValue.increment(1),
                                        });
                                      },
                                child: Text(isExpected ? '신청 완료' : '구매 희망하기'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
