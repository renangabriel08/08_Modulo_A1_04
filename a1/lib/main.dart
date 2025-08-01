import 'package:a1/pages/genius.dart';
import 'package:a1/pages/home.dart';
import 'package:a1/pages/memo.dart';
import 'package:a1/pages/quiz.dart';
import 'package:a1/styles/cores.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Cores.azulClaro),
      ),
      routes: {
        '/home': (context) => const Home(),
        '/genius': (context) => const Genius(),
        '/memo': (context) => const Memo(),
        '/quiz': (context) => const Quiz(),
      },
      initialRoute: '/home',
    );
  }
}
