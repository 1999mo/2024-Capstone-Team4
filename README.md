진행 상황 보고 2024 - 10 - 10 : 앱의 디렉터리 구성 완료

    lib/
    │
    ├── main.dart                # 앱 실행 진입점
    │
    ├── core/                    # 앱의 핵심 기능 및 서비스 관련 코드
    │   ├── constants/           # 상수값들 (API 키, 문자열, 스타일 등)
    │   ├── services/            # Firebase, API 통신 등 서비스 관련 코드
    │   ├── utils/               # 헬퍼 함수, 유틸리티 함수
    │   └── themes/              # 앱의 테마 (색상, 텍스트 스타일 등)
    │
    ├── data/                    # 데이터 관련 폴더
    │   ├── models/              # 데이터 모델 (예: User, Product 등)
    │   ├── providers/           # 상태 관리 (예: Provider, Riverpod 등)
    │   └── repositories/        # 데이터 소스 (Firebase, 로컬 DB 등과의 통신)
    │
    ├── presentation/            # 화면 관련 폴더
    │   ├── screens/             # 화면 (HomeScreen, DetailScreen 등)
    │   ├── widgets/             # 공통 위젯 (예: 버튼, 카드 등)
    │   └── components/          # 페이지별 세부 컴포넌트 (예: 특정 페이지에 종속된 위젯)
    │
    ├── routes/                  # 라우트 설정 폴더
    │   └── app_routes.dart      # 라우트 설정 파일
    │
    └── config/                  # 설정 관련 폴더
        ├── env/                 # 환경 변수 관련 (예: dev, prod 설정)
        └── firebase_options.dart # Firebase 초기화 및 설정