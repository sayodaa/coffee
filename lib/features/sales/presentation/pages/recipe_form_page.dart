import 'package:coffee_app/core/domain/value_objects/money.dart';
import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/inventory/domain/entities/inventory_item.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:coffee_app/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class RecipeFormPage extends StatefulWidget {
  /// Pass an existing recipe to pre-fill the form for editing.
  /// Leave null to create a new recipe.
  final Recipe? initialRecipe;
  const RecipeFormPage({super.key, this.initialRecipe});
  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final List<RecipeIngredient> _ingredients = [];
  InventoryItem? _selectedItem;
  final _quantityController = TextEditingController();
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialRecipe != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.initialRecipe!.productName;
      _priceController.text = widget.initialRecipe!.price.amount.toString();
      _ingredients.addAll(widget.initialRecipe!.ingredients);
    }
  }

  void _addIngredient() {
    if (_selectedItem == null || _quantityController.text.isEmpty) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;

    // Prevent duplicate ingredients
    final alreadyExists =
        _ingredients.any((ing) => ing.inventoryItemId == _selectedItem!.id);
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${_selectedItem!.name} already added. Remove it first to change quantity.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _ingredients.add(RecipeIngredient(
        inventoryItemId: _selectedItem!.id,
        quantityRequiredPerUnit: quantity,
      ));
      _selectedItem = null;
      _quantityController.clear();
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _saveRecipe() {
    if (!_formKey.currentState!.validate() || _ingredients.isEmpty) {
      if (_ingredients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr(LangKeys.error_no_ingredients)),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_isEditing) {
      final updated = widget.initialRecipe!.copyWith(
        productName: _nameController.text.trim(),
        ingredients: _ingredients,
        price: Money(double.tryParse(_priceController.text) ?? 0),
        updatedAt: DateTime.now(),
      );
      _isSubmitting = true;
      context.read<RecipesCubit>().updateRecipe(updated);
    } else {
      final now = DateTime.now();
      final recipe = Recipe(
        id: const Uuid().v4(),
        productId:
            _nameController.text.trim().toLowerCase().replaceAll(' ', '_'),
        productName: _nameController.text.trim(),
        ingredients: _ingredients,
        price: Money(double.tryParse(_priceController.text) ?? 0),
        createdAt: now,
        updatedAt: now,
      );
      _isSubmitting = true;
      context.read<RecipesCubit>().addRecipe(recipe);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? context.tr(LangKeys.edit_recipe)
              : context.tr(LangKeys.new_recipe),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveRecipe,
          )
        ],
      ),
      body: BlocConsumer<RecipesCubit, RecipesState>(
        listener: (context, recipeState) {
          if (!_isSubmitting) return;

          if (recipeState is RecipesLoaded) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr(LangKeys.operation_success))),
              );
              _isSubmitting = false;
              Navigator.of(context).pop();
            }
          } else if (recipeState is RecipesError) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(recipeState.message),
                  backgroundColor: Colors.red,
                ),
              );
              _isSubmitting = false;
            }
          }
        },
        builder: (context, recipeState) {
          final isSaving = recipeState is RecipesLoading || _isSubmitting;

          return BlocBuilder<InventoryCubit, InventoryState>(
            builder: (context, state) {
              // if (state is InventoryLoading) {
              //   return const Center(child: CircularProgressIndicator());
              // }

              final inventoryItems = state is InventoryLoaded
                  ? state.items
                  : context.read<InventoryCubit>().cachedItems;

              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RecipeNameAutocompleteField(
                            controller: _nameController,
                            initialValue: widget.initialRecipe?.productName,
                            onSelected: (String value) {
                              setState(() {
                                _nameController.text = value;
                                _nameController.selection =
                                    TextSelection.collapsed(
                                        offset: value.length);
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: context.tr(LangKeys.price),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.tr(LangKeys.field_required);
                              }
                              final v = double.tryParse(value);
                              if (v == null || v < 0)
                                return context.tr(LangKeys.invalid_price);
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr(LangKeys.ingredients),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Builder(builder: (ctx) {
                            // Ensure unique items by id to avoid duplicate values
                            final uniqueMap = <String, InventoryItem>{
                              for (final it in inventoryItems) it.id: it
                            };
                            final uniqueItems = uniqueMap.values.toList();

                            final safeValue = _selectedItem != null &&
                                    uniqueItems
                                        .any((e) => e.id == _selectedItem!.id)
                                ? uniqueItems.firstWhere(
                                    (e) => e.id == _selectedItem!.id)
                                : null;

                            return DropdownButtonFormField<InventoryItem>(
                              value: safeValue,
                              decoration: InputDecoration(
                                labelText: context.tr(LangKeys.select_item),
                                border: const OutlineInputBorder(),
                              ),
                              items: uniqueItems.map((item) {
                                return DropdownMenuItem(
                                  value: item,
                                  child: Text('${item.name} (${item.unit})'),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() {
                                if (val == null) {
                                  _selectedItem = null;
                                } else {
                                  // ensure we use the instance from the list
                                  _selectedItem = uniqueItems
                                      .firstWhere((e) => e.id == val.id);
                                }
                              }),
                            );
                          }),
                          SizedBox(
                            height: 16,
                          ),
                          // Ingredient adder row
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _quantityController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: context.tr(LangKeys.qty),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Colors.green, size: 32),
                                onPressed: _addIngredient,
                              ),
                            ],
                          ),
                          // const SizedBox(height: 160),

                          // Ingredients list
                          Expanded(
                            child: _ingredients.isEmpty
                                ? SizedBox(
                                    height: 100,
                                    child: Center(
                                      child: Text(
                                        context.tr(LangKeys.no_items_added),
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _ingredients.length,
                                    itemBuilder: (context, index) {
                                      final ing = _ingredients[index];
                                      final invItem = inventoryItems.firstWhere(
                                        (i) => i.id == ing.inventoryItemId,
                                        orElse: () => InventoryItem(
                                          id: '',
                                          sku: '',
                                          name: 'Unknown',
                                          unit: '',
                                          price: 0,
                                          minThreshold: 0,
                                          quantity: 0,
                                        ),
                                      );
                                      return Card(
                                        child: ListTile(
                                          title: Text(invItem.name),
                                          subtitle: Text(
                                              '${ing.quantityRequiredPerUnit} ${invItem.unit}'),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () =>
                                                _removeIngredient(index),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveRecipe,
                              child: Text(context.tr(LangKeys.save)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isSaving)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// قوائم اقتراحات منفصلة: كل اسم إما عربي بحت أو إنجليزي بحت (مش الاتنين مع
// بعض في نفس الاسم). القائمة النهائية دي دمج للاتنين عشان تدور بأي لغة
// وتلاقي نتايج، لكن كل عنصر لوحده لغة واحدة بس.
// عدّل/زوّد فيها براحتك.
// ─────────────────────────────────────────────────────────────────────────
const List<String> kRecipeNameSuggestionsEn = [
  // Espresso based
  'Espresso',
  'Double Espresso',
  'Americano',
  'Cappuccino',
  'Latte',
  'Flat White',
  'Macchiato',
  'Cortado',
  'Mocha',
  'Affogato',
  'Ristretto',
  'Lungo',
  'Cafe au Lait',
  'Piccolo Latte',
  'Breve',
  'Red Eye',

  // Iced / cold drinks
  'Iced Coffee',
  'Iced Latte',
  'Iced Americano',
  'Iced Cappuccino',
  'Iced Mocha',
  'Iced Caramel Macchiato',
  'Cold Brew',
  'Nitro Cold Brew',
  'Frappe',
  'Frappuccino',
  'Iced Matcha Latte',
  'Iced Chai Latte',
  'Iced Spanish Latte',
  'Iced White Mocha',

  // Turkish / Arabic style (English names)
  'Turkish Coffee',
  'Arabic Coffee',
  'Saudi Coffee',
  'Cardamom Coffee',

  // Flavored lattes / seasonal
  'Vanilla Latte',
  'Caramel Latte',
  'Hazelnut Latte',
  'Pumpkin Spice Latte',
  'Gingerbread Latte',
  'White Chocolate Mocha',
  'Dark Chocolate Mocha',
  'Cinnamon Latte',
  'Honey Latte',
  'Rose Latte',
  'Pistachio Latte',
  'Lotus Biscoff Latte',
  'Salted Caramel Latte',

  // Matcha / tea based
  'Matcha Latte',
  'Chai Latte',
  'Karak Tea',
  'Moroccan Mint Tea',
  'Green Tea',
  'Black Tea',
  'Hibiscus Tea',
  'Herbal Tea',
  'Earl Grey Tea',
  'Lemon Ginger Tea',

  // Hot chocolate & non-coffee
  'Hot Chocolate',
  'White Hot Chocolate',
  'Spanish Latte',
  'Dirty Chai',
  'Golden Milk',
  'Chai Tea Latte',

  // Juices & smoothies
  'Fresh Orange Juice',
  'Mango Juice',
  'Strawberry Juice',
  'Lemon Mint Juice',
  'Mixed Berry Smoothie',
  'Mango Smoothie',
  'Banana Smoothie',
  'Avocado Juice',
  'Guava Juice',
  'Pineapple Juice',
  'Watermelon Juice',
  'Detox Juice',

  // Mocktails / soft drinks
  'Virgin Mojito',
  'Blue Lagoon Mocktail',
  'Passion Fruit Mocktail',
  'Sparkling Lemonade',
  'Berry Fizz',
  'Cucumber Mint Cooler',

  // Bakery / pastry
  'Croissant',
  'Cheesecake',
  'Chocolate Cake',
  'Red Velvet Cake',
  'Muffin',
  'Cinnamon Roll',
  'Brownie',
  'Cookies',
  'Tiramisu',
  'Panna Cotta',
];

const List<String> kRecipeNameSuggestionsAr = [
  // إسبريسو
  'إسبريسو',
  'إسبريسو دوبل',
  'أمريكانو',
  'كابتشينو',
  'لاتيه',
  'فلات وايت',
  'ماكياتو',
  'كورتادو',
  'موكا',
  'أفوجاتو',
  'ريستريتو',
  'لونغو',
  'كافيه أو ليه',
  'بيكولو لاتيه',
  'بريف',
  'ريد آي',

  // مشروبات مثلجة
  'قهوة مثلجة',
  'آيس لاتيه',
  'آيس أمريكانو',
  'آيس كابتشينو',
  'آيس موكا',
  'آيس كراميل ماكياتو',
  'كولد برو',
  'نيترو كولد برو',
  'فرابيه',
  'فرابتشينو',
  'آيس ماتشا لاتيه',
  'آيس تشاي لاتيه',
  'آيس سبانش لاتيه',
  'آيس وايت موكا',

  // قهوة تركي/عربي
  'قهوة تركي',
  'قهوة عربي',
  'قهوة سادة',
  'قهوة سعودي',
  'قهوة بالهيل',
  'قهوة مظبوطة',
  'قهوة عريحة',

  // لاتيه بنكهات
  'فانيلا لاتيه',
  'كراميل لاتيه',
  'بندق لاتيه',
  'بمبكن سبايس لاتيه',
  'جينجربريد لاتيه',
  'وايت شوكليت موكا',
  'دارك شوكليت موكا',
  'قرفة لاتيه',
  'عسل لاتيه',
  'لاتيه بالورد',
  'فستق لاتيه',
  'لوتس لاتيه',
  'سولتد كراميل لاتيه',

  // ماتشا وشاي
  'ماتشا لاتيه',
  'تشاي لاتيه',
  'شاي كرك',
  'شاي بالنعناع مغربي',
  'شاي أخضر',
  'شاي أسود',
  'كركديه',
  'شاي أعشاب',
  'إيرل جراي',
  'شاي بالليمون والزنجبيل',

  // شوكولاتة ساخنة ومشروبات أخرى
  'شوكولاتة ساخنة',
  'وايت هوت شوكليت',
  'سبانش لاتيه',
  'ديرتي تشاي',
  'جولدن ميلك',
  'تشاي تي لاتيه',

  // عصائر وسموذي
  'عصير برتقال',
  'عصير مانجا',
  'عصير فراولة',
  'ليمون بالنعناع',
  'سموذي فواكه حمراء',
  'سموذي مانجا',
  'سموذي موز',
  'عصير أفوكادو',
  'عصير جوافة',
  'عصير أناناس',
  'عصير بطيخ',
  'عصير ديتوكس',

  // موكتيلز ومشروبات غازية
  'موهيتو بدون كحول',
  'بلو لاجون',
  'باشون فروت موكتيل',
  'ليمونادة فوارة',
  'بيري فيز',
  'خيار ونعناع',

  // مخبوزات وحلويات
  'كرواسون',
  'تشيز كيك',
  'كيكة شوكولاتة',
  'ريد فيلفيت',
  'مافن',
  'سينامون رول',
  'براوني',
  'كوكيز',
  'تيراميسو',
  'بانا كوتا',
];

/// القائمة الكاملة اللي بتترشح منها الاقتراحات: كل عنصر لغة واحدة بس
/// (إما عربي أو إنجليزي)، لكن الفلترة بتقبل الاتنين مع بعض.
final List<String> kRecipeNameSuggestions = [
  ...kRecipeNameSuggestionsEn,
  ...kRecipeNameSuggestionsAr,
];

/// حقل اسم الـ Recipe مع اقتراحات فورية بمجرد كتابة حرف — الاقتراحات نفسها
/// إما عربي أو إنجليزي (مش الاتنين مدموجين في اسم واحد)، لكن ممكن تدور
/// بأي لغة وهيلاقي المطابق ليها.
class RecipeNameAutocompleteField extends StatelessWidget {
  const RecipeNameAutocompleteField({
    super.key,
    required this.controller,
    this.initialValue,
    required this.onSelected,
    this.onChanged,
    this.labelText = 'Recipe Name',
    this.suggestions,
  });

  /// الـ controller الحقيقي بتاع اسم الوصفة في الفورم (لازم نفس الكونترولر
  /// المستخدم وقت الحفظ).
  final TextEditingController controller;
  final String? initialValue;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onChanged;
  final String labelText;

  /// لو مبعتش قايمة مخصصة، بيستخدم القايمة الافتراضية (عربي + إنجليزي).
  final List<String>? suggestions;

  @override
  Widget build(BuildContext context) {
    final effectiveSuggestions = suggestions ?? kRecipeNameSuggestions;
    return Autocomplete<String>(
      initialValue: TextEditingValue(
        text: initialValue ?? controller.text,
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim();
        if (query.isEmpty) {
          // من غير كتابة، إديله أول شوية اقتراحات كـ default
          return effectiveSuggestions.take(15);
        }
        return effectiveSuggestions.where((option) {
          return option.toLowerCase().contains(query.toLowerCase());
        });
      },
      displayStringForOption: (option) => option,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // نخلي الـ controller الداخلي بتاع الـ Autocomplete هو نفسه اللي
        // بيتحفظ منه اسم الوصفة، عشان مايبقاش في اتنين controller منفصلين.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.text != textController.text) {
            controller.text = textController.text;
          }
        });
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.local_cafe_outlined),
          ),
          onChanged: (value) {
            controller.text = value;
            onChanged?.call(value);
          },
          onFieldSubmitted: (value) => onFieldSubmitted(),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'من فضلك اكتب اسم الوصفة';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelectedCallback, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 400),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.local_cafe, size: 18),
                    title: Text(option),
                    onTap: () => onSelectedCallback(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (value) {
        controller.text = value;
        onSelected(value);
      },
    );
  }
}
