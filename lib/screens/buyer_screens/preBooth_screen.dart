import 'package:catculator/screens/buyer_screens/booth_items_list.dart';
import 'package:catculator/screens/buyer_screens/preBooth_items_list.dart';
import 'package:catculator/screens/main_screens/main_screen.dart';
import 'package:flutter/material.dart';

class PreboothScreen extends StatelessWidget {
  final String uid;
  final String? festivalName;

  const PreboothScreen({
    Key? key,
    required this.uid,
    required this.festivalName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
                  (route) => false,
            );
          },
        ),*/
        centerTitle: true,
        title: const Text('사전구매 부스 둘러보기', textAlign: TextAlign.center),
        toolbarHeight: 56.0,
      ),
      extendBodyBehindAppBar: true,
      body: PreboothItemsList(uid: uid, festivalName: festivalName),
    );
  }
}