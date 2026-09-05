import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/home/worker_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client for Realtime dispatch events (Decision W-D07)
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10,
      ),
    );
    debugPrint('Supabase initialized successfully for MakkalSevai Worker.');
  } catch (e) {
    debugPrint('Supabase initialization warning (continuing with REST): $e');
  }

  runApp(const MakkalSevaiWorkerApp());
}

class MakkalSevaiWorkerApp extends StatelessWidget {
  const MakkalSevaiWorkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MakkalSevai Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WorkerHomeScreen(),
    );
  }
}
