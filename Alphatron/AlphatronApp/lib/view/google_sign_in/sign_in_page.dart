// import 'package:alphatron_app/view/google_sign_in/user_info_page.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../provider/google_sign_in/auth_provider.dart';
//
// // TODO 1 : 로그인 과정 콘솔에 출력
// // TODO 2 : 로그인 성공 시 콘솔에 출력
// // TODO 3 : 로그인 성공 시, 구글에 요청해 사용자 정보 받아와서 콘솔에 출력
// // TODO 4 : 로그인 성공 시, 사용자 정보를 표시하는 페이지로 화면 전환
// class SignInPage extends StatelessWidget {
//   final AuthController authController = Get.put(AuthController());
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Google Sign In'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           child: Text('Sign in with Google'),
//           onPressed: () async {
//             bool success = await authController.signInWithGoogle();
//             if (success) {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => UserInfoPage(),
//                 ),
//               );
//             }
//           },
//         ),
//       ),
//     );
//   }
// }