import 'package:flutter/material.dart';

import 'src/presentation/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tockee',
      theme: ThemeData(        
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 30, 99, 163)),
      ),
      home: const HomeScreen(),
    );
  }
}
