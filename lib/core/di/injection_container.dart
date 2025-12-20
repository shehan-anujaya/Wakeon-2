/// Dependency Injection Container
/// 
/// Configures and provides all dependencies using GetIt service locator.

import 'package:get_it/get_it.dart';

import '../../data/datasources/camera_datasource.dart';
import '../../data/datasources/settings_datasource.dart';
import '../../data/repositories/drowsiness_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../data/services/alert_service.dart';
import '../../data/services/tflite_service.dart';
import '../../domain/repositories/drowsiness_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/analyze_frame_usecase.dart';
import '../utils/performance_utils.dart';

final getIt = GetIt.instance;

/// Configure all dependencies
Future<void> configureDependencies() async {
  // ===== Core Services =====
  
  // Performance utilities
  getIt.registerLazySingleton<FrameRateController>(
    () => FrameRateController(),
  );
  
  getIt.registerLazySingleton<InferenceTimer>(
    () => InferenceTimer(),
  );
  
  getIt.registerLazySingleton<BatteryAwareManager>(
    () => BatteryAwareManager(),
  );
  
  // ===== Data Sources =====
  
  getIt.registerLazySingleton<CameraDataSource>(
    () => CameraDataSourceImpl(),
  );
  
  getIt.registerLazySingleton<SettingsDataSource>(
    () => SettingsDataSourceImpl(),
  );
  
  // ===== Services =====
  
  // TensorFlow Lite service for model inference
  getIt.registerLazySingleton<TFLiteService>(() => TFLiteService());
  
  // Alert service for audio/haptic feedback
  getIt.registerLazySingleton<AlertService>(() => AlertService());
  
  // ===== Repositories =====
  
  getIt.registerLazySingleton<DrowsinessRepository>(
    () => DrowsinessRepositoryImpl(
      cameraDataSource: getIt(),
      tfliteService: getIt(),
    ),
  );
  
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      dataSource: getIt(),
    ),
  );
  
  // ===== Use Cases =====
  
  getIt.registerLazySingleton<AnalyzeFrameUseCase>(
    () => AnalyzeFrameUseCase(
      repository: getIt(),
    ),
  );
}

/// Dispose all services that need cleanup
Future<void> disposeDependencies() async {
  if (getIt.isRegistered<TFLiteService>()) {
    await getIt<TFLiteService>().dispose();
  }
  if (getIt.isRegistered<AlertService>()) {
    await getIt<AlertService>().dispose();
  }
  await getIt.reset();
}
