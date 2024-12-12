import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:catculator/screens/splash.dart';
import 'package:catculator/screens/user_auth/auth_screen_export.dart';
import 'package:catculator/screens/main_screens/main_screen_export.dart';
import 'package:catculator/screens/seller_screens/seller_screen_export.dart';
import 'package:catculator/screens/buyer_screens/buyer_screens_export.dart';
import 'package:catculator/screens/online_seller_screens/online_seller_screens_export.dart';
import 'package:catculator/screens/online_buyer_screens/online_buyer_screens_export.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  // FlutterLocalNotificationsPlugin 초기화
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "축제 도우미",
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MakeProfile();
          }
          return const Splash();
        },
      ),
      routes: {
        '/splash': (context) => const Splash(),

        //user_auth 시작
        '/user_auth/login_screen': (context) => const LoginScreen(),
        '/user_auth/signup': (context) => const Signup(),
        '/user_auth/find_id': (context) => const FindId(),

        //seller_screens 시작
        '/main_screens/make_profile': (context) => const MakeProfile(),
        '/main_screens/main_screen': (context) => const MainScreen(),
        '/main_screens/setting': (context) => const Setting(),
        '/seller_screens/my_booth': (context) => const MyBooth(),
        '/seller_screens/add_booth': (context) => const AddBooth(),
        '/seller_screens/selling': (context) => const Selling(),
        '/seller_screens/selling_details':(context)=> const SellingDetails(),
        '/seller_screens/edit_selling_items': (context)=>const EditSellingItems(),
        '/seller_screens/add_item':(context)=>const AddItem(),
        '/seller_screens/edit_item':(context)=>const EditItem(),
        '/seller_screens/adjustment':(context)=>const Adjustment(),
        '/seller_screens/adjustment_detail':(context)=>const AdjustmentDetail(),
        '/seller_screens/sale_record':(context)=>const SaleRecord(),
        '/seller_screens/pre_order':(context)=>const PreOrder(),

        //buyer_screens 시작
        '/buyer_screens/buyer_navigation_screen':(context)=>const BuyerNavigationScreen(),
        '/buyer_screens/booth_items_list':(context)=>const BoothItemsList(),
        '/buyer_screens/booth_item_screen':(context)=>const BoothItemScreen(),
        '/buyer_screens/preBooth_list_screen':(context)=>const PreboothListScreen(),
        '/buyer_screens/preBooth_item_list':(context)=>const PreboothItemsList(),
        '/buyer_screens/bag_list_screen':(context)=>const BagListScreen(),
        '/buyer_screens/order_list':(context)=>const OrderList(),


        //online_seller_screens 시작
        '/online_seller_screens/online_select_booth':(context)=>const OnlineSelectBooth(),
        '/online_seller_screens/my_online_items':(context)=>const MyOnlineItems(),
        '/online_seller_screens/online_item_edit':(context)=>const OnlineItemEdit(),
        '/online_seller_screens/online_item_add':(context)=>const OnlineItemAdd(),
        '/online_seller_screens/online_consumer_list':(context)=>const OnlineConsumerList(),

        //online_buyer_screens 시작
        '/online_buyer_screens/navigation':(context)=>const NavigationMain(),
        '/online_buyer_screens/online_select_festival':(context)=>const OnlineSelectFestival(),
        '/online_buyer_screens/online_select_booths':(context)=>const OnlineSelectBooths(),
        '/online_buyer_screens/online_look_booth_items':(context)=>const OnlineLookBoothItems(),
        '/online_buyer_screens/online_buyer_shopping_cart':(context)=>const OnlineBuyerShoppingCart(),
        '/online_buyer_screens/online_buyer_pay':(context)=>const OnlineBuyerPay(),
        '/online_buyer_screens/online_buyer_order_list':(context)=>const OnlineBuyerOrderList(),


      },
    );
  }
}
