import 'package:catculator/screens/buyer_screens/bag_inside.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BagListScreen extends StatefulWidget {
  final String? festivalName;

  const BagListScreen({
    required this.festivalName,
    Key? key,
  }) : super(key: key);

  @override
  State<BagListScreen> createState() => _BagScreen();
}

class _BagScreen extends State<BagListScreen> {
  //List<Map<String, dynamic>> orderItems = [];
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchBoothData();
  }

  Future<List<Map<String, dynamic>>> fetchBoothData() async {
    try {
      List<String> boothName;
      List<Map<String, dynamic>> boothList = [];
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName).get();

      if(!doc.exists) {
        print("There is no doc");
        return [];
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      boothName = data.keys.toList();

      List<Map<String, dynamic>> boothData;
      for(String uid in boothName) {
        DocumentReference boothDocRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('booths')
            .doc(widget.festivalName);

        DocumentSnapshot boothSnapshot = await boothDocRef.get();
        if (boothSnapshot.exists) {
          Map<String, dynamic> booth = boothSnapshot.data() as Map<String, dynamic>;
          booth['uid'] = uid;

          boothList.add(booth);
        }
      }

      return boothList;
      /*
      // Fetch from userBasket of booths
      for (var doc in festivalSnapshot.docs) {

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
      */
    } catch (e) {
      print('Error fetching festival and booth data: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니 부스 목록'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchBoothData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(child: Text('No booths available.'));
            } else {
              List<Map<String, dynamic>> booth = snapshot.data!;

              return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                  ),
                  itemCount: booth.length,
                  itemBuilder: (context, index) {
                    //print(booth[index]['imagePath']);
                    return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BagInside(
                                uid: booth[index]['uid'],
                                festivalName: widget.festivalName,
                              ),
                            ),
                          );
                        },
                        child: Card(
                            elevation: 5.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                booth[index]['imagePath']?.isNotEmpty ?? false
                                      ? Container(
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(
                                    booth[index]['imagePath'],
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
                      Text(
                        booth[index]['boothName'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${booth[index]['location']}'),
                      Text('${booth[index]['painters'].join(', ')}'),
                            ])
                        )
                    );
                  }
              );
            }
            /*body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    itemCount: ,
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
                                booth.imagePath,
                                width: 50,
                                height: 50,
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
                  onPressed: () async{
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
      ),*/
          }
      ),
    );
  }
}