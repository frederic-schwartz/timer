import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'src/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('fr', ''), // French
        Locale('es', ''), // Spanish
        Locale('de', ''), // German
        Locale('it', ''), // Italian
        Locale('pt', ''), // Portuguese
        Locale('nl', ''), // Dutch
        Locale('ru', ''), // Russian
        Locale('ja', ''), // Japanese
        Locale('ko', ''), // Korean
        Locale('zh', ''), // Chinese
        Locale('ar', ''), // Arabic
      ],
      home: const HomeScreen(),
    );
  }
}
