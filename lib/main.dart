import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'screens/loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Immersive, edge-to-edge night look.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const YardflareApp());
}

class YardflareApp extends StatelessWidget {
  const YardflareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yardflare Rally',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const LoadingScreen(),
    );
  }
}
