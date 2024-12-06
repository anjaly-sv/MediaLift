import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'homepage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "login",
      options: FirebaseOptions(
        apiKey: "AIzaSyDJZxE7AMlTaLN2RRCecKrfFdQXBAKv9DI",
        appId: "1:581072122193:android:7f72c5d9a2bbd68fcca370",
        messagingSenderId: "581072122193",
        projectId: "trial-1db6e",
        storageBucket: "trial-1db6e.appspot.com",
      ),
    );
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
