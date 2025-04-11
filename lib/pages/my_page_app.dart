import 'package:flutter/material.dart';

class MyPageApp extends StatelessWidget {
  const MyPageApp({super.key});

  @override
  Widget build(BuildContext context) {
    double largura = 100;
    double altura = 100;

    return Scaffold(
      body: Column(
        children: [
          Container(
          width: largura,
          height: altura,
          color: Colors.red,
        ),
        ]
      ),
    );
  }
}
