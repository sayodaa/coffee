import 'package:coffee_app/auth/services/auth_service.dart';
import 'package:coffee_app/core/localization/language_cache_helper.dart';
import 'package:coffee_app/features/inventory/data/repositories/hive_inventory_repository.dart';
import 'package:coffee_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/notifications/data/datasources/local_notifications_datasource.dart';
import 'package:coffee_app/features/notifications/data/datasources/low_stock_notified_local_datasource.dart';
import 'package:coffee_app/features/notifications/data/datasources/notification_dedupe_local_datasource.dart';
import 'package:coffee_app/features/notifications/data/services/notification_service.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/profile/data/datasources/profile_local_datasource.dart';
import 'package:coffee_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:coffee_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:coffee_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:coffee_app/features/sales/data/datasources/recipe_local_datasource.dart';
import 'package:coffee_app/features/sales/data/repositories/hive_sales_repository.dart';
import 'package:coffee_app/features/sales/data/repositories/recipe_repository_impl.dart';
import 'package:coffee_app/features/sales/domain/repositories/recipe_repository_interface.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:coffee_app/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:coffee_app/features/settings/domain/repositories/settings_repository.dart';
import 'package:coffee_app/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:coffee_app/features/settings/domain/usecases/save_settings_usecase.dart';
import 'package:coffee_app/features/settings/domain/usecases/watch_settings_usecase.dart';
import 'package:coffee_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;
final GetIt getIt = GetIt.instance;

Future<void> initServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Localization — must be registered before any Cubit that uses LocaleCubit
  sl.registerLazySingleton<LanguageCacheHelper>(() => LanguageCacheHelper());

  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );

  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSource(sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(local: sl()),
  );

  sl.registerLazySingleton<GetSettingsUseCase>(() => GetSettingsUseCase(sl()));
  sl.registerLazySingleton<WatchSettingsUseCase>(
    () => WatchSettingsUseCase(sl()),
  );
  sl.registerLazySingleton<SaveSettingsUseCase>(
      () => SaveSettingsUseCase(sl()));

  sl.registerFactory<SettingsCubit>(
    () => SettingsCubit(
      getSettings: sl(),
      watchSettings: sl(),
      saveSettings: sl(),
    ),
  );

  sl.registerLazySingleton<NotificationDedupeLocalDataSource>(
    () => NotificationDedupeLocalDataSource(sl()),
  );
  sl.registerLazySingleton<LocalNotificationsDataSource>(
    () => LocalNotificationsDataSource(sl()),
  );

  sl.registerLazySingleton<LowStockNotifiedLocalDataSource>(
    () => LowStockNotifiedLocalDataSource(sl()),
  );

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(sl()),
  );

  sl.registerLazySingleton<InventoryRepository>(
      () => HiveInventoryRepository());
  sl.registerLazySingleton<SalesRepository>(() => HiveSalesRepository());
  // Auth
  sl.registerLazySingleton<AuthService>(() => AuthService());

  // Recipe repository setup
  sl.registerLazySingleton<RecipeLocalDataSource>(
    () => RecipeLocalDataSource(),
  );
  sl.registerLazySingleton<RecipeRepository>(
    () => RecipeRepositoryImpl(sl<RecipeLocalDataSource>()),
  );

  sl.registerFactoryParam<SalesCubit, InventoryCubit, NotificationCubit>(
    (inventory, notification) => SalesCubit(
      salesRepository: sl<SalesRepository>(),
      inventoryCubit: inventory,
      notificationCubit: notification,
    ),
  );

  // ─── Profile ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSource(),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(localDataSource: sl()),
  );
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(repository: sl()),
  );
}
