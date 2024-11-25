import 'package:flutter/material.dart';

class BagQrScreen extends StatelessWidget {
  const BagQrScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Screen'),
        automaticallyImplyLeading: false, // Disable back arrow
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code (Placeholder for the actual QR code)
          Center(
            child: Container(
              color: Colors.grey[300], // Just a placeholder for QR code
              width: 200,
              height: 200,
              child: const Center(
                child: Text('QR Code', style: TextStyle(fontSize: 16.0)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Number (Placeholder for QR number or identifier)
          const Text(
            '12345', // Replace with dynamic QR number or identifier
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Message: "해당 화면을 판매자에게 보여주세요"
          const Text(
            '해당 화면을 판매자에게 보여주세요',
            style: TextStyle(fontSize: 16.0, color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Button: "담은 목록 보기" to go back
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Goes back to previous screen
                },
                child: const Text('담은 목록 보기'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}