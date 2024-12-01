import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 숫자 포맷팅


class OnlineBuyerPay extends StatefulWidget {
  const OnlineBuyerPay({super.key});

  @override
  State<OnlineBuyerPay> createState() => _OnlineBuyerPayState();
}

class _OnlineBuyerPayState extends State<OnlineBuyerPay> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController zipcodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isProcessing = false;

  late String? festivalName;
  late int totalCost;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as List<dynamic>;
    festivalName = args[0] as String?;
    totalCost = args[1] as int;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isProcessing = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 인증 정보가 없습니다. 다시 시도해주세요.')),
      );
      setState(() {
        isProcessing = false;
      });
      return;
    }

    final basketRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_basket')
        .doc(festivalName);

    final orderListRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('online_order_list')
        .doc(festivalName);

    try {
      final basketSnapshot = await basketRef.get();
      if (!basketSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장바구니가 비어 있습니다.')),
        );
        return;
      }

      final basketData = basketSnapshot.data() as Map<String, dynamic>;
      final buyerInfo = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'zipcode': zipcodeController.text.trim(),
      };

      // Step 1: Copy data to `online_order_list`
      for (var sellerId in basketData.keys) {
        final sellerBasketItems = List.from(basketData[sellerId]);

        final uniqueOrderId = FirebaseFirestore.instance.collection('placeholder').doc().id;

        await orderListRef.set({
          uniqueOrderId: [buyerInfo, ...sellerBasketItems],
        }, SetOptions(merge: true));
      }

      // Step 2: Process `online_consumer_list` updates
      for (var sellerId in basketData.keys) {
        final sellerOrdersRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerId)
            .collection('online_consumer_list')
            .doc(festivalName);

        final uniqueConsumerId = FirebaseFirestore.instance.collection('placeholder').doc().id;

        await sellerOrdersRef.set({
          uniqueConsumerId: [buyerInfo, ...List.from(basketData[sellerId])],
        }, SetOptions(merge: true));
      }

      // Step 3: Delete the basket
      await basketRef.delete();

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결제가 완료되었습니다!')),
      );

      // Navigate back
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('결제 처리 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('성함', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(hintText: '이름을 입력하세요', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? '이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Text('주소', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(hintText: '주소를 입력하세요', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? '주소를 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Text('우편번호', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: zipcodeController,
                decoration: const InputDecoration(hintText: '우편번호를 입력하세요', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '우편번호를 입력하세요';
                  } else if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                    return '숫자만 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('전화번호', style: TextStyle(fontSize: 16)),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(hintText: '전화번호를 입력하세요', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '전화번호를 입력하세요';
                  } else if (!RegExp(r'^\d+$').hasMatch(value.trim())) {
                    return '숫자만 입력하세요';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20,),
              Text('총 결제 금액 : ${numberFormat.format(totalCost)}', style: TextStyle(fontSize: 30),),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: const Text('뒤로가기'),
                  ),
                  ElevatedButton(
                    onPressed: isProcessing ? null : _processPayment,
                    child: isProcessing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text('결제하기'),
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
