import 'package:flutter/material.dart';

class PreboothListScreen extends StatefulWidget {
  const PreboothListScreen({super.key});

  @override
  State<PreboothListScreen> createState() => _PreboothListScreenState();
}

class _PreboothListScreenState extends State<PreboothListScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('사전구매'),);
  }
}
