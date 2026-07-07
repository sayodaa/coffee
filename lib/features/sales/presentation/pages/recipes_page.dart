import 'package:coffee_app/core/localization/json_localizations.dart';
import 'package:coffee_app/core/localization/lang_keys.dart';
import 'package:coffee_app/features/sales/domain/entities/recipe_entity.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_cubit.dart';
import 'package:coffee_app/features/sales/presentation/bloc/recipes_state.dart';
import 'package:coffee_app/features/sales/presentation/pages/recipe_form_page.dart';
import 'package:coffee_app/presentation/widgets/shimmers/inventory_shimmer.dart';
import 'package:coffee_app/shared/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ─── Local theme constants (kept consistent with Reports/Sales pages) ────────
const _kCaramel = Color(0xFFC68E52);
const _kWhite = Colors.white;
const _kBgDark = Color(0xFF1B1512);

class RecipesPage extends StatefulWidget {
  const RecipesPage({
    super.key,
  });
  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  @override
  void initState() {
    super.initState();
    // Load recipes when page is initialized
    // This is called only once, not on every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecipesCubit>().loadRecipes();
      }
    });
  }

  void _navigateToCreateRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecipeFormPage()),
    );
  }

  void _navigateToEditRecipe(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RecipeFormPage(initialRecipe: recipe)),
    );
  }

  Future<void> _confirmDeleteRecipe(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr(LangKeys.confirm_delete_title)),
        content: Text('${context.tr(LangKeys.confirm_delete_recipe)}\n"$name"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr(LangKeys.cancel)),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr(LangKeys.delete)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Delete recipe using RecipesCubit
      if (context.mounted) {
        context.read<RecipesCubit>().deleteRecipe(id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Lets the body (and our background image) draw behind the app bar,
      // so the photo covers the whole screen including the status bar area.
      extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   title: Text(
      //     context.tr(LangKeys.recipes),
      //     style: const TextStyle(color: _kWhite, fontWeight: FontWeight.w700),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: _kWhite),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh, color: _kWhite),
      //       tooltip: context.tr(LangKeys.refresh_inventory),
      //       onPressed: () {
      //         context.read<RecipesCubit>().refreshRecipes();
      //       },
      //     ),
      //   ],
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          backgroundColor: _kCaramel,
          foregroundColor: _kWhite,
          onPressed: _navigateToCreateRecipe,
          icon: const Icon(Icons.add),
          label: Text(context.tr(LangKeys.new_recipe)),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full-screen background image (behind app bar too) ──
          const _RecipesBackground(),

          // ── Page content on top of the image ──
          SafeArea(
            child: BlocBuilder<RecipesCubit, RecipesState>(
              builder: (context, state) {
                // Handle loading state
                if (state is RecipesLoading) {
                  return const Center(child: InventoryShimmer());
                }

                // Handle empty state
                if (state is RecipesEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.menu_book_rounded,
                    title: context.tr(LangKeys.no_recipes_title),
                    subtitle: context.tr(LangKeys.no_recipes_subtitle),
                    actionLabel: context.tr(LangKeys.add_recipe),
                    onActionPressed: _navigateToCreateRecipe,
                  );
                }

                // Handle error state
                if (state is RecipesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: _kWhite),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          style: const TextStyle(color: _kWhite),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kCaramel,
                            foregroundColor: _kWhite,
                          ),
                          onPressed: () {
                            context.read<RecipesCubit>().loadRecipes();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(context.tr(LangKeys.retry)),
                        ),
                      ],
                    ),
                  );
                }

                // Handle loaded state
                if (state is RecipesLoaded) {
                  final recipes = state.recipes;

                  if (recipes.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.menu_book_rounded,
                      title: context.tr(LangKeys.no_recipes_title),
                      subtitle: context.tr(LangKeys.no_recipes_subtitle),
                      actionLabel: context.tr(LangKeys.add_recipe),
                      onActionPressed: _navigateToCreateRecipe,
                    );
                  }

                  return _buildRecipesList(recipes, context);
                }

                // Handle operation success state
                if (state is RecipesOperationSuccess) {
                  // Show success message and transition back to loaded
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message)),
                    );
                  });
                  return _buildRecipesList(state.recipes, context);
                }

                // Default case
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to build recipes list UI
  Widget _buildRecipesList(List<Recipe> recipes, BuildContext context) {
    if (recipes.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.menu_book_rounded,
        title: context.tr(LangKeys.no_recipes_title),
        subtitle: context.tr(LangKeys.no_recipes_subtitle),
        actionLabel: context.tr(LangKeys.add_recipe),
        onActionPressed: _navigateToCreateRecipe,
      );
    }

    return RefreshIndicator(
      color: _kCaramel,
      backgroundColor: _kBgDark,
      onRefresh: () async {
        await context.read<RecipesCubit>().refreshRecipes();
      },
      child: ListView.builder(
        padding:
            const EdgeInsets.only(top: 16, bottom: 120, left: 16, right: 16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            // Semi-transparent dark tint (instead of a solid theme color)
            // so the recipe cards read clearly on top of the photo.
            color: Colors.black.withOpacity(0.42),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            child: Theme(
              // Forces the ExpansionTile's icon/text/divider colors to be
              // white/light regardless of the app's base theme, since the
              // card now sits on a photo instead of a plain surface.
              data: Theme.of(context).copyWith(
                dividerColor: Colors.white.withOpacity(0.12),
                listTileTheme: const ListTileThemeData(
                  iconColor: _kWhite,
                  textColor: _kWhite,
                ),
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: _kCaramel,
                      primaryContainer: _kCaramel.withOpacity(0.35),
                      onSurface: _kWhite,
                    ),
              ),
              child: ExpansionTile(
                iconColor: _kWhite,
                collapsedIconColor: _kWhite,
                leading: CircleAvatar(
                  backgroundColor: _kCaramel.withOpacity(0.35),
                  child: const Icon(Icons.local_bar, color: _kWhite),
                ),
                title: Text(
                  recipe.productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _kWhite),
                ),
                subtitle: Text(
                  '${recipe.ingredients.length} ${context.tr(LangKeys.ingredients)}',
                  style: TextStyle(color: _kWhite.withOpacity(0.75)),
                ),
                children: [
                  ...recipe.ingredients.map((ing) {
                    return ListTile(
                      leading: Icon(Icons.fiber_manual_record,
                          size: 10, color: _kWhite.withOpacity(0.7)),
                      title: Text(
                        '${context.tr(LangKeys.ingredient_id)}: ${ing.inventoryItemId}',
                        // '${context.tr(LangKeys.recipes)}: ${ing.calculateRequiredQuantity(index)}',
                        style: const TextStyle(color: _kWhite),
                      ),
                      trailing: Text(
                        '${ing.quantityRequiredPerUnit}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: _kWhite),
                      ),
                    );
                  }),
                  // Action buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit button
                        TextButton.icon(
                          onPressed: () => _navigateToEditRecipe(recipe),
                          icon: const Icon(Icons.edit,
                              color: Colors.lightBlueAccent, size: 18),
                          label: Text(
                            context.tr(LangKeys.edit_recipe),
                            style:
                                const TextStyle(color: Colors.lightBlueAccent),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete button with confirmation
                        TextButton.icon(
                          onPressed: () => _confirmDeleteRecipe(
                              recipe.id, recipe.productName),
                          icon: const Icon(Icons.delete,
                              color: Colors.redAccent, size: 18),
                          label: Text(
                            context.tr(LangKeys.delete),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Background (full-screen photo, extends behind the app bar) ──────────────
//
// Same treatment as the Reports page: base photo, a warm caramel color wash,
// then a vertical scrim (darker at top/bottom, lighter in the middle) so
// text and icons stay legible everywhere, including behind the app bar.

class _RecipesBackground extends StatelessWidget {
  const _RecipesBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/barista2.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _kBgDark.withOpacity(0.55),
                _kCaramel.withOpacity(0.12),
                _kBgDark.withOpacity(0.55),
              ],
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xCC1B1512),
                Color(0x661B1512),
                Color(0x331B1512),
                Color(0xDD1B1512),
              ],
              stops: [0.0, 0.28, 0.62, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
