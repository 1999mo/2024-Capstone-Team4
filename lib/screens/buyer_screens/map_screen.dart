import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? festivalName;
  String? mapImageUrl;
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    festivalName = ModalRoute.of(context)?.settings.arguments as String?;
    if (festivalName != null) {
      _fetchMapImage();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMapImage() async {
    try {
      final formattedName = festivalName!.replaceAll(' ', '_');
      final ref = FirebaseStorage.instance.ref('maps/$formattedName.jpg');
      final url = await ref.getDownloadURL();
      setState(() {
        mapImageUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        mapImageUrl = null;
        isLoading = false;
      });
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero, // 화면 전체에 꽉 차게
          child: Column(
            children: [
              Container(
                color: Colors.black,
                padding: const EdgeInsets.only(top: 16, right: 16),
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  maxScale: 10.0,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(festivalName ?? '지도 정보'),
        centerTitle: true,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : mapImageUrl != null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              mapImageUrl!,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 35),
            ElevatedButton.icon(
              onPressed: () => _showFullScreenImage(mapImageUrl!),
              icon: const Icon(Icons.zoom_in),
              label: const Text('확대'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                backgroundColor: const Color(0xFFFDBE85),
                foregroundColor: Colors.black,
              ),
            ),
          ],
        )
            : const Text(
          '아직 지도 정보가 업로드되지 않았습니다.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
