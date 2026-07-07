import 'package:coffee_app/auth/providers/auth_provider.dart';
import 'package:coffee_app/auth/screens/role_selection_screen.dart';
import 'package:coffee_app/core/app_root.dart';
import 'package:coffee_app/core/di/service_locator.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/locale_cubit.dart';
import 'package:coffee_app/core/theme/app_theme.dart';
import 'package:coffee_app/core/widgets/splash_screen.dart';
import 'package:coffee_app/features/ai_assistant/cubit/ai_history_cubit.dart';
import 'package:coffee_app/features/ai_assistant/data/ai_assistant_repository.dart';
import 'package:coffee_app/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/pages/dashboard_page.dart';
import 'package:coffee_app/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:coffee_app/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:coffee_app/features/sales/domain/repositories/recipe_repository_interface.dart';
import 'package:coffee_app/features/sales/domain/repositories/sales_repository.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/sales_cubit.dart';
import 'package:coffee_app/features/settings/presentation/bloc/settings_bloc.dart'
    as legacy_settings;
import 'package:coffee_app/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:coffee_app/features/settings/presentation/cubit/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const AppStarter());
}

class AppStarter extends StatefulWidget {
  const AppStarter({super.key});

  @override
  State<AppStarter> createState() => _AppStarterState();
}

class _AppStarterState extends State<AppStarter> {
  bool _isInitialized = false;
  late final AuthProvider _authProvider;
  late final AiAssistantRepository _aiAssistantRepository;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          onInitialized: () {
            setState(() {
              _authProvider = AuthProvider();
              _authProvider.initialize();
              _aiAssistantRepository = AiAssistantRepository();
              _isInitialized = true;
            });
          },
        ),
      );
    }

    return MyApp(
      authProvider: _authProvider,
      inventoryRepository: sl<InventoryRepository>(),
      salesRepository: sl<SalesRepository>(),
      aiAssistantRepository: _aiAssistantRepository,
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final InventoryRepository inventoryRepository;
  final SalesRepository salesRepository;
  final AiAssistantRepository aiAssistantRepository;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.inventoryRepository,
    required this.salesRepository,
    required this.aiAssistantRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
      ],
      child: RepositoryProvider.value(
        value: aiAssistantRepository,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<SettingsCubit>(
              create: (context) => sl<SettingsCubit>()..initialize(),
            ),
            BlocProvider<NotificationCubit>(
              create: (context) => NotificationCubit(
                service: sl(),
                lowStockNotified: sl(),
                salesRepository: salesRepository,
                settingsCubit: context.read<SettingsCubit>(),
              ),
            ),
            BlocProvider<InventoryCubit>(
              create: (context) => InventoryCubit(
                repository: inventoryRepository,
                notificationCubit: context.read<NotificationCubit>(),
              ),
              // Note: InventoryCubit initializes loading automatically in constructor
              // Emits: Loading → (Loaded | Empty) or Loading → stream subscription
            ),
            BlocProvider<SalesCubit>(
              create: (context) => sl<SalesCubit>(
                param1: context.read<InventoryCubit>(),
                param2: context.read<NotificationCubit>(),
              ),
              // Note: SalesCubit initializes loading automatically in constructor
              // Emits: Loading → (Loaded | Error) with initial sales/recipes
            ),
            BlocProvider<RecipesCubit>(
              create: (context) => RecipesCubit(
                repository: sl<RecipeRepository>(),
                inventoryRepository: inventoryRepository,
              ),
              // Note: RecipesCubit initializes loading automatically in constructor
            ),
            BlocProvider<ReportsCubit>(
              create: (context) => ReportsCubit(
                salesRepository: salesRepository,
                inventoryCubit: context.read<InventoryCubit>(),
              ),
              // Note: ReportsCubit initializes loading automatically in constructor
              // Emits: Loading → (Loaded | Error) with default date range
            ),
            BlocProvider<legacy_settings.SettingsBloc>(
              create: (context) => legacy_settings.SettingsBloc(),
            ),
            BlocProvider<ThemeCubit>(
              create: (context) => ThemeCubit(),
            ),
            BlocProvider<LocaleCubit>(
              create: (context) => LocaleCubit(sl())..getSavedLanguage(),
            ),
            BlocProvider<AiHistoryCubit>(
              create: (context) =>
                  AiHistoryCubit(repository: aiAssistantRepository)
                    ..loadConversations(),
            ),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, localeState) {
                  return MaterialApp(
                    title: 'Coffee App',
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeState.locale,
                    supportedLocales: const [Locale('en'), Locale('ar')],
                    localizationsDelegates: const [
                      JsonLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    routes: {
                      '/home': (context) =>
                          const AppRoot(child: PremiumDashboardPage()),
                      '/role-selection': (context) =>
                          const AppRoot(child: RoleSelectionScreen()),
                    },
                    localeResolutionCallback: (deviceLocale, supportedLocales) {
                      for (final locale in supportedLocales) {
                        if (locale.languageCode == deviceLocale?.languageCode) {
                          return locale;
                        }
                      }
                      return localeState.locale;
                    },
                    home: Builder(
                      builder: (context) {
                        final authProvider = context.watch<AuthProvider>();
                        if (authProvider.loggedIn) {
                          return const AppRoot(child: PremiumDashboardPage());
                        }

                        return const AppRoot(child: RoleSelectionScreen());
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
      


                      // const SizedBox(height: 16),
                // TextFormField(
                //   controller: _catCtrl,
                //   decoration: InputDecoration(
                //     labelText: context.tr(LangKeys.category),
                //     border: const OutlineInputBorder(),
                //     prefixIcon: const Icon(Icons.category),
                //   ),
                //   validator: (v) => v == null || v.isEmpty
                //       ? context.tr(LangKeys.category_required)
                //       : null,
                //   enabled: !_isSubmitting,
                // ),