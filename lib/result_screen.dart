import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final dynamic product;

  const ResultScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Result")),
      body: Center(
        child: Text(
          "hi",
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
