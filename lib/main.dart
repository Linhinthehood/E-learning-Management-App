import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/app_router.dart';
import 'utils/firebase_initializer.dart';
import 'utils/hive_initializer.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseInitializer.initialize();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('💡 Make sure you have set up Firebase configuration');
  }

  // Initialize Hive for offline storage
  try {
    await HiveInitializer.initialize();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('⚠️ Hive initialization failed: $e');
  }

  // Run app with Riverpod
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Learning Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF000000)),
        useMaterial3: true,
      ),
      home: const AppRouter(),
    );
  }
}
