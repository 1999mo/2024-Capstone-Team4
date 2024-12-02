import 'package:catculator/screens/buyer_screens/booth_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BoothListScreen extends StatefulWidget {
  final String painter;
  final String? festivalName;

  const BoothListScreen({Key? key, required this.painter, required this.festivalName}) : super(key: key);

  @override
  _BoothListScreen createState() => _BoothListScreen();
}

class _BoothListScreen extends State<BoothListScreen> {

  Future<List<Map<String, dynamic>>> _getAllBooths(String painter) async {
    try {
      //var festivalsSnapshot = await FirebaseFirestore.instance.collection('Festivals').get();

      DocumentSnapshot festivalDoc = await FirebaseFirestore.instance
          .collection('Festivals')
          .doc(widget.festivalName)
          .get();
      List<Map<String, dynamic>> festivalBoothList = [];

      //for (var festivalDoc in festivalsSnapshot.docs) {
        //String festivalName = festivalDoc.id; Festival name is the document ID

      List<String> sellerUids = List.from(festivalDoc['sellers']); // List of seller UIDs

        for (var userId in sellerUids) {
          var boothRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(userId)
              .collection('booths')
              .doc(widget.festivalName);

          // Fetch the booth items for this user and festival
          var boothSnapshot = await boothRef.get();

          if (boothSnapshot.exists) {
            List<String> painters = List<String>.from(boothSnapshot['painters'] ?? []);

            bool matchesPainter = painters.any((painterName) =>
            painterName.toLowerCase().contains(painter.toLowerCase()) || painter.isEmpty);

            String imagePath = await FirebaseStorage.instance
                .ref('$userId/profile_image.jpg')
                .getDownloadURL();

            if(matchesPainter) {
              festivalBoothList.add({
                'userId': userId,
                'boothName': boothSnapshot['boothName'],
                'location': boothSnapshot['location'],
                'painters': List<String>.from(boothSnapshot['painters'] ?? []),
                'imagePath': imagePath,
              });
            }
          }
        }
      //}

      return _getItemMatchBooths(painter, festivalBoothList);
    } catch (e) {
      print('Error fetching booth list: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getItemMatchBooths(String painter, List<Map<String, dynamic>> festivalBoothList) async {
    try {
      DocumentSnapshot festivalDoc = await FirebaseFirestore.instance
          .collection('Festivals')
          .doc(widget.festivalName)
          .get();

      List<String> sellerUids = List.from(festivalDoc['sellers']);

      for (var userId in sellerUids) {
        var boothRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .collection('booths')
            .doc(widget.festivalName);

        // Fetch the booth items for this user and festival
        var boothSnapshot = await boothRef.get();

        if (boothSnapshot.exists) {
          //List<String> painters = List<String>.from(boothSnapshot['painters'] ?? []);

          //bool matchesPainter = painters.any((painterName) =>
          //painterName.toLowerCase().contains(painter.toLowerCase()) || painter.isEmpty);
          final collection = FirebaseFirestore.instance.collection('Users/$userId/booths/');
          final querySnapshot = await collection.get();
          List<String> itemNames = querySnapshot.docs.map((doc) => doc.id).toList();

          bool matchesName = itemNames.any((itemName) =>
          itemName.toLowerCase().contains(itemName.toLowerCase()) || painter.isEmpty);


          String imagePath = await FirebaseStorage.instance
              .ref('$userId/profile_image.jpg')
              .getDownloadURL();

          if(matchesName && (!festivalBoothList.any((item) => item['userId'] == userId))) {
            festivalBoothList.add({
              'userId': userId,
              'boothName': boothSnapshot['boothName'],
              'location': boothSnapshot['location'],
              'painters': List<String>.from(boothSnapshot['painters'] ?? []),
              'imagePath': imagePath,
            });
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
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

              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
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
                              festivalName: widget.festivalName,
                          ),
                        )
                      );
                    },
                    child: SizedBox(
                      height: 100.0,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Color(0xFFD1D1D1), width: 1),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              booth['imagePath'].isNotEmpty
                              ? Container(
                                width: 100.0,
                                height: 100.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: NetworkImage(
                                    booth['imagePath'],
                                  ),
                                  fit: BoxFit.cover,
                                  ),
                                ),
                              )
                              : Container(
                                width: 100.0,
                                height: 100.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage('assets/catcul_w.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                booth['boothName'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,),
                              ),
                              const SizedBox(height: 4),
                              Text('${booth['location']}'),
                              Text('${booth['painters'].join(', ')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
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
      ),
    );
  }
}
