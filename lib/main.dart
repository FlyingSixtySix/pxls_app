import 'package:flutter/material.dart';

import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'screens/home.dart';

void main() {
  runApp(
      Phoenix(
        child: const PxlsApp(),
      ),
  );
}

class PxlsApp extends StatelessWidget {
  const PxlsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pxls.space',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(title: 'pxls.space'),
      debugShowCheckedModeBanner: false,
    );
  }
}
