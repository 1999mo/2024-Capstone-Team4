import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 숫자 포맷팅
import 'package:catculator/script.dart';

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

    //결제 카카오톡 부문
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

      {
        // 0. 결제가 완료 되었는지 확인하는 부분
        Scripts script = new Scripts();
        int totalCost = 0;

        final futures = basketData.keys.map((sellerId) async {
          final items = List<Map<String, dynamic>>.from(basketData[sellerId]);

          totalCost += items.fold(
            0,
                (sum, item) =>
            sum + (((item['sellingPrice'] as num?)?.toInt() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 0)),
          );
        }).toList();
        await Future.wait(futures);

        String result = await script.sendPaymentCheck(context, totalCost, uid, 'CatCulator');
        //uid 부문에 추후 사용자의 계좌 입력 필요
        //결제 금액과 계좌 번호로 확인
        //true 이외의 경우 오류 메시지를 받아서 팝업으로 띄움
        //'CatCulator' 부문에 결제 이름 추가 가능하면 추가

        if (result != 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
          return;
        }
      }

      // Step 1: Copy data to `online_order_list`
      for (var sellerId in basketData.keys) {
        final boothNameRef = await FirebaseFirestore.instance.collection('Users').doc(sellerId).collection('booths').doc(festivalName).get();
        buyerInfo['boothName']=boothNameRef['boothName'];
        final sellerBasketItems = List.from(basketData[sellerId]);

        final uniqueOrderId =
            FirebaseFirestore.instance.collection('placeholder').doc().id;

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

        final uniqueConsumerId =
            FirebaseFirestore.instance.collection('placeholder').doc().id;

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
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '성함',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                    hintText: '이름을 입력하세요', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                '주소',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: addressController,
                decoration: const InputDecoration(
                    hintText: '주소를 입력하세요', border: OutlineInputBorder()),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? '주소를 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                '우편번호',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: zipcodeController,
                decoration: const InputDecoration(
                    hintText: '우편번호를 입력하세요', border: OutlineInputBorder()),
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
              const Text(
                '전화번호',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                    hintText: '전화번호를 입력하세요', border: OutlineInputBorder()),
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
              SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '총 결제금액',
                      style: TextStyle(
                          fontSize: 23,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                        '${numberFormat.format(totalCost)}원',
                        style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                          color: Colors.red
                        ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
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
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                            '뒤로가기',
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10,),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDBE85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: isProcessing ? null : _processPayment,
                        child: isProcessing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                            '결제하기',
                          style: TextStyle(color: Colors.black),
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
