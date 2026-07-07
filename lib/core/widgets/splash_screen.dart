import 'dart:ui';

import 'package:coffee_app/core/di/app_startup.dart';
import 'package:coffee_app/core/theme/app_colors.dart';
import 'package:coffee_app/features/ai_assistant/models/chat_message.dart';
import 'package:coffee_app/features/ai_assistant/models/conversation.dart';
import 'package:coffee_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:coffee_app/features/inventory/data/models/stock_movement_model.dart';
import 'package:coffee_app/features/profile/data/models/profile_model.dart';
import 'package:coffee_app/features/sales/data/models/product_model.dart';
import 'package:coffee_app/features/sales/data/models/recipe_model.dart';
import 'package:coffee_app/features/sales/data/models/sale_item_model.dart';
import 'package:coffee_app/features/sales/data/models/sale_transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ── Initialization step labels ────────────────────────────────────────────────

const _kSteps = [
  (label: 'Warming up the espresso machine…', fraction: 0.10),
  (label: 'Calibrating the grinder…', fraction: 0.20),
  (label: 'Syncing your coffee data…', fraction: 0.30),
  (label: 'Brewing your workspace…', fraction: 0.55),
  (label: 'Configuring premium services…', fraction: 0.75),
  (label: 'Every cup, perfectly crafted.', fraction: 1.00),
];

// ── SplashScreen ──────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitialized;
  const SplashScreen({Key? key, required this.onInitialized}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusLabel = _kSteps.first.label;
  double _progress = 0.0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  void _setStep(int stepIndex) {
    if (!mounted || stepIndex >= _kSteps.length) return;
    setState(() {
      _statusLabel = _kSteps[stepIndex].label;
      _progress = _kSteps[stepIndex].fraction;
    });
  }

  Future<void> _initializeApp() async {
    try {
      _setStep(0);
      // Hive.initFlutter() is already called once in main() — do NOT call again.

      _setStep(1);

      // Register ALL adapters exactly once, with guards to prevent duplicates.
      // AI
      if (!Hive.isAdapterRegistered(6))
        Hive.registerAdapter(ChatMessageAdapter());
      if (!Hive.isAdapterRegistered(7))
        Hive.registerAdapter(ConversationAdapter());

      // Inventory
      if (!Hive.isAdapterRegistered(0))
        Hive.registerAdapter(InventoryItemModelAdapter());
      if (!Hive.isAdapterRegistered(1))
        Hive.registerAdapter(StockMovementModelAdapter());
      if (!Hive.isAdapterRegistered(2))
        Hive.registerAdapter(MovementTypeModelAdapter());

      // Sales & Products
      if (!Hive.isAdapterRegistered(13))
        Hive.registerAdapter(ProductModelAdapter());
      if (!Hive.isAdapterRegistered(12))
        Hive.registerAdapter(ProductCategoryModelAdapter());
      if (!Hive.isAdapterRegistered(11))
        Hive.registerAdapter(RecipeModelAdapter());
      if (!Hive.isAdapterRegistered(10))
        Hive.registerAdapter(RecipeIngredientModelAdapter());
      if (!Hive.isAdapterRegistered(14))
        Hive.registerAdapter(SaleItemModelAdapter());
      if (!Hive.isAdapterRegistered(15))
        Hive.registerAdapter(SaleTransactionModelAdapter());

      // Profile
      if (!Hive.isAdapterRegistered(30))
        Hive.registerAdapter(ProfileModelAdapter());

      _setStep(2);
      await _migrateInventoryBoxIfNeeded();

      _setStep(3);
      // Open all boxes with corruption recovery.
      // If a box was written by a broken adapter, delete it and reopen empty.
      await _safeOpenBox<InventoryItemModel>('inventory_v2');
      await _safeOpenBox<StockMovementModel>('movements_v2');
      await _safeOpenBox<SaleTransactionModel>('sales_transactions');
      await _safeOpenBox<RecipeModel>('recipes');
      await _safeOpenBox<Conversation>('ai_conversations');
      await _safeOpenBox<ProductModel>('products');
      await _safeOpenBox<ProductCategoryModel>('categories');
      await _safeOpenBox<dynamic>('authBox');
      await _safeOpenBox<ProfileModel>('profile_box');

      _setStep(4);
      await appStartup();

      _setStep(5);

      // Brief pause so the final message is readable
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) widget.onInitialized();
    } catch (e) {
      if (mounted) {
        setState(() => _statusLabel = 'Initialization failed: $e');
      }
      debugPrint('Initialization Error: $e');
    }
  }
  // ── Safe box opener (handles corrupted data) ─────────────────────────────

  /// Opens a Hive box safely. If the box contains corrupted data (e.g. from
  /// a previously broken adapter), it deletes the box and reopens it empty.
  Future<Box<T>> _safeOpenBox<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      debugPrint(
          '[Hive] Box "$boxName" is corrupted: $e — deleting and recreating.');
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }

  // ── Data migration (unchanged business logic) ─────────────────────────────

  Future<void> _migrateInventoryBoxIfNeeded() async {
    const boxName = 'inventory_v2';
    if (!await Hive.boxExists(boxName)) return;

    try {
      final rawBox = await Hive.openBox<dynamic>(boxName);
      bool needsMigration = false;
      try {
        for (final value in rawBox.values) {
          if (value is Map) {
            final price = value['price'];
            final qty = value['quantity'];
            if (price is String || qty is String) {
              needsMigration = true;
              break;
            }
          }
        }
      } catch (e) {
        // Values are corrupted — delete the entire box
        debugPrint(
            '[Migration] inventory_v2 data is corrupted: $e — deleting box.');
        await rawBox.close();
        await Hive.deleteBoxFromDisk(boxName);
        return;
      }
      if (!needsMigration) {
        await rawBox.close();
        return;
      }

      debugPrint('[Migration] inventory_v2 needs type migration — fixing…');
      final rawSnapshot = Map<dynamic, dynamic>.from(rawBox.toMap());
      await rawBox.close();

      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }

      if (await Hive.boxExists(boxName)) {
        await Hive.deleteBoxFromDisk(boxName);
      }

      final typedBox = await Hive.openBox<InventoryItemModel>(boxName);
      for (final entry in rawSnapshot.entries) {
        final raw = entry.value;
        if (raw is! Map) continue;
        final model = InventoryItemModel(
          id: _str(raw['id']) ?? '',
          sku: _str(raw['sku']) ?? _str(raw['id']) ?? '',
          name: _str(raw['name']) ?? '',
          quantity: _dbl(raw['quantity'] ?? raw['current_quantity']),
          minThreshold: _int(raw['minThreshold'] ?? raw['minimum_threshold']),
          unit: _str(raw['unit']) ?? 'piece',
          price: _dbl(raw['price'] ?? raw['cost_per_unit']),
        );
        await typedBox.put(entry.key, model);
      }
      await typedBox.close();
      debugPrint('[Migration] inventory_v2 migration complete.');
    } catch (e) {
      debugPrint('[Migration] inventory_v2 migration skipped: $e');
    }
  }

  static double _dbl(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String? _str(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cinematic background ─────────────────────────────────────────
          Image.asset('assets/images/barista2.jpg', fit: BoxFit.cover),
          Container(
            decoration:
                const BoxDecoration(gradient: AppColors.cinematicOverlay),
          ),
          // Soft bottom blur for content readability
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 300,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
          ),

          // ── Animated content ─────────────────────────────────────────────
          SafeArea(
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 3),

                      // Logo badge
                      _CoffeeLogo(),

                      const SizedBox(height: 20),

                      // App title
                      Text(
                        'Coffee Bar',
                        style: GoogleFonts.inter(
                          color: AppColors.cream,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium Coffee Management',
                        style: GoogleFonts.inter(
                          color: AppColors.latte.withOpacity(0.75),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Status & progress
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: Text(
                          _statusLabel,
                          key: ValueKey(_statusLabel),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.latte.withOpacity(0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Caramel progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 3,
                            backgroundColor: AppColors.darkBorder,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.caramel),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Coffee Logo Badge ─────────────────────────────────────────────────────────

class _CoffeeLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: AppColors.coffeeGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.caramel.withOpacity(0.45),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.coffee, color: AppColors.cream, size: 44),
    );
  }
}
