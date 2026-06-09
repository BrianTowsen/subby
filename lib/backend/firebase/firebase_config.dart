import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDYri9hBKk81kZN61WKC_bD99nsyGjJxbg",
            authDomain: "winston-9dy48u.firebaseapp.com",
            projectId: "winston-9dy48u",
            storageBucket: "winston-9dy48u.firebasestorage.app",
            messagingSenderId: "888223270950",
            appId: "1:888223270950:web:6657725bf7a85530637ee7"));
  } else {
    await Firebase.initializeApp();
  }
}
