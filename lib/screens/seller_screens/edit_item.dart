import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditItem extends StatefulWidget {
  const EditItem({super.key});

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  final _formKey = GlobalKey<FormState>();
  String? boothId;
  String? itemId;

  String itemName = '';
  String selectedPainter = '판매 작가명';
  String itemType = '';
  int? costPrice;
  int? sellingPrice;
  int? stockQuantity;
  File? imageFile;
  String? imageUrl; // Firebase Storage에서 가져온 이미지 URL

  List<String> painters = ['판매 작가명'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as List<String?>;
    if (args != null && args.length >= 2) {
      boothId = args[0];
      itemId = args[1];
      _loadPaintersAndItemData();
    }
  }

  Future<void> _loadPaintersAndItemData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null || itemId == null) return;

    final boothRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId);

    final itemRef = boothRef.collection('items').doc(itemId);

    final boothDoc = await boothRef.get();
    final itemDoc = await itemRef.get();

    setState(() {
      // Load painters
      final boothData = boothDoc.data() as Map<String, dynamic>?;
      if (boothData != null && boothData['painters'] is List) {
        painters = [
          '판매 작가명',
          ...boothData['painters']
              .where((painter) => painter != null)
              .map((painter) => painter.toString())
        ];
      }

      // Load item data
      final itemData = itemDoc.data() as Map<String, dynamic>?;
      if (itemData != null) {
        itemName = itemData['itemName'] ?? '';
        selectedPainter = itemData['artist'] ?? '판매 작가명';
        itemType = itemData['itemType'] ?? '';
        costPrice = itemData['costPrice'];
        sellingPrice = itemData['sellingPrice'];
        stockQuantity = itemData['stockQuantity'];
      }
    });

    // Load image from Firebase Storage
    imageUrl = await FirebaseStorage.instance
        .ref()
        .child('$uid/${itemId?.replaceAll(' ', '_')}.jpg')
        .getDownloadURL();
  }

  Future<String> _uploadImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null || itemId == null) return '';

    if (imageFile == null) {
      return imageUrl ?? '';
    }

    final ref = FirebaseStorage.instance
        .ref()
        .child('$uid/${itemId?.replaceAll(' ', '_')}.jpg');
    final uploadTask = ref.putFile(imageFile!);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _updateItem() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null || itemId == null) return;

    final itemRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('booths')
        .doc(boothId)
        .collection('items')
        .doc(itemId);

    final updatedImageUrl = await _uploadImage();

    await itemRef.update({
      'itemName': itemName,
      'artist': selectedPainter,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'itemType': itemType,
      'imagePath': updatedImageUrl,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상품 정보가 성공적으로 수정되었습니다.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 수정'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('상품명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: itemName,
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
              const Text('작가 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
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
              const Text('원가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: costPrice?.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
              const Text('판매가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: sellingPrice?.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
              const Text('재고 수량', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: stockQuantity?.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
              const Text('상품 종류', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextFormField(
                initialValue: itemType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '상품 종류를 입력하세요',
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
              const Text('이미지 미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(imageFile!, height: 150),
                )
              else if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.network(imageUrl!, height: 150),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: const Text('이미지를 불러오는 중입니다.'),
                ),
              TextButton(
                onPressed: () async {
                  final pickedFile =
                  await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      imageFile = File(pickedFile.path);
                    });
                  }
                },
                child: const Text('이미지 선택'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('수정 취소'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _updateItem();
                      }
                    },
                    child: const Text('수정 완료'),
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
