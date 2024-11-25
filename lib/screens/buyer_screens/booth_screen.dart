import 'package:catculator/screens/buyer_screens/booth_items_list.dart';
import 'package:catculator/screens/main_screens/main_screen.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
                  (route) => false,
            );
          },
        ),
        centerTitle: true,
        title: const Text('부스 둘러보기', textAlign: TextAlign.center),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket),
            onPressed: () {
              // TODO: Implement basket functionality here
            },
          ),
        ],
      ),
      body: BoothItemsList(uid: uid, festivalName: festivalName),
    );
  }
}