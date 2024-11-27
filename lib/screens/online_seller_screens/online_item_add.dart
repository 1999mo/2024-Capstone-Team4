import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class OnlineItemAdd extends StatefulWidget {
  const OnlineItemAdd({super.key});

  @override
  State<OnlineItemAdd> createState() => _OnlineItemAddState();
}

class _OnlineItemAddState extends State<OnlineItemAdd> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? boothId;
  String itemName = '';
  String artist = '';
  String itemType = '';
  int? costPrice;
  int? sellingPrice;
  File? imageFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boothId = ModalRoute.of(context)?.settings.arguments as String?;
  }

  Future<String> _uploadImage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // 사용자가 이미지를 선택하지 않았다면 빈 문자열 반환
      if (imageFile == null) {
        return '';
      }

      // 선택된 이미지 업로드
      final ref = FirebaseStorage.instance.ref().child('$uid/${itemName.replaceAll(' ', '_')}.jpg');
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



    final itemsRef = FirebaseFirestore.instance.collection('OnlineStore').doc(boothId).collection(uid);

    final existingDoc = await itemsRef.doc(itemName).get();
    if (existingDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 존재하는 상품명입니다.')),
      );
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상품이 성공적으로 추가되었습니다.')),
    );

    final imageUrl = await _uploadImage();

    // 데이터 저장
    await itemsRef.doc(itemName).set({
      'itemName': itemName,
      'artist': artist,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'itemType': itemType,
      'imagePath': imageUrl, // 업로드 실패 시 빈 문자열 저장
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('온라인 상품 추가'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('상품명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Text('작가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '작가명을 입력하세요';
                  }
                  return null;
                },
                onSaved: (value) => artist = value!.trim(),
              ),
              const SizedBox(height: 16),
              const Text('원가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '상품을 만드는데 들어간 비용'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '원가를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
                },
                onSaved: (value) => costPrice = int.parse(value!),
              ),
              const SizedBox(height: 16),
              const Text('판매가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '실제로 판매할 가격'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '판매가를 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
                  }
                  return null;
                },
                onSaved: (value) => sellingPrice = int.parse(value!),
              ),
              const SizedBox(height: 16),
              const Text('상품 종류', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              TextButton(
                onPressed: () async {
                  final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      imageFile = File(pickedFile.path);
                    });
                  }
                },
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.grey), // 아웃라인 추가
                  minimumSize: const Size(320, 56), // 너비와 높이 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Center(
                  child: Text(
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
                        child: const Text(
                          '뒤로가기',
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
