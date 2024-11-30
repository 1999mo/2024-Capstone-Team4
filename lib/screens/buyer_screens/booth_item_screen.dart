import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoothItemScreen extends StatefulWidget {
  final String uid;
  final String? festivalName;
  final String itemName;

  const BoothItemScreen({
    Key? key,
    required this.uid,
    required this.festivalName,
    required this.itemName,
  }) : super(key: key);

  @override
  _BoothItemScreenState createState() => _BoothItemScreenState();
}

class _BoothItemScreenState extends State<BoothItemScreen> {
  int itemQuantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.uid) // Use widget.uid, widget.festivalName, etc.
            .collection('booths')
            .doc(widget.festivalName)
            .collection('items')
            .doc(widget.itemName)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading booth item.'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Item not found.'));
          }

          final itemData = snapshot.data!.data() as Map<String, dynamic>;
          final sellingPrice = itemData['sellingPrice'] ?? 'N/A';
          final stockQuantity = itemData['stockQuantity'] ?? 0;
          final imagePath = itemData['imagePath'] ?? '';
          final itemType = itemData['itemType'] ?? 'Unknown Type';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: imagePath.isNotEmpty
                      ? Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    height: 350.0,
                    width: double.infinity,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return Image.asset(
                        'assets/catcul_w.jpg',
                        fit: BoxFit.cover,
                        height: 350.0,
                        width: double.infinity,
                      );
                    },
                  )
                      : Image.asset(
                    'assets/catcul_w.jpg',
                    fit: BoxFit.cover,
                    height: 350.0,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '상품명: ${widget.itemName}',
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '상품 종류: $itemType',
                      style: const TextStyle(
                          fontSize: 16.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '판매가: $sellingPrice',
                      style: const TextStyle(
                          fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Display stock quantity here
                        Text(
                          '재고수: $stockQuantity',
                          style: const TextStyle(
                            fontSize: 16.0,
                            color: Colors.grey,
                      ),
                    ),/*Container(
                          padding: const EdgeInsets.all(8.0), // Padding around the entire row
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey), // Rectangle border around the row
                            borderRadius: BorderRadius.circular(8.0), // Optional rounded corners
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      itemQuantity++;
                                    });
                                    },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.black),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4.0),
                                  color: Colors.white,),
                                child: Text(
                                  '$itemQuantity',
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                              ),
                              Container(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (itemQuantity > 1) itemQuantity--;
                                    });
                                    },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(8),
                                    backgroundColor: Colors.white,
                                  ),
                                  child: const Icon(Icons.remove, color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        )*/
                      ],
                    ),
                  ])
              ),
              const Spacer(),
              /*Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final user = FirebaseAuth.instance.currentUser;

                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(user?.uid)
                            .collection('basket')
                            .doc(widget.festivalName)
                            .set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(user?.uid)
                            .collection('basket')
                            .doc(widget.festivalName)
                            .collection('booth')
                            .doc(widget.uid)
                            .set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));


                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(user?.uid)
                            .collection('basket')
                            .doc(widget.festivalName)
                            .collection('booth')
                            .doc(widget.uid)
                            .collection('items')
                            .add({
                          'itemName': widget.itemName,
                          'quantity': itemQuantity,
                        });

                      } catch (e) {
                        print('Error adding in basket: $e');
                      }
                    },
                    child: const Text('미리담기'),
                  ),
                ),
              ),*/
            ],
          );
        },
      ),
    );
  }
}
