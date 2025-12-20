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
import 'package:wakelock/wakelock.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'presentation/bloc/drowsiness/drowsiness_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Lock to portrait mode for consistent camera feed
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Keep screen awake during driving
  await Wakelock.enable();
  
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
        BlocProvider<DrowsinessBloc>(
          create: (_) => getIt<DrowsinessBloc>(),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => getIt<SettingsBloc>()..add(LoadSettingsEvent()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'WakeOn - Driver Safety',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme, // Always dark for driver safety
            themeMode: ThemeMode.dark,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
