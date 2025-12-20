/// WakeOn - AI Driver Safety Assistant
/// 
/// A commercial-grade, offline AI-powered drowsiness detection system
/// optimized for real-time performance on mobile devices.
/// 
/// Author: WakeOn Team
/// Version: 1.0.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'data/services/alert_service.dart';
import 'domain/usecases/analyze_frame_usecase.dart';
import 'presentation/bloc/drowsiness_detection/drowsiness_detection_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Lock to portrait mode for consistent camera feed
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Keep screen awake during driving
  await WakelockPlus.enable();
  
  // Set system UI overlay style for dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const WakeOnApp());
}

/// Root application widget
class WakeOnApp extends StatelessWidget {
  const WakeOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DrowsinessDetectionBloc>(
          create: (_) => DrowsinessDetectionBloc(
            analyzeFrameUseCase: getIt<AnalyzeFrameUseCase>(),
            alertService: getIt<AlertService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'WakeOn - Driver Safety',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
