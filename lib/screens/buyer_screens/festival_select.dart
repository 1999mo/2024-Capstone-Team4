import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _validateAndClose() {
    if (selectedValue == null || selectedValue == "축제를 선택하세요") {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('경고'),
          content: const Text('축제를 선택하세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop(selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 400,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 텍스트와 드롭다운 버튼을 정중앙에 배치
          crossAxisAlignment: CrossAxisAlignment.center, // 가로축도 중앙 정렬
          children: [
            const Text(
              '축제를 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedValue ?? "축제를 선택하세요",
              items: [
                const DropdownMenuItem(
                  value: "축제를 선택하세요",
                  child: Text("축제를 선택하세요"),
                ),
                ...festivals.map((festival) {
                  return DropdownMenuItem(
                    value: festival,
                    child: Text(festival),
                  );
                }).toList(),
              ],
              onChanged: (newValue) {
                setState(() {
                  selectedValue = newValue;
                });
              },
            ),
            const SizedBox(height: 200),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D1D1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop('');
                      },
                      child: const Text(
                          '뒤로',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8,),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBE85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: _validateAndClose,
                      child: const Text(
                        '확인',
                        style: TextStyle(color: Colors.black),),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
