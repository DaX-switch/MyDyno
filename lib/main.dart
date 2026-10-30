import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/prefs_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  runApp(const MyDynoApp());
}

class MyDynoApp extends StatelessWidget {
  const MyDynoApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'My Dyno',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepOrange, brightness: Brightness.dark),
        ),
        home: const HomeScreen(),
      );
}
