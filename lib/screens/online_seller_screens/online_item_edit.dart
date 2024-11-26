import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class OnlineItemEdit extends StatefulWidget {
  const OnlineItemEdit({super.key});

  @override
  State<OnlineItemEdit> createState() => _OnlineItemEditState();
}

class _OnlineItemEditState extends State<OnlineItemEdit> {
  final _formKey = GlobalKey<FormState>();
  String? boothId;
  String? itemId;
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  late TextEditingController itemNameController;
  late TextEditingController artistController;
  late TextEditingController itemTypeController;
  late TextEditingController costPriceController;
  late TextEditingController sellingPriceController;

  File? imageFile;
  String? imageUrl;
  final String defaultImagePath = 'assets/catcul_w.jpg'; // 기본 이미지 경로

  @override
  void initState() {
    super.initState();
    itemNameController = TextEditingController();
    artistController = TextEditingController();
    itemTypeController = TextEditingController();
    costPriceController = TextEditingController();
    sellingPriceController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as List<String?>;
    if (args != null && args.length == 2) {
      boothId = args[0];
      itemId = args[1];
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    if (uid == null || boothId == null || itemId == null) return;

    final itemRef = FirebaseFirestore.instance
        .collection('OnlineStore')
        .doc(boothId)
        .collection(uid!)
        .doc(itemId);

    final itemDoc = await itemRef.get();

    if (itemDoc.exists) {
      final itemData = itemDoc.data() as Map<String, dynamic>?;
      if (itemData != null) {
        setState(() {
          itemNameController.text = itemData['itemName'] ?? '';
          artistController.text = itemData['artist'] ?? '';
          itemTypeController.text = itemData['itemType'] ?? '';
          costPriceController.text = itemData['costPrice']?.toString() ?? '';
          sellingPriceController.text = itemData['sellingPrice']?.toString() ?? '';
        });
      }
    }

    imageUrl = await _getImageUrl();
  }

  Future<String?> _getImageUrl() async {
    if (uid == null || itemId == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref('$uid/$itemId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null; // 이미지가 없거나 에러가 발생한 경우
    }
  }

  Future<String> _uploadImage() async {
    if (uid == null || itemId == null || imageFile == null) return imageUrl ?? '';
    final ref = FirebaseStorage.instance.ref('$uid/${itemId?.replaceAll(' ', '_')}.jpg');
    final uploadTask = ref.putFile(imageFile!);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _updateItem() async {
    if (uid == null || boothId == null || itemId == null) return;

    final itemRef = FirebaseFirestore.instance
        .collection('OnlineStore')
        .doc(boothId)
        .collection(uid!)
        .doc(itemId);

    final updatedImageUrl = await _uploadImage();

    await itemRef.update({
      'itemName': itemNameController.text.trim(),
      'artist': artistController.text.trim(),
      'itemType': itemTypeController.text.trim(),
      'costPrice': int.tryParse(costPriceController.text),
      'sellingPrice': int.tryParse(sellingPriceController.text),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: itemNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('작가명', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: artistController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '작가명을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('상품 종류', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: itemTypeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '상품 종류를 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('원가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: costPriceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
              ),
              const SizedBox(height: 16),
              const Text('판매가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: sellingPriceController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
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
              ),
              const SizedBox(height: 16),
              const Text('이미지 미리보기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (imageFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.file(imageFile!, height: 150),
                )
              else if (imageUrl != null && imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.network(
                    imageUrl!,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(defaultImagePath, height: 150);
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Image.asset(defaultImagePath, height: 150),
                ),
              TextButton(
                onPressed: () async {
                  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      imageFile = File(pickedFile.path);
                    });
                  }
                },
                style: TextButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  minimumSize: const Size(320, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('사진 업로드 +', style: TextStyle(color: Colors.black)),
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
                        child: const Text('수정 취소', style: TextStyle(fontSize: 14, color: Colors.black)),
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
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상품정보가 수정되었습니다.')));
                            _updateItem();
                          }
                        },
                        child: const Text('수정 완료', style: TextStyle(fontSize: 14, color: Colors.black)),
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
