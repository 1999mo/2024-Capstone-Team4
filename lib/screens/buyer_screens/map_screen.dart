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
  String selectedBooth = '메인 부스 선택';
  String selectedZone = '편의시설 또는 존 선택';
  final List<String> boothOptions = ['메인 부스 선택'] + List.generate(25, (index) => String.fromCharCode(65 + index));
  final List<String> zoneOptions = [
    '편의시설 또는 존 선택',
    '인디게임 특별존',
    '어덜트존',
    '버츄올스타',
    '크리에스타',
    '보카스타',
    '푸드존',
    '무대',
    'Biz',
    '탈의실 및 물품보관소',
    '화장실'
  ];

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
                    children: [
                      Expanded(
                        child: InteractiveViewer(
                          maxScale: 10.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // 이미지의 원본 비율 계산
                              double imageAspectRatio = 1.5; // 예: 가로:세로 비율이 3:2인 경우
                              double imageWidth = constraints.maxWidth; // 이미지의 최대 너비
                              double imageHeight = imageWidth / imageAspectRatio;
                              double imageLeft = (constraints.maxWidth - imageWidth) / 2;
                              double imageTop = (constraints.maxHeight - imageHeight) / 2;

                              //////////////////////////////
                              double leftPosition = 0;
                              double topPosition = 0;
                              double recWidth=0;
                              double recHeight=0;
                              int recWidthRatio = 0;
                              int recHeightRatio = 0;
                              int xLocationRatio = 0;
                              int yLocationRatio = 0;

                              // 화장실 위치와 크기 리스트
                              List<Map<String, dynamic>> bathroomLocations = [
                                {'x': 293, 'y': 30, 'width': 8, 'height': 10},
                                {'x': 214, 'y': 30, 'width': 8, 'height': 10},
                                {'x': 56, 'y': 30, 'width': 17, 'height': 10},
                                {'x': 137, 'y': 235, 'width': 25, 'height': 10},
                                {'x': 5, 'y': 235, 'width': 8, 'height': 10},
                              ];

                              List<Widget> _buildBathroomWidgets(
                                  double imageLeft, double imageTop, double imageWidth, double imageHeight) {
                                return bathroomLocations.map((bathroom) {
                                  double leftPosition = imageLeft + (imageWidth / 320) * (8 + bathroom['x']);
                                  double topPosition = imageTop + (imageHeight / 360) * bathroom['y'] * 1.01;
                                  double width = (imageWidth / 150) * bathroom['width'];
                                  double height = (imageHeight / 150) * bathroom['height'];

                                  return Positioned(
                                    left: leftPosition,
                                    top: topPosition,
                                    child: Container(
                                      width: width,
                                      height: height,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        border: Border.all(color: Colors.red, width: 2.0),
                                      ),
                                    ),
                                  );
                                }).toList();
                              }

                              // 이미지가 컨테이너보다 높거나 넓을 경우 처리
                              if (imageHeight > constraints.maxHeight) {
                                imageHeight = constraints.maxHeight;
                                imageWidth = imageHeight * imageAspectRatio;
                              }

                              // 실제 이미지가 렌더링될 위치의 시작 좌표



                              if (selectedBooth != '메인 부스 선택') {
                                String firstLetter = selectedBooth[0].toLowerCase();
                                int offset = firstLetter.codeUnitAt(0) - 'a'.codeUnitAt(0);

                                xLocationRatio = 0;
                                yLocationRatio = (firstLetter == 'x' || firstLetter == 'y') ? 112 : 70;

                                recWidthRatio = 3;
                                recHeightRatio = 45;

                                for (int i = 1; i <= offset; i++) {
                                  xLocationRatio += (i % 2 == 1) ? 7 : 4;
                                }
                              }

                              if (selectedZone != '편의시설 또는 존 선택' && selectedZone != '화장실') {
                                if (selectedZone == '인디게임 특별존') {
                                  xLocationRatio = 62;
                                  yLocationRatio = 173;
                                  recWidthRatio = 20;
                                  recHeightRatio = 18;
                                } else if (selectedZone == '어덜트존') {
                                  xLocationRatio = 130;
                                  yLocationRatio = 46;
                                  recWidthRatio = 30;
                                  recHeightRatio = 25;
                                } else if (selectedZone == '버츄올스타') {
                                  xLocationRatio = 146;
                                  yLocationRatio = 107;
                                  recWidthRatio = 25;
                                  recHeightRatio = 22;
                                } else if (selectedZone == '크리에스타') {
                                  xLocationRatio = 145;
                                  yLocationRatio = 145;
                                  recWidthRatio = 25;
                                  recHeightRatio = 18;
                                } else if (selectedZone == '보카스타') {
                                  xLocationRatio = 145;
                                  yLocationRatio = 175;
                                  recWidthRatio = 25;
                                  recHeightRatio = 15;
                                } else if (selectedZone == '푸드존') {
                                  xLocationRatio = 190;
                                  yLocationRatio = 47;
                                  recWidthRatio = 28;
                                  recHeightRatio = 25;
                                } else if (selectedZone == '무대') {
                                  xLocationRatio = 230;
                                  yLocationRatio = 105;
                                  recWidthRatio = 35;
                                  recHeightRatio = 60;
                                } else if (selectedZone == 'Biz') {
                                  xLocationRatio = 195;
                                  yLocationRatio = 104;
                                  recWidthRatio = 10;
                                  recHeightRatio = 50;
                                } else if (selectedZone == '탈의실 및 물품보관소') {
                                  xLocationRatio = 247;
                                  yLocationRatio = 45;
                                  recWidthRatio = 30;
                                  recHeightRatio= 28;
                                }
                              }

                              leftPosition = imageLeft + (imageWidth / 320) * (4.5 + xLocationRatio);
                              topPosition = imageTop + (imageHeight / 360) * (yLocationRatio) * (1.01);
                              recWidth=(imageWidth / 150) * recWidthRatio;
                              recHeight= (imageHeight / 150) * recHeightRatio;


                              return Stack(
                                children: [
                                  Center(
                                    child: Image.network(
                                      mapImageUrl!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  if (selectedZone == '화장실')
                                    ..._buildBathroomWidgets(imageLeft, imageTop, imageWidth, imageHeight),
                                  if (selectedBooth != '메인 부스 선택' ||
                                      (selectedZone != '편의시설 또는 존 선택' && selectedZone != '화장실'))
                                    Positioned(
                                      left: leftPosition, // 사각형 중심 맞추기
                                      top: topPosition, // 사각형 중심 맞추기
                                      child: Container(
                                        width:recWidth,
                                        height: recHeight,
                                        decoration: BoxDecoration(
                                          color: Colors.transparent, // 투명한 배경
                                          border: Border.all(color: Colors.red, width: 2.0), // 빨간 테두리
                                          shape: BoxShape.rectangle, // 사각형 모양
                                        ),
                                      ),
                                    ),
                                  Positioned(
                                      top: 16,
                                      left: 16,
                                      right: 16,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: DropdownButtonFormField<String>(
                                                  value: selectedBooth,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedBooth = value!;
                                                      selectedZone = '편의시설 또는 존 선택';
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide:
                                                          BorderSide(color: Color(0xfffdbe85), width: 2.0), // 컨셉컬러 적용
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide:
                                                          BorderSide(color: Color(0xfffdbe85), width: 3.0), // 더 두꺼운 테두리
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                  ),
                                                  items: boothOptions
                                                      .map(
                                                        (booth) => DropdownMenuItem(
                                                          value: booth,
                                                          child: Text(
                                                            booth,
                                                            style: TextStyle(
                                                              color: Colors.black,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: DropdownButtonFormField<String>(
                                                  value: selectedZone,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedZone = value!;
                                                      selectedBooth = '메인 부스 선택';
                                                    });
                                                  },
                                                  decoration: InputDecoration(
                                                    enabledBorder: OutlineInputBorder(
                                                      borderSide:
                                                          BorderSide(color: Color(0xfffdbe85), width: 2.0), // 컨셉컬러 적용
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide:
                                                          BorderSide(color: Color(0xfffdbe85), width: 3.0), // 더 두꺼운 테두리
                                                      borderRadius: BorderRadius.circular(8.0),
                                                    ),
                                                  ),
                                                  items: zoneOptions
                                                      .map(
                                                        (zone) => DropdownMenuItem(
                                                          value: zone,
                                                          child: Text(
                                                            zone,
                                                            style: TextStyle(
                                                                color: Colors.black, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 14,
                                                  ),
                                                  icon: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )),
                                ],
                              );
                            },
                          ),
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
