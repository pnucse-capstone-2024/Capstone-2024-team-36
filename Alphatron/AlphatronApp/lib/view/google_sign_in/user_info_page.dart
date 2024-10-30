// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../provider/google_sign_in/auth_provider.dart';
//
// class UserInfoPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final AuthController authController = Get.put(AuthController());
//     final user = authController.user;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('User Info'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text('Welcome, ${user?.displayName ?? ""}!'),
//             SizedBox(height: 16),
//             Text('Your email is ${user?.email ?? ""}'),
//             SizedBox(height: 16),
//             ElevatedButton(
//               child: Text('Sign Out'),
//               onPressed: () async {
//                 await authController.signOut();
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }