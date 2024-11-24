import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoothItemsList extends StatelessWidget {
  final String uid;
  final String festivalName;

  const BoothItemsList({
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
            childAspectRatio: 3 / 2, // Adjust the height and width ratio of the grid items
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 4.0,
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['itemName'] ?? 'Unknown Item',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis, // Ensure the text doesn't overflow
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Price: ${item['sellingPrice'] ?? 'N/A'}',
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
}
