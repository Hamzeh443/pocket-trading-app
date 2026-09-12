import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: PocketApp(), debugShowCheckedModeBanner: false));

class PocketApp extends StatelessWidget {
  const PocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pocket Option Bot'), backgroundColor: Colors.indigo),
      body: const Center(child: Text('تطبيق التداول جاهز للبناء!', style: TextStyle(fontSize: 20))),
    );
  }
}
