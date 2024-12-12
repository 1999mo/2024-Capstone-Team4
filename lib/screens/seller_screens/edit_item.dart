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
  bool isDataLoaded=false;

  late TextEditingController itemNameController;
  late TextEditingController costPriceController;
  late TextEditingController sellingPriceController;
  late TextEditingController stockQuantityController;
  late TextEditingController itemTypeController;

  String selectedPainter = '판매 작가명';
  File? imageFile;
  String? imageUrl;

  List<String> painters = ['판매 작가명'];
  final String defaultImagePath = 'assets/catcul_w.jpg'; // 기본 이미지 경로

  @override
  void initState() {
    super.initState();
    itemNameController = TextEditingController();
    costPriceController = TextEditingController();
    sellingPriceController = TextEditingController();
    stockQuantityController = TextEditingController();
    itemTypeController = TextEditingController();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as List<String?>;
    if (args != null && args.length >= 2) {
      boothId = args[0];
      itemId = args[1];

    }
    _loadPaintersAndItemData();
  }



  Future<void> _loadPaintersAndItemData() async {
    if(isDataLoaded) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null || itemId == null) return;

    final boothRef = FirebaseFirestore.instance.collection('Users').doc(uid).collection('booths').doc(boothId);

    final itemRef = boothRef.collection('items').doc(itemId);

    final boothDoc = await boothRef.get();
    final itemDoc = await itemRef.get();

    if (boothDoc.exists) {
      final boothData = boothDoc.data();
      if (boothData != null && boothData['painters'] is List) {
        setState(() {
          painters = [
            '판매 작가명',
            ...boothData['painters'].where((painter) => painter != null).map((painter) => painter.toString())
          ];
        });
      }
    }

    if (itemDoc.exists) {
      final itemData = itemDoc.data() as Map<String, dynamic>?;
      if (itemData != null) {
        setState(() {
          itemNameController.text = itemData['itemName'] ?? '';
          costPriceController.text = itemData['costPrice']?.toString() ?? '';
          sellingPriceController.text = itemData['sellingPrice']?.toString() ?? '';
          stockQuantityController.text = itemData['stockQuantity']?.toString() ?? '';
          itemTypeController.text = itemData['itemType'] ?? '';
          selectedPainter = itemData['artist'] ?? '판매 작가명';
          imageUrl = itemData['imagePath'];
        });
      }
    }
    isDataLoaded=true;
  }

  Future<void> _deletePreviousImage(String? previousImagePath) async {
    if (previousImagePath != null && previousImagePath.isNotEmpty) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(previousImagePath);
        await ref.delete();
      } catch (e) {
        debugPrint('이미지 삭제 실패: $e');
      }
    }
  }

  Future<String> _uploadImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || boothId == null || itemId == null) return '';

    if (imageFile == null) {
      return imageUrl ?? '';
    }

    final ref = FirebaseStorage.instance.ref().child('$uid/${itemId?.replaceAll(' ', '_')}.jpg');
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

    await _deletePreviousImage(imageUrl); // 기존 이미지 삭제
    final updatedImageUrl = await _uploadImage();

    await itemRef.update({
      'itemName': itemNameController.text.trim(),
      'artist': selectedPainter,
      'costPrice': int.tryParse(costPriceController.text),
      'sellingPrice': int.tryParse(sellingPriceController.text),
      'stockQuantity': int.tryParse(stockQuantityController.text),
      'itemType': itemTypeController.text.trim(),
      'imagePath': updatedImageUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 수정'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(selectedPainter)));
          }, icon: Icon(Icons.abc))
        ],
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
              const Text('작가 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder()),
                value: selectedPainter,
                items: painters.map((painter) => DropdownMenuItem(value: painter, child: Text(painter))).toList(),
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
                    return '숫자만 입력가능합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('판매가',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              const Text('재고 수량', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: stockQuantityController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '재고 수량을 입력하세요';
                  }
                  if (int.tryParse(value) == null) {
                    return '숫자만 입력 가능합니다';
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
              const SizedBox(height: 16,),
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
                  minimumSize: const Size(double.infinity, 56),
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
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('상품정보가 수정되었습니다.'), duration: Duration(seconds: 1),));
                            Navigator.pop(context);
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
