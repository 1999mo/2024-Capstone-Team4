import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class BagQrScreen extends StatefulWidget {
  final String uid;
  final String? festivalName;

  const BagQrScreen({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  BagQrScreenState createState() => BagQrScreenState();
}

class BagQrScreenState extends State<BagQrScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<String> getOrderCode() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName).get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey(widget.uid)) {
          Map<String, dynamic> insideData = data[widget.uid];

          if (!insideData.containsKey('code')) {
            Random random = Random();
            int timeStamp = DateTime.now().millisecondsSinceEpoch;
            int randomSuffix = random.nextInt(100000);

            String code = (timeStamp + randomSuffix).toString().substring(0, 12);

            DocumentReference<Map<String, dynamic>> itemDoc = await FirebaseFirestore.instance.collection('Users').doc(user?.uid).collection('basket').doc(widget.festivalName);

            await itemDoc.update({
              '${widget.uid}.code': code,
            }).catchError((error) {
              print("error setting code: $error");
            });

            return code;
          } else {
            return insideData['code'];
          }
        }
      }

      print("If you see this, check the bag_qr.dart, this should not happen");
      return '';
    } catch(e) {
      print("Error while get order code : $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Screen'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<String>(
        future: getOrderCode(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No code found'));
          } else {
            final code = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: QrImageView(
                    data: code,  // The QR code data
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  code,
                  style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  '해당 화면을 판매자에게 보여주세요',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);  // Navigating back
                      },
                      child: const Text('담은 목록 보기'),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}