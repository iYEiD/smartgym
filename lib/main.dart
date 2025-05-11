import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartgymai/core/config/app_config.dart';
import 'package:smartgymai/core/theme/app_theme.dart';
import 'package:smartgymai/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize app configuration
  final appConfig = AppConfig();
  await appConfig.initialize();
  
  runApp(
    const ProviderScope(
      child: SmartGymApp(),
    ),
  );
}

class SmartGymApp extends ConsumerWidget {
  const SmartGymApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Smart Gym AI',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
