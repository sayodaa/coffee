import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fixed list of measurement units offered in the Unit dropdown.
const List<String> kUnitOptions = [
  'kg',
  'g',
  'mg',
  'L',
  'mL',
  'pcs',
  'pack',
  'box',
  'bag',
  'bottle',
  'can',
  'cup',
  'tbsp',
  'tsp',
];

class InventoryFormPage extends StatefulWidget {
  final InventoryItem? initialItem;

  const InventoryFormPage({super.key, this.initialItem});

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _skuCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _catCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _minCtrl;
  late TextEditingController _unitCtrl;
  late TextEditingController _priceCtrl;

  String? _selectedUnit;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _skuCtrl = TextEditingController(text: widget.initialItem?.sku ?? '');
    _nameCtrl = TextEditingController(text: widget.initialItem?.name ?? '');
    _catCtrl = TextEditingController();
    _qtyCtrl = TextEditingController(
        text: widget.initialItem?.quantity.toString() ?? '');
    _minCtrl = TextEditingController(
        text: widget.initialItem?.minThreshold.toString() ?? '');
    _unitCtrl = TextEditingController(text: widget.initialItem?.unit ?? '');
    _priceCtrl =
        TextEditingController(text: widget.initialItem?.price.toString() ?? '');

    final initialUnit = widget.initialItem?.unit;
    if (initialUnit != null && initialUnit.isNotEmpty) {
      _selectedUnit = initialUnit;
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _catCtrl.dispose();
    _qtyCtrl.dispose();
    _minCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  /// Turns an ingredient's English name into a simple, readable SKU/ID,
  /// e.g. "Whole Milk" -> "WHOLE-MILK".
  String _generateSkuFromName(String enName) {
    final cleaned = enName
        .replaceAll(RegExp(r'[^A-Za-z0-9\s]'), '') // strip punctuation
        .trim()
        .toUpperCase();
    final parts =
        cleaned.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    return parts.join('-');
  }

  void _regenerateSku() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _skuCtrl.text = _generateSkuFromName(_nameCtrl.text);
    });
  }

  void _submit() {
    // Sync the unit controller with the dropdown selection before
    // validation/build so downstream logic keeps working unchanged.
    _unitCtrl.text = _selectedUnit ?? '';

    if (_formKey.currentState?.validate() ?? false) {
      final item = InventoryItem(
        id: widget.initialItem?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        sku: _skuCtrl.text,
        name: _nameCtrl.text,
        quantity: double.tryParse(_qtyCtrl.text) ?? 0.0,
        minThreshold: int.tryParse(_minCtrl.text) ?? 0,
        unit: _unitCtrl.text,
        price: double.tryParse(_priceCtrl.text) ?? 0.0,
      );

      setState(() => _isSubmitting = true);

      if (widget.initialItem == null) {
        context.read<InventoryCubit>().addInventoryItem(item);
      } else {
        context.read<InventoryCubit>().updateInventoryItem(item);
      }
    }
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
    String? suffixText,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      prefixIcon: Icon(icon, size: 22),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionSpacer() => const SizedBox(height: 28);
  Widget _fieldSpacer() => const SizedBox(height: 16);

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final title = _isEditing
        ? context.tr(LangKeys.edit_material_title)
        : context.tr(LangKeys.add_material_title);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isEditing ? Icons.edit_note_rounded : Icons.inventory_2_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing
                      ? context.tr(LangKeys.edit_material_title)
                      : context.tr(LangKeys.add_material_title),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitDropdown(BuildContext context) {
    // Guard against an initial/edit value that isn't part of the fixed
    // list — include it so the dropdown never crashes on an unknown value.
    final options = [...kUnitOptions];
    if (_selectedUnit != null && !options.contains(_selectedUnit)) {
      options.add(_selectedUnit!);
    }

    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded),
      borderRadius: BorderRadius.circular(14),
      decoration: _decoration(
        context,
        label: context.tr(LangKeys.unit),
        icon: Icons.straighten,
        hint: context.tr(LangKeys.unit_hint),
      ),
      items: options
          .map(
            (u) => DropdownMenuItem<String>(
              value: u,
              child: Text(u),
            ),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() {
                _selectedUnit = value;
                _unitCtrl.text = value ?? '';
              });
            },
      validator: (v) =>
          v == null || v.isEmpty ? context.tr(LangKeys.unit_required) : null,
    );
  }

  Widget _saveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          _isSubmitting
              ? context.tr(LangKeys.saving)
              : context.tr(LangKeys.save),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<InventoryCubit, InventoryState>(
      // Only react while we're in the middle of a submission
      listenWhen: (_, __) => true,
      listener: (context, state) {
        if (!_isSubmitting) return;

        if (state is InventoryLoaded || state is InventoryEmpty) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.initialItem == null
                          ? context.tr(LangKeys.item_added_success)
                          : context.tr(LangKeys.item_updated_success),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
            ),
          );
          if (mounted) Navigator.pop(context);
        } else if (state is InventoryError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              content: Row(
                children: [
                  const Icon(Icons.error_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(widget.initialItem == null
              ? context.tr(LangKeys.add_material_title)
              : context.tr(LangKeys.edit_material_title)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _header(context),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── General Information ──────────────────────
                        _sectionTitle(
                          context,
                          context.tr(LangKeys.name),
                          Icons.info_outline_rounded,
                        ),
                        IngredientNameField(
                          controller: _nameCtrl,
                          labelText: context.tr(LangKeys.name),
                          validator: (v) => v == null || v.isEmpty
                              ? context.tr(LangKeys.name_required)
                              : null,
                          enabled: !_isSubmitting,
                          decorationBuilder: (label, icon) => _decoration(
                            context,
                            label: label,
                            icon: icon,
                          ),
                          onIngredientSelected: (opt) {
                            if (_skuCtrl.text.trim().isEmpty) {
                              setState(() {
                                _skuCtrl.text = _generateSkuFromName(opt.en);
                              });
                            }
                          },
                        ),
                        _fieldSpacer(),
                        TextFormField(
                          controller: _skuCtrl,
                          readOnly: true,
                          enabled: !_isSubmitting,
                          decoration: _decoration(
                            context,
                            label: context.tr(LangKeys.id),
                            icon: Icons.code_rounded,
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? context.tr(LangKeys.sku_required)
                              : null,
                        ),

                        _sectionSpacer(),
                        Divider(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 20),

                        // ── Inventory ─────────────────────────────────
                        _sectionTitle(
                          context,
                          context.tr(LangKeys.quantity),
                          Icons.inventory_rounded,
                        ),
                        TextFormField(
                          controller: _qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          enabled: !_isSubmitting,
                          decoration: _decoration(
                            context,
                            label: context.tr(LangKeys.quantity),
                            icon: Icons.numbers_rounded,
                            suffixText: _selectedUnit,
                          ),
                          validator: (v) => v == null || int.tryParse(v) == null
                              ? context.tr(LangKeys.invalid_quantity)
                              : null,
                        ),
                        TextFormField(
                          controller: _minCtrl,
                          keyboardType: TextInputType.number,
                          enabled: !_isSubmitting,
                          decoration: _decoration(
                            context,
                            label: context.tr(LangKeys.min_threshold),
                            icon: Icons.notifications_active_rounded,
                          ),
                          validator: (v) => v == null || int.tryParse(v) == null
                              ? context.tr(LangKeys.invalid_threshold)
                              : null,
                        ),
                        _fieldSpacer(),
                        _unitDropdown(context),

                        _sectionSpacer(),
                        Divider(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 20),

                        // ── Pricing ───────────────────────────────────
                        _sectionTitle(
                          context,
                          context.tr(LangKeys.price),
                          Icons.payments_rounded,
                        ),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          enabled: !_isSubmitting,
                          decoration: _decoration(
                            context,
                            label: context.tr(LangKeys.price),
                            icon: Icons.attach_money_rounded,
                            suffixText: 'EGP',
                          ),
                          validator: (v) =>
                              v == null || double.tryParse(v) == null
                                  ? context.tr(LangKeys.invalid_price)
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _saveButton(context),
                const SizedBox(height: 120), // Bottom padding for GlassNavBar
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single ingredient entry with English + Arabic names.
class IngredientOption {
  final String en;
  final String ar;
  const IngredientOption(this.en, this.ar);
}

/// Built-in library of common café/drink ingredients.
/// Edit/extend this list freely — it's just plain data.
const List<IngredientOption> kIngredientLibrary = [
  // ── Dairy ──────────────────────────────────────────────
  IngredientOption('Whole Milk', 'لبن كامل الدسم'),
  IngredientOption('Skimmed Milk', 'لبن خالي الدسم'),
  IngredientOption('Condensed Milk', 'لبن مكثف محلى'),
  IngredientOption('Evaporated Milk', 'لبن مبخر'),
  IngredientOption('Cream', 'كريمة'),
  IngredientOption('Whipped Cream', 'كريمة مخفوقة'),
  IngredientOption('Oat Milk', 'حليب الشوفان'),
  IngredientOption('Almond Milk', 'حليب اللوز'),
  IngredientOption('Coconut Milk', 'حليب جوز الهند'),

  // ── Coffee ─────────────────────────────────────────────
  IngredientOption('Arabica Coffee Beans', 'بن أرابيكا'),
  IngredientOption('Robusta Coffee Beans', 'بن روبوستا'),
  IngredientOption('Espresso Beans', 'بن إسبريسو'),
  IngredientOption('Instant Coffee', 'قهوة سريعة الذوبان'),
  IngredientOption('Turkish Coffee Ground', 'قهوة تركي مطحونة'),
  IngredientOption('Decaf Coffee', 'قهوة منزوعة الكافيين'),

  // ── Tea ────────────────────────────────────────────────
  IngredientOption('Black Tea', 'شاي أسود'),
  IngredientOption('Green Tea', 'شاي أخضر'),
  IngredientOption('Mint Tea', 'شاي بالنعناع'),
  IngredientOption('Chamomile Tea', 'شاي بابونج'),
  IngredientOption('Hibiscus (Karkade)', 'كركديه'),
  IngredientOption('Matcha Powder', 'مسحوق ماتشا'),

  // ── Sweeteners ─────────────────────────────────────────
  IngredientOption('White Sugar', 'سكر أبيض'),
  IngredientOption('Brown Sugar', 'سكر بني'),
  IngredientOption('Powdered Sugar', 'سكر بودرة'),
  IngredientOption('Honey', 'عسل'),
  IngredientOption('Molasses', 'عسل أسود'),
  IngredientOption('Simple Syrup', 'شراب سكر بسيط'),
  IngredientOption('Caramel Syrup', 'شراب كراميل'),
  IngredientOption('Vanilla Syrup', 'شراب فانيليا'),
  IngredientOption('Hazelnut Syrup', 'شراب بندق'),
  IngredientOption('Chocolate Syrup', 'شراب شوكولاتة'),

  // ── Citrus & Fruits ────────────────────────────────────
  IngredientOption('Lemon', 'ليمون'),
  IngredientOption('Orange', 'برتقال'),
  IngredientOption('Mandarin', 'يوسفي'),
  IngredientOption('Lime', 'ليمون أخضر'),
  IngredientOption('Strawberry', 'فراولة'),
  IngredientOption('Banana', 'موز'),
  IngredientOption('Mango', 'مانجو'),
  IngredientOption('Pineapple', 'أناناس'),
  IngredientOption('Kiwi', 'كيوي'),
  IngredientOption('Watermelon', 'بطيخ'),
  IngredientOption('Grape', 'عنب'),
  IngredientOption('Peach', 'خوخ'),
  IngredientOption('Blueberry', 'توت أزرق'),
  IngredientOption('Raspberry', 'توت العليق'),
  IngredientOption('Passion Fruit', 'فاكهة العشق'),
  IngredientOption('Guava', 'جوافة'),
  IngredientOption('Pomegranate', 'رمان'),
  IngredientOption('Apple', 'تفاح'),
  IngredientOption('Dates', 'تمر'),

  // ── Spices & Flavorings ────────────────────────────────
  IngredientOption('Cinnamon', 'قرفة'),
  IngredientOption('Cocoa Powder', 'كاكاو بودرة'),
  IngredientOption('Cardamom', 'هيل'),
  IngredientOption('Ginger', 'زنجبيل'),
  IngredientOption('Nutmeg', 'جوزة الطيب'),
  IngredientOption('Cloves', 'قرنفل'),
  IngredientOption('Vanilla Extract', 'خلاصة فانيليا'),
  IngredientOption('Rose Water', 'ماء ورد'),
  IngredientOption('Orange Blossom Water', 'ماء زهر'),
  IngredientOption('Mastic (Mistika)', 'مستكة'),
  IngredientOption('Mint Leaves', 'أوراق نعناع'),
  IngredientOption('Turmeric', 'كركم'),
  IngredientOption('Salt', 'ملح'),

  // ── Bases & Others ─────────────────────────────────────
  IngredientOption('Water', 'مياه'),
  IngredientOption('Ice', 'ثلج'),
  IngredientOption('Soda Water', 'مياه غازية'),
  IngredientOption('Chocolate Bar/Chips', 'شوكولاتة'),
  IngredientOption('Marshmallow', 'مارشميلو'),
  IngredientOption('Biscuit Crumble', 'بسكويت مطحون'),
  IngredientOption('Almonds', 'لوز'),
  IngredientOption('Walnuts', 'جوز'),
  IngredientOption('Pistachio', 'فستق'),
  IngredientOption('Hazelnut', 'بندق'),
  IngredientOption('Coconut Flakes', 'رقائق جوز الهند'),
  IngredientOption('Oats', 'شوفان'),
  IngredientOption('Granola', 'جرانولا'),
  IngredientOption('Cornstarch', 'نشا'),
];

/// A searchable name field: suggests from [kIngredientLibrary] (matching
/// either English or Arabic text as the user types) but still lets the
/// user type any free-text name that isn't in the list.
///
/// Wraps an existing [controller] directly, so it drops in wherever a
/// plain TextFormField used to be — validators, enabled state, etc. all
/// keep working the same way.
///
/// [onIngredientSelected] fires whenever the user taps a suggestion (not
/// on free-text entry), so the caller can react — e.g. auto-fill another
/// field from the picked ingredient.
class IngredientNameField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final ValueChanged<IngredientOption>? onIngredientSelected;
  final InputDecoration Function(String label, IconData icon)?
      decorationBuilder;

  const IngredientNameField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.enabled = true,
    this.onIngredientSelected,
    this.decorationBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<IngredientOption>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim();
        if (query.isEmpty) return const Iterable<IngredientOption>.empty();
        final lowerQuery = query.toLowerCase();
        return kIngredientLibrary.where((opt) {
          return opt.en.toLowerCase().contains(lowerQuery) ||
              opt.ar.contains(query);
        }).take(20);
      },
      displayStringForOption: (opt) => opt.en,
      onSelected: (opt) {
        controller.text = opt.en;
        onIngredientSelected?.call(opt);
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: decorationBuilder != null
              ? decorationBuilder!(labelText, Icons.local_cafe_outlined)
              : InputDecoration(
                  labelText: labelText,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.local_cafe_outlined),
                ),
          validator: validator,
          onFieldSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionsList = options.toList();
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, minWidth: 300),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: optionsList.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                itemBuilder: (context, index) {
                  final opt = optionsList[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.local_cafe_rounded,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      opt.en,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      opt.ar,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => onSelected(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
