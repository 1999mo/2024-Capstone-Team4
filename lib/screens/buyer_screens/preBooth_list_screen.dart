import 'package:catculator/screens/buyer_screens/booth_screen.dart';
import 'package:catculator/screens/buyer_screens/preBooth_screen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PreboothListScreen extends StatefulWidget {
  final String painter;
  final String? festivalName;

  const PreboothListScreen({Key? key, required this.painter, required this.festivalName}) : super(key: key);

  @override
  _PreboothListScreen createState() => _PreboothListScreen();
}

class _PreboothListScreen extends State<PreboothListScreen> {

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
                'isPreSell': boothSnapshot['isPreSell'],
                'preSellEnd': boothSnapshot['preSellEnd'],
                'preSellStart': boothSnapshot['preSellStart'],
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
              'isPreSell': boothSnapshot['isPreSell'],
              'preSellEnd': boothSnapshot['preSellEnd'],
              'preSellStart': boothSnapshot['preSellStart'],
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
        title: const Text('사전구매 부스 목록'),
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

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 225,
              ),
              itemCount: boothList.length,
              itemBuilder: (context, index) {
                var booth = boothList[index];
                bool isBoothOpen = booth['isPreSell'];
                bool isBoothTime = false;

                DateTime startTime;
                DateTime endTime;
                String boothTime = '';

                if (isBoothOpen) {
                  startTime = booth['preSellStart'].toDate();
                  endTime = booth['preSellEnd'].toDate();
                  String d1 = DateFormat('yyyy.MM.dd').format(startTime);
                  String d2 = DateFormat('MM.dd').format(endTime);
                  boothTime = '$d1-$d2';

                  DateTime currentDate = DateTime.now();
                  if(currentDate.isAfter(startTime) && currentDate.isBefore(endTime)) {
                    isBoothTime = true;
                  }
                }

                return GestureDetector(
                  onTap: () {
                    if (isBoothTime) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreboothScreen(
                            uid: booth['userId'],
                            festivalName: widget.festivalName,
                          ),
                        ),
                      );
                    }
                  },
                  child: SizedBox(
                    height: 256.0,
                    width: 256.0,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          child: Card(
                            color: isBoothTime ? Colors.white : Colors.grey,  // Set grey color if booth is closed
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
                                        image: NetworkImage(booth['imagePath']),
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
                                  SizedBox(height: 8),
                                  Text(
                                    booth['boothName'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('${booth['location']}'),
                                  Text('${booth['painters'].join(', ')}'),
                                  if (isBoothOpen)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(boothTime),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (!isBoothTime)  // Display "판매 종료" on top of the card when booth is closed
                          Positioned(
                            top: 90.0,
                            left: 8.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                              color: Colors.red,
                              child: Text(
                                '사전 구매 기간이 아닙니다',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
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