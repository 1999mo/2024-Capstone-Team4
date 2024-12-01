import 'package:catculator/screens/buyer_screens/bag_qr.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FutureResults {
  final List<Map<String, dynamic>> bagList;
  final bool paymentStatus;

  FutureResults({required this.bagList, required this.paymentStatus});
}

class BagInside extends StatefulWidget {
  final String uid;
  final String? festivalName;

  const BagInside({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  BagInsideState createState() => BagInsideState();
}

class BagInsideState extends State<BagInside> {
  final user = FirebaseAuth.instance.currentUser;

  Future<List<Map<String, dynamic>>> fetchBagList() async {
    try {
      List<Map<String, dynamic>> bagList = [];
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName).get();

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      var itemList = data[widget.uid];

      for (var entry in itemList.entries) {
        String key = entry.key;
        dynamic value = entry.value;

        if (key == 'payment' || key == 'code') {
          continue;
        }

        DocumentSnapshot itemDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.uid)
            .collection('booths')
            .doc(widget.festivalName)
            .collection('items')
            .doc(key)
            .get();

        int itemPrice = itemDoc['sellingPrice'];

        Map<String, dynamic> list = {
          'itemName': key,
          'itemQuantity': value,
          'itemPrice': itemPrice,
        };
        bagList.add(list);
      }
      return bagList;
    } catch(e) {
      return [];
    }
  }

  void setItem(String itemName, int quantity) async {
    try {
      DocumentReference<Map<String, dynamic>> doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName);

      await doc.update({
        '${widget.uid}.$itemName': quantity,
      }).catchError((error) {
        print("error updating item: $error");
      });

    } catch(e) {
      print("Error while trying to setItem : $e");
      return;
    }
  }

  void paymentSet() async {
    try {
      DocumentReference<Map<String, dynamic>> doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName);

      await doc.update({
        '${widget.uid}.payment': true,
      }).catchError((error) {
        print("error updating payment: $error");
      });
    } catch(e) {
      print("Error while trying to payment : $e");
      return;
    }
  }

  Future<bool> paymentGet() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName).get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey(widget.uid)) {
          var payment = data[widget.uid]['payment'];
          if (payment != null) {
            return payment;
          } else {
            print('Payment field does not exist. Check code');
            return false;
          }
        }
      } else {
        print('No such booth');
        return false;
      }

      print("This should not be printed, check the bag_inside.dart");
      return false;
    } catch(e) {
      print("Error while trying to get payment check: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 목록'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<FutureResults>(
        future: Future.wait([
          fetchBagList(),
          paymentGet(),
        ]).then((results) {
          return FutureResults(
            bagList: results[0] as List<Map<String, dynamic>>,
            paymentStatus: results[1] as bool,
          );
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No items found'));
          } else {
            FutureResults results = snapshot.data!;
            List<Map<String, dynamic>> orderItems = results.bagList;
            bool paymentStatus = results.paymentStatus;

            int totalPrice = orderItems.fold<int>(0, (total, item) {
              return (total + (item['itemPrice'] * item['itemQuantity']) as int);
            });

            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                //color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      Column(
                        children: orderItems.map((item) {
                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['itemName']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                    '${item['itemPrice'] * item['itemQuantity']} 원',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      )
                                  ),
                                  Row(
                                    children: [
                                      AbsorbPointer(
                                      absorbing: paymentStatus,
                                      child: Opacity(
                                        opacity: !paymentStatus ? 1.0 : 0.0,
                                        child: IconButton(
                                          onPressed: () {
                                            if (item['itemQuantity'] > 0) {
                                              setState(() {
                                                setItem(item['itemName'], item['itemQuantity'] - 1);
                                              });
                                            }
                                            },
                                          icon: const Icon(Icons.remove),
                                        ),
                                      )),
                                      Text(
                                        '${item['itemQuantity']}',
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                      AbsorbPointer(
                                          absorbing: paymentStatus,
                                          child: Opacity(
                                            opacity: !paymentStatus ? 1.0 : 0.0,
                                            child: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  setItem(item['itemName'], item['itemQuantity'] + 1);
                                                });
                                                },
                                              icon: const Icon(Icons.add),
                                            ),
                                          )
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '총 가격 : $totalPrice 원',
                            style: const TextStyle(
                              fontSize: 30.0,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                            Navigator.pop(context);
                            },
                              child: Text('뒤로가기'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                //Need logic to make this check to payed, just making payed for now
                                setState(() {
                                  paymentSet();
                                });
                                },
                              child: Text('결제하기'),
                            ),
                          ]
                      ),
                    ],
                  ),
                  paymentStatus ? Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10.0,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BagQrScreen(
                              uid: widget.uid,
                              festivalName: widget.festivalName,
                            ),
                          ),
                        );
                      },
                      child: Text('QR 코드 보기'),
                    ),
                  ) : SizedBox.shrink(),
                ]
              )
            );
          }
          },
      ),
    );
  }
}
