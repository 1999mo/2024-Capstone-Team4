import 'dart:ffi';

import 'package:catculator/screens/buyer_screens/bag_qr.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Booth {
  final String name;
  final String imagePath;

  Booth ({required this.name, required this.imagePath});
}

class Festival {
  final String name;
  final List<Booth> booths;

  Festival({required this.name, required this.booths});
}

class BagScreen extends StatefulWidget {
  const BagScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<BagScreen> createState() => _BagScreen();
}

class _BagScreen extends State<BagScreen> {
  List<Map<String, dynamic>> orderItems = [];
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;
  String? currentFestival;
  List<Festival> festivalNames = [];

  @override
  void initState() {
    super.initState();
    fetchFestivalAndBoothData();
  }

  Future<void> fetchFestivalAndBoothData() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch festival names
      QuerySnapshot festivalSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user?.uid)
          .collection('basket')
          .get();

      // Process the festival names into Festival objects
      List<Festival> fetchedFestivals = [];

      for (var doc in festivalSnapshot.docs) {
        String festivalName = doc.id;

        // Fetch booths related to this festival
        QuerySnapshot boothSnapshot = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user?.uid)
            .collection('basket')  // This part will be inside the festival's basket collection
            .doc(festivalName)      // Add festivalName as the document reference
            .collection('booth')    // Access the 'booth' subcollection under this festival
            .get();

        List<Booth> booths = [];

        for (var boothDoc in boothSnapshot.docs) {
          String boothUid = boothDoc.id;

          DocumentSnapshot boothDetailSnapshot = await FirebaseFirestore.instance
              .collection('Users')
              .doc(boothUid)
              .collection('booths')
              .doc(festivalName)
              .get();

          String boothName = boothDetailSnapshot['boothName'] ?? 'Unknown';
          String imagePath;
          try {
            imagePath = boothDetailSnapshot['imagePath'] ?? '';
          } catch (e) {
            imagePath = '';
          }

          booths.add(Booth(name: boothName, imagePath: imagePath));
        }

        fetchedFestivals.add(Festival(name: festivalName, booths: booths));
      }

      setState(() {
        festivalNames = fetchedFestivals;
        currentFestival = festivalNames.isNotEmpty ? festivalNames.first.name : null;
        isLoading = false;
      });

      currentFestival = festivalNames.first.name;
    } catch (e) {
      print('Error fetching festival and booth data: $e');
      isLoading = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    int totalPrice = orderItems.fold<int>(0, (sum, item) {
      return sum +
          (int.tryParse(item['price'].toString()) ?? 0) *
              (int.tryParse(item['itemQuantitySelected'].toString()) ?? 0);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니 목록'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: currentFestival,
                    onChanged: (String? newValue) {
                      setState(() {
                        currentFestival = newValue;
                      });
                    },
                    items: festivalNames.map((festival) {
                      return DropdownMenuItem<String>(
                        value: festival.name, // Use festival name as the value
                        child: Text(festival.name), // Display the festival name
                      );
                    }).toList(),
                    hint: const Text("Select Festival"),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: festivalNames
                        .firstWhere(
                          (festival) => festival.name == currentFestival,
                      orElse: () => Festival(name: '', booths: []), // Fallback in case no matching festival is found
                    )
                        .booths
                        .length,
                    itemBuilder: (context, index) {
                      var booth = festivalNames
                          .firstWhere(
                            (festival) => festival.name == currentFestival,
                        orElse: () => Festival(name: '', booths: []), // Fallback
                      )
                          .booths[index];

                      return GestureDetector(
                        onTap: () {
                          //go to bag_inside
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey), // Default border color
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Image.network(
                                booth.imagePath, // Display booth image
                                width: 50, // Adjust size as needed
                                height: 50, // Adjust size as needed
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                booth.name, // Display booth name
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    //await fetchOrderItems(); // Refresh data
                  },
                  child: const Text('데이터 새로고침'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BagQrScreen(),
                      ),
                    );
                  },
                  child: const Text('결제하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}