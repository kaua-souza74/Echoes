import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/screens/world_flow_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const EchoesApp());
}

class EchoesApp extends StatelessWidget {
  const EchoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECHOES — O Despertar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff84d9e8),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff080e19),
      ),
      home: const WorldFlowScreen(),
    );
  }
}
