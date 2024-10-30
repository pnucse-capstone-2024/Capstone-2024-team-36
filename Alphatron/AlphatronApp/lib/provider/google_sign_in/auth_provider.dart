// import 'package:get/get.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import '../../model/google_sign_in/user_model.dart';
//
// class AuthController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//
//   Rx<UserModel?> _user = Rx<UserModel?>(null);
//   UserModel? get user => _user.value;
//
//   @override
//   void onInit() {
//     super.onInit();
//     _auth.authStateChanges().listen((User? firebaseUser) {
//       if (firebaseUser != null) {
//         _user.value = UserModel.fromFirebaseUser(firebaseUser);
//       } else {
//         _user.value = null;
//       }
//     });
//   }
//
//   Future<bool> signInWithGoogle() async {
//     try {
//       print('Starting Google Sign In process');
//       final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
//       if (googleSignInAccount != null) {
//         print('Google Sign In account obtained');
//         final GoogleSignInAuthentication googleSignInAuthentication =
//             await googleSignInAccount.authentication;
//
//         final AuthCredential credential = GoogleAuthProvider.credential(
//           accessToken: googleSignInAuthentication.accessToken,
//           idToken: googleSignInAuthentication.idToken,
//         );
//
//         final UserCredential authResult = await _auth.signInWithCredential(credential);
//         final User? user = authResult.user;
//
//         if (user != null) {
//           print('Sign In successful. User: ${user.displayName}');
//           return true;
//         }
//       }
//     } catch (error) {
//       print('Error during Google Sign In: $error');
//     }
//     return false;
//   }
//
//   Future<void> signOut() async {
//     await _auth.signOut();
//     await _googleSignIn.signOut();
//   }
// }