import 'package:catculator/screens/buyer_screens/booth_item_screen.dart';
import 'package:catculator/screens/buyer_screens/preBooth_item_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreboothItemsList extends StatelessWidget {
  final String uid;
  final String? festivalName;

  const PreboothItemsList({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);


  Future<List<Map<String, dynamic>>> fetchItems() async {
    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(festivalName)
        .collection('items');

    final snapshot = await boothRef.get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String> fetchImage() async {
    final boothImage = await FirebaseStorage.instance
        .ref('$uid/profile_image.jpg')
        .getDownloadURL();

    return boothImage;
  }

  @override
  Widget build(BuildContext context) {
    final boothInfo = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(festivalName);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          boothInfo.get(),
          fetchImage(),
        ]),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading booth details.'));
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No booth details found.'));
          }

          if (!(snapshot.data![0] as DocumentSnapshot).exists) {
            return const Center(child: Text('No booth details found.'));
          }

          // Fetching data from the document
          final boothData = snapshot.data![0].data() as Map<String, dynamic>;
          final boothLocation = boothData['location'] ?? 'Unknown Location';
          final painters = List<String>.from(boothData['painters'] ?? []);
          final boothImage = snapshot.data![1];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 100.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    border: Border.all(color: Colors.grey), // Optional border
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Inner padding
                    child: Stack(
                      children: [
                        // Top Left: Static Text '부스명'
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: Text(
                            '부스명',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        // Top Right: Booth Location
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Text(
                            '부스 위치: $boothLocation',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        // Bottom Left: Painters (List of Painters)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Text(
                            '작가: ${painters.join(', ')}',
                            // Join the list of painters with commas
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: boothImage.isNotEmpty
                              ? Container(
                            width: 50.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(
                                  boothImage,
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                              : Container(
                            width: 50.0,
                            height: 50.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/catcul_w.jpg'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Booth Items List (Integrated directly here)
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchItems(),
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
                        crossAxisCount: 2, // Number of columns
                        crossAxisSpacing: 8.0, // Space between columns
                        mainAxisSpacing: 8.0, // Space between rows
                        childAspectRatio: 2 / 3, // Adjust the ratio as needed
                      ),
                      itemCount: items.length,
                      shrinkWrap: true, // Ensures that the gridview takes only as much space as it needs
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final imagePath = item['imagePath'] ?? ''; // Fetch image path
                        final itemName = item['itemName'] ?? 'Unknown Item';
                        final sellingPrice = item['sellingPrice'] ?? 'N/A';
                        final stockQuantity = item['stockQuantity'] ?? 'N/A';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PreboothItemScreen(
                                  uid: uid,
                                  festivalName: festivalName,
                                  itemName: itemName,
                                ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4.0,
                            margin: const EdgeInsets.all(8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  imagePath.isNotEmpty
                                      ? Image.network(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    height: 120.0, // Fixed height for the image
                                    width: double.infinity,
                                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                      return Image.asset(
                                        'assets/catcul_w.jpg',
                                        fit: BoxFit.cover,
                                        height: 120.0,
                                        width: double.infinity,
                                      );
                                    },
                                  )
                                      : Image.asset(
                                    'assets/catcul_w.jpg',
                                    fit: BoxFit.cover,
                                    height: 120.0,
                                    width: double.infinity,
                                  ),
                                  const SizedBox(height: 8.0), // Space between image and text

                                  // 상품명 (Item Name)
                                  Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis, // Ensure the text doesn't overflow
                                  ),
                                  const SizedBox(height: 8.0), // Space between item name and price

                                  // 가격 (Selling Price)
                                  Text(
                                    '가격: $sellingPrice',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8.0), // Space between price and stock quantity

                                  // 수량 (Stock Quantity)
                                  Text(
                                    '수량: $stockQuantity',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14.0,
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
                ),
              )
            ],
          );
        },
      ),
    );
  }
}