진행 상황 보고 2024 - 10 - 10 : 앱의 디렉터리 구성 완료

전체 공지
1. 컨셉 컬러 : #FDBE85 (주황색) Figma에서 주황색 나왔다 싶으면 무조건 이 색깔을 사용
2. 사용할 때는 => Color(0xfffdbe85)
3. 판매자 테스트 계정 아이디 : test@gmail.com    비밀번호 : 123456
4. 구매자 테스트 계정 아이디 : test2@gmail.com    비밀번호 : 123456

최유나님 공지사항
1. 꾸며야 하는 위젯 코드에 커서를 올려놓는다.
2. Alt + enter 을 입력하고 Wrap with Container 을 사용한다.
3. 너비 조정에는 width
4. 높이 조정시 height
5. 여백 조정시
   EdgeInsets.all(double)	네 방향의 여백을 동일하게 지정
   EdgeInsets.symmetric(horizontal : double)	가로(horizontal)와 세로(vertical) 방향의 여백을 개별적으로 지정
   EdgeInsets.only(left: double)	특정 방향(left, top, right, bottom)의 여백을 개별적으로 지정

6. 위젯과 위젯 사이에 10의 간격이 있을 경우 위 위젯과 아래 위젯에 각각 10을 줘버리면 20이 되므로 이런 경우 각각 5씩 주거나 SizedBox 위젯을 이용할 것
   
7. 글꼴 꾸미는법 Text('예시')  =>  Text('예시', style: TextStyle(fontSize: 글씨크기, color:... 등등))
8. 곤란한 상황엔 새벽이라도 괜찮으니 언제든 연락할 것 어차피 새벽에 자고 있을리가 전무함

TODO
 - my_booth.dart
 - selling.dart
 - edit_selling)

김준모님 공지사항
1. 구매하 화면 구성

발신자 api : 408587343572