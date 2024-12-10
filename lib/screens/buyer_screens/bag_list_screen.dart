import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart'; // UUID 생성용
import 'package:catculator/script.dart';

class BagListScreen extends StatefulWidget {
  const BagListScreen({super.key});

  @override
  State<BagListScreen> createState() => _BagListScreenState();
}

class _BagListScreenState extends State<BagListScreen> {
  String? festivalName;
  Map<String, List<Map<String, dynamic>>> basketData = {};
  int totalCost = 0;
  bool isLoading = false; // 로딩 상태 관리

  final numberFormat = NumberFormat('#,###');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
    _fetchBasketItems();
  }

  Future<void> _fetchBasketItems() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    try {
      final basketRef = FirebaseFirestore.instance
          .collection('Users')
          .doc(uid)
          .collection('basket')
          .doc(festivalName);
      final basketSnapshot = await basketRef.get();

      if (basketSnapshot.exists) {
        final data = basketSnapshot.data() as Map<String, dynamic>;
        final fetchedData = <String, List<Map<String, dynamic>>>{};

        for (var sellerUid in data.keys) {
          final items =
              (data[sellerUid] as List<dynamic>).cast<Map<String, dynamic>>();
          fetchedData[sellerUid] = items;
        }

        setState(() {
          basketData = fetchedData;
          _calculateTotalCost();
        });
      }
    } catch (e) {
      debugPrint('Error fetching basket items: $e');
    }
  }

  void _calculateTotalCost() {
    totalCost = basketData.values.expand((items) => items).fold(
        0,
        (sum, item) =>
            sum + (item['sellingPrice'] as int) * (item['quantity'] as int));
    setState(() {});
  }

  Future<void> _updateQuantity(
      String sellerUid, int index, int quantity) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    basketData[sellerUid]![index]['quantity'] = quantity;
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('basket')
        .doc(festivalName)
        .set(basketData);

    _calculateTotalCost();
  }

  Future<void> _removeItem(String sellerUid, int index) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || festivalName == null) return;

    basketData[sellerUid]!.removeAt(index);
    if (basketData[sellerUid]!.isEmpty) {
      basketData.remove(sellerUid);
    }

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('basket')
        .doc(festivalName)
        .set(basketData);

    _calculateTotalCost();
  }

  Future<void> handlePayment(BuildContext context, String? festivalName) async {
    if (totalCost == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('장바구니에 물건이 없습니다.'),
        duration: Duration(seconds: 1),
      ));
      return;
    }
    if (festivalName == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final basketRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('basket')
        .doc(festivalName);
    final basketSnapshot = await basketRef.get();

    if (!basketSnapshot.exists) return;

    final data = basketSnapshot.data() as Map<String, dynamic>;
    final uuid = Uuid();

    try {
      {
        // 0. 결제가 완료 되었는지 확인하는 부분
        Scripts script = new Scripts();
        int totalCost = 0;

        final futures = data.keys.map((sellerId) async {
          final items = List<Map<String, dynamic>>.from(data[sellerId]);

          totalCost += items.fold(
            0,
                (sum, item) =>
            sum + (((item['sellingPrice'] as num?)?.toInt() ?? 0) * ((item['quantity'] as num?)?.toInt() ?? 0)),
          );
        }).toList();
        await Future.wait(futures);

        String result = await script.sendPaymentCheck(context, totalCost, uid);
        //uid 부문에 추후 사용자의 계좌 입력 필요
        //결제 금액과 계좌 번호로 확인
        //true 이외의 경우 오류 메시지를 받아서 팝업으로 띄움

        if (result != 'true') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
          return;
        }
      }

      for (String sellerUid in data.keys) {
        final sellerItems = List<Map<String, dynamic>>.from(data[sellerUid]);
        final boothDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerUid)
            .collection('booths')
            .doc(festivalName)
            .get();

        final boothName = boothDoc.data()?['boothName'] ?? '부스명 없음';

        // Generate unique pre_order_code
        final preOrderCode = uuid.v4().substring(0, 7); // 7자리 고유 코드

        // Generate QR code and upload to Firebase Storage
        final qrPath = await _generateAndUploadQrCode(uid, preOrderCode);

        // Prepare new pre-order list
        final preOrderList = [
          {
            'boothName': boothName,
            'pre_order_code': preOrderCode,
            'qr_path': qrPath,
          },
          ...sellerItems,
        ];

        // Use unique ID for the order document
        final orderId = uuid.v4();

        // Save to pre_order_list
        final preOrderRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(sellerUid)
            .collection('pre_order_consumer_list')
            .doc(festivalName);

        await preOrderRef.set({orderId: preOrderList}, SetOptions(merge: true));

        // Save to pre_order_consumer_list
        final consumerRef = FirebaseFirestore.instance
            .collection('Users')
            .doc(uid)
            .collection('pre_order_list')
            .doc(festivalName);

        await consumerRef.set({orderId: preOrderList}, SetOptions(merge: true));
      }

      // Clear basket
      await basketRef.delete();

      // Show success snackbar and navigate to Order List tab
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('결제가 완료되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {});
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> _generateAndUploadQrCode(
      String uid, String preOrderCode) async {
    try {
      // Generate QR code as an image
      final qrPainter = QrPainter(
        data: preOrderCode,
        version: QrVersions.auto,
        gapless: false,
      );

      // Save the QR code to a temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/pre_$preOrderCode.jpg';

      final file = File(tempPath);
      final byteData =
          await qrPainter.toImageData(300); // Generate a 300x300 image
      await file.writeAsBytes(byteData!.buffer.asUint8List());

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref('$uid/pre_$preOrderCode.jpg');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});

      // Return the QR code URL
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('QR 코드 생성 및 업로드 실패: $e');
      return '';
    }
  }

  Future<void> _handlePayment(BuildContext context) async {
    setState(() {
      isLoading = true; // 로딩 시작
    });

    try {
      await handlePayment(context, festivalName); // 결제 처리
    } finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = basketData.entries.toList();
    sortedEntries.sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? '장바구니'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: sortedEntries.length,
            itemBuilder: (context, sellerIndex) {
              final sellerUid = sortedEntries[sellerIndex].key;
              final items = sortedEntries[sellerIndex].value;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Users')
                    .doc(sellerUid)
                    .collection('booths')
                    .doc(festivalName)
                    .get(),
                builder: (context, snapshot) {
                  final boothName = snapshot.data?['boothName'] ?? '부스명 없음';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          '$boothName',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: item['imagePath'] ?? '',
                                          placeholder: (context, url) =>
                                              const CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                              Image.asset(
                                                  'assets/catcul_w.jpg'),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Color(0xFFD1D1D1)),
                                              shape: BoxShape.circle,
                                              color: item['quantity'] == 1
                                                  ? Color(0x91D1D1D1)
                                                  : null,
                                            ),
                                            height: 30,
                                            width: 30,
                                            child: IconButton(
                                              icon: const Icon(Icons.remove,
                                                  color: Colors.blue),
                                              iconSize: 18,
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: item['quantity'] > 1
                                                  ? () {
                                                      _updateQuantity(
                                                          sellerUid,
                                                          index,
                                                          item['quantity'] - 1);
                                                    }
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text('${item['quantity']}'),
                                          const SizedBox(width: 4),
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Color(0xFFD1D1D1)),
                                              shape: BoxShape.circle,
                                            ),
                                            height: 30,
                                            width: 30,
                                            child: IconButton(
                                              icon: const Icon(Icons.add,
                                                  color: Colors.red),
                                              iconSize: 18,
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onPressed: () {
                                                _updateQuantity(
                                                    sellerUid,
                                                    index,
                                                    item['quantity'] + 1);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          item['itemName'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₩${numberFormat.format(item['sellingPrice'])}', // 상품 가격 표시
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.close,
                                                color: Colors.grey),
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            visualDensity:
                                                VisualDensity.compact,
                                            onPressed: () {
                                              _removeItem(sellerUid, index);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                          height: 20), // 아래 요소와 간격 유지
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          '₩${numberFormat.format(item['sellingPrice'] * item['quantity'])}',
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(10),
              color: isLoading
                  ? Colors.grey[300]
                  : const Color(0xfffdbe85), // 로딩 중일 때 흐릿한 색상
              child: InkWell(
                onTap: isLoading
                    ? null // 로딩 중에는 클릭 불가
                    : () async {
                        await _handlePayment(context); // 결제 처리 호출
                      },
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '총 금액 ₩${numberFormat.format(totalCost)}',
                              ),
                              const Text(
                                '구매하기',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
