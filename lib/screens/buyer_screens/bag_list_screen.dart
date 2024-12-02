import 'package:flutter/material.dart';

class BagListScreen extends StatefulWidget {
  const BagListScreen({super.key});

  @override
  State<BagListScreen> createState() => _BagListScreenState();
}

class _BagListScreenState extends State<BagListScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('장바구니'),);
  }
}
