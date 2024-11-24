import 'package:catculator/screens/buyer_screens/BoothItemsList.dart';
import 'package:flutter/material.dart';

class BoothScreen extends StatelessWidget {
  final String uid;
  final String festivalName;

  const BoothScreen({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('부스 둘러보기'),
      ),
      body: BoothItemsList(uid: uid, festivalName: festivalName),
    );
  }
}