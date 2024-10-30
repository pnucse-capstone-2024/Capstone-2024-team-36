
import 'package:alphatron_app/view/video_watch_view/video_list_view.dart';
import 'package:alphatron_app/view/ws_streaming/video_stream_view2.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'dart:developer' as developer;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'AlphaTron App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/root',
      getPages: [
        GetPage(name: '/root', page: () => VideoStream()),
        // GetPage(name: '/google_sign_in_view', page: () => SignInPage()),
        // GetPage(name: '/user_info_page', page: () => UserInfoPage()),
        GetPage(name: '/video_list', page: () => VideoListView()),
      ],
      home: VideoStream(),
    );
  }
}
