import 'package:catculator/screens/buyer_screens/booth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoothListScreen extends StatefulWidget {
  final String painter;

  const BoothListScreen({Key? key, required this.painter}) : super(key: key);

  @override
  _BoothListScreen createState() => _BoothListScreen();
}

class _BoothListScreen extends State<BoothListScreen> {

  Future<List<Map<String, dynamic>>> _getAllBooths(String painter) async {
    try {
      //print(painter + " : painter");
      // Get all festivals from the 'Festivals' collection
      var festivalsSnapshot = await FirebaseFirestore.instance.collection('Festivals').get();

      // Prepare a list to hold the festival data
      List<Map<String, dynamic>> festivalBoothList = [];

      // Iterate over each festival
      for (var festivalDoc in festivalsSnapshot.docs) {
        String festivalName = festivalDoc.id; // Festival name is the document ID
        List<String> sellerUids = List.from(festivalDoc['sellers']); // List of seller UIDs

        // For each seller UID, fetch their booths for this festival
        for (var userId in sellerUids) {
          var boothRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('booths')
              .doc(festivalName);

          // Fetch the booth items for this user and festival
          var boothSnapshot = await boothRef.get();

          if (boothSnapshot.exists) {
            List<String> painters = List<String>.from(boothSnapshot['painters'] ?? []);

            bool matchesPainter = painters.any((painterName) =>
            painterName.toLowerCase().contains(painter.toLowerCase()) || painter.isEmpty);

            if(matchesPainter) {
              festivalBoothList.add({
                'festival': festivalName,
                'userId': userId,
                'boothName': boothSnapshot['boothName'],
                'location': boothSnapshot['location'],
                'painters': List<String>.from(boothSnapshot['painters'] ?? []),
              });
            }
          }
        }
      }
      return festivalBoothList;
    } catch (e) {
      print('Error fetching booth list: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부스 목록'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllBooths(widget.painter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No booths available.'));
          } else {
            var boothList = snapshot.data!;

            return ListView.builder(
              itemCount: boothList.length,
              itemBuilder: (context, index) {
                var booth = boothList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoothScreen(
                            uid: booth['userId'],
                            festivalName: booth['festival'],
                        ),
                      )
                    );
                  },
                  child: SizedBox(
                    height: 100.0,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booth['boothName'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('부스위치: ${booth['location']}'),
                            Text('작가: ${booth['painters'].join(', ')}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          },
      ),
    );
  }
}
