import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*
String? result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                      return MyDropdownDialog();
                    } );
                    Use this to get the wanted pop up
*/

class MyDropdownDialog extends StatefulWidget {
  @override
  _MyDropdownDialogState createState() => _MyDropdownDialogState();
}

class _MyDropdownDialogState extends State<MyDropdownDialog> {
  String? selectedValue;
  List<String> festivals = [];

  @override
  void initState() {
    super.initState();
    _fetchFestivals();
  }

  Future<void> _fetchFestivals() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('Festivals').get();
      final festivalList = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        festivals = festivalList;
      });
    } catch (e) {
      print("부스 선택 팝업 에러 : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
  return Dialog(
      child: Container(
        width: 500,
        height: 400,
        child: AlertDialog(
          content: DropdownMenu<String>(
            width: 250,
            onSelected: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  selectedValue = newValue;
                });
              }
            },
            dropdownMenuEntries: festivals.map<DropdownMenuEntry<String>>(
                    (festival) => DropdownMenuEntry(
                  value: festival,
                  label: festival,
                )
            ).toList(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
              child: const Text('뒤로'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedValue);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      )
    );
  }
}
