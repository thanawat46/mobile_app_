import 'package:flutter/material.dart';

import 'Login/LoginPage.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "App",
      home: const LoginPage(),
    );
  }
}

