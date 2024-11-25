import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  State<AddItem> createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? boothId;
  String itemName = '';
  String selectedPainter = '판매 작가명';
  String itemType = '';
  int? costPrice;
  int? sellingPrice;
  int? stockQuantity;
  File? imageFile;

  List<String> painters = ['판매 작가명'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId = ModalRoute.of(context)?.settings.arguments as String?;
    if (boothId != null) {
      _loadPainters();
    }
  }

  Future<void> _loadPainters() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;

    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId);

    final boothDoc = await boothRef.get();
    if (boothDoc.exists) {
      final data = boothDoc.data() as Map<String, dynamic>;
      setState(() {
        painters = [
          '판매 작가명',
          ...List<String>.from(data['painters'] ?? []),
        ];
      });
    }
  }

  Future<String> _uploadImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // 사용자가 이미지를 선택하지 않았다면 빈 문자열 반환
      if (imageFile == null) {
        return '';
      }

      // 선택된 이미지 업로드
      final ref = FirebaseStorage.instance
          .ref()
          .child('$uid/${itemName.replaceAll(' ', '_')}.jpg');
      final uploadTask = ref.putFile(imageFile!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // 업로드 실패 시 빈 문자열 반환
      return '';
    }
  }


  Future<void> _addItem() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상품이 성공적으로 추가되었습니다.')),
    );
    final itemsRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId)
        .collection('items');

    final existingDoc = await itemsRef.doc(itemName).get();
    if (existingDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 존재하는 상품명입니다.')),
      );
      return;
    }

    final imageUrl = await _uploadImage();

    // 이미지 업로드 결과와 관계없이 데이터 저장
    await itemsRef.doc(itemName).set({
      'itemName': itemName,
      'artist': selectedPainter,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'itemType': itemType,
      'imagePath': imageUrl, // 업로드 실패 시 빈 문자열 저장
    });


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 추가'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('상품명',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품명을 입력하세요';
                  }
                  return null;
                },
                onSaved: (value) => itemName = value!.trim(),
              ),
              const SizedBox(height: 16),
              const Text('작가 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder()),
                value: selectedPainter,
                items: painters
                    .map((painter) =>
                        DropdownMenuItem(value: painter, child: Text(painter)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPainter = value!;
                  });
                },
                validator: (value) {
                  if (value == '판매 작가명') {
                    return '해당 상품의 작가를 선택하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('원가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '상품을 만드는데 들어간 비용'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '원가를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력가능합니다';
                  }
                  return null;
                },
                onSaved: (value) => costPrice = int.parse(value!),
              ),
              const SizedBox(height: 16),
              const Text('판매가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '실제로 판매할 가격'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '판매가를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력가능합니다';
                  }
                  return null;
                },
                onSaved: (value) => sellingPrice = int.parse(value!),
              ),
              const SizedBox(height: 16),
              const Text('재고 수량',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: '상품의 총 수량'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '재고 수량을 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력가능합니다';
                  }
                  return null;
                },
                onSaved: (value) => stockQuantity = int.parse(value!),
              ),
              const SizedBox(height: 16),
              const Text('상품 종류',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'ex) 아크릴 키링, 포토 카드 등',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품 종류를 입력하세요';
                  }
                  return null;
                },
                onSaved: (value) => itemType = value!.trim(),
              ),
              const SizedBox(height: 16),
              //const Text('이미지 업로드',
                //  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
              //),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      imageFile = File(pickedFile.path);
                    });
                  }
                },
                style: TextButton.styleFrom(
                  side: BorderSide(color: Colors.grey), // 아웃라인 추가
                  minimumSize: Size(320, 56), // 너비와 높이 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                  child: Center(
                child: const Text(
                    '사진 업로드 +',
                  style: TextStyle(
                    color: Colors.black, // 텍스트 색상 검은색
                  ),
                ),
                  ),
              ),
              if (imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(imageFile!, height: 150),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.asset('assets/catcul_w.jpg', height: 150),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D1D1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            '뒤로가기',
                            style: TextStyle(fontSize: 14, color: Colors.black),
                          )),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBE85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            _addItem();
                          }
                        },
                        child: const Text(
                            '확인',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
