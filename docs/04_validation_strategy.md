# 4. VALIDATION STRATEGY

## 4.1 Validation Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    VALIDATION LAYERS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Layer 1: UI Input Validation                                    │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Quantity must be positive integer                     │    │
│  │ - Size variant must be valid                            │    │
│  │ - Customizations within allowed ranges                  │    │
│  │ - Customer info format (if provided)                  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 2: Domain Validation (Entity level)                        │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Product must exist and be active                     │    │
│  │ - Recipe must exist for product                        │    │
│  │ - All ingredients must exist in inventory            │    │
│  │ - Units must be compatible                             │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 3: Business Rule Validation (UseCase level)              │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Sufficient stock for ALL ingredients                 │    │
│  │ - No negative stock allowed (prevent oversell)          │    │
│  │ - Concurrent transaction check                         │    │
│  │ - Pricing validity                                     │    │
│  └─────────────────────────────────────────────────────────┘    │
│                            ↓                                     │
│  Layer 4: Database Constraint Validation                         │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │ - Foreign key constraints                               │    │
│  │ - Quantity >= 0 (DB-level check)                      │    │
│  │ - Unique transaction ID                                 │    │
│  │ - Optimistic locking version check                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 4.2 Validation Implementation

```dart
// lib/domain/core/validators/validators.dart

abstract class Validator<T> {
  ValidationResult validate(T input);
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult({required this.isValid, required this.errors});

  factory ValidationResult.success() =>
      ValidationResult(isValid: true, errors: []);

  factory ValidationResult.failure(List<ValidationError> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

class ValidationError {
  final String field;
  final String message;
  final String? code;

  ValidationError({required this.field, required this.message, this.code});
}

// Layer 1: Input Validator
class SaleItemInputValidator implements Validator<SaleItem> {
  @override
  ValidationResult validate(SaleItem item) {
    final errors = <ValidationError>[];

    if (item.quantity <= 0) {
      errors.add(ValidationError(
        field: 'quantity',
        message: 'Quantity must be greater than 0',
        code: 'INVALID_QUANTITY',
      ));
    }

    if (item.quantity > 1000) {
      errors.add(ValidationError(
        field: 'quantity',
        message: 'Quantity exceeds maximum allowed (1000)',
        code: 'QUANTITY_TOO_LARGE',
      ));
    }

    if (item.sugarLevel == SugarLevel.double_ && item.quantity > 10) {
      errors.add(ValidationError(
        field: 'sugarLevel',
        message: 'Double sugar not allowed for large quantity orders',
        code: 'SUGAR_LIMIT_EXCEEDED',
      ));
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

// Layer 2: Domain Validator
class SaleDomainValidator {
  final ProductRepository _productRepo;
  final RecipeRepository _recipeRepo;
  final InventoryRepository _inventoryRepo;

  SaleDomainValidator({
    required ProductRepository productRepo,
    required RecipeRepository recipeRepo,
    required InventoryRepository inventoryRepo,
  })  : _productRepo = productRepo,
        _recipeRepo = recipeRepo,
        _inventoryRepo = inventoryRepo;

  Future<ValidationResult> validate(SaleItem item) async {
    final errors = <ValidationError>[];

    final product = await _productRepo.getById(item.productId);
    if (product == null) {
      errors.add(ValidationError(
        field: 'productId',
        message: 'Product not found: ${item.productId}',
        code: 'PRODUCT_NOT_FOUND',
      ));
    } else if (!product.isActive) {
      errors.add(ValidationError(
        field: 'productId',
        message: 'Product is not active: ${product.name}',
        code: 'PRODUCT_INACTIVE',
      ));
    }

    final recipe = await _recipeRepo.getByProductId(item.productId);
    if (recipe == null) {
      errors.add(ValidationError(
        field: 'recipe',
        message: 'No recipe found for product: ${item.productId}',
        code: 'RECIPE_NOT_FOUND',
      ));
    } else {
      final ingredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: {},
      );

      for (final ingredient in ingredients) {
        final inventoryItem = await _inventoryRepo.getById(ingredient.inventoryItemId);
        if (inventoryItem == null) {
          errors.add(ValidationError(
            field: 'ingredient.${ingredient.inventoryItemId}',
            message: 'Inventory item not found: ${ingredient.inventoryItemId}',
            code: 'INGREDIENT_NOT_FOUND',
          ));
        }
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }
}

// Layer 3: Business Rule Validator
class StockAvailabilityValidator {
  final InventoryRepository _inventoryRepo;
  final RecipeRepository _recipeRepo;

  StockAvailabilityValidator({
    required InventoryRepository inventoryRepo,
    required RecipeRepository recipeRepo,
  })  : _inventoryRepo = inventoryRepo,
        _recipeRepo = recipeRepo;

  Future<StockValidationResult> validateStockForItems(List<SaleItem> items) async {
    final requirements = <String, double>{};
    final failures = <StockValidationFailure>[];

    for (final item in items) {
      final recipe = await _recipeRepo.getByProductId(item.productId);
      if (recipe == null) continue;

      final ingredients = recipe.getModifiedIngredients(
        size: item.size,
        ingredientModifications: _getModifications(item),
      );

      for (final ingredient in ingredients) {
        final required = ingredient.calculateRequiredQuantity(item.quantity);
        requirements[ingredient.inventoryItemId] =
            (requirements[ingredient.inventoryItemId] ?? 0) + required;
      }
    }

    for (final entry in requirements.entries) {
      final inventoryItem = await _inventoryRepo.getById(entry.key);
      if (inventoryItem == null) {
        failures.add(StockValidationFailure(
          inventoryItemId: entry.key,
          required: entry.value,
          available: 0,
          reason: FailureReason.itemNotFound,
        ));
      } else if (inventoryItem.currentQuantity < entry.value) {
        failures.add(StockValidationFailure(
          inventoryItemId: entry.key,
          inventoryItemName: inventoryItem.name,
          required: entry.value,
          available: inventoryItem.currentQuantity,
          unit: inventoryItem.unit,
          reason: FailureReason.insufficientStock,
        ));
      }
    }

    return failures.isEmpty
        ? StockValidationResult.success()
        : StockValidationResult.failure(failures);
  }

  Map<String, double>? _getModifications(SaleItem item) {
    if (item.sugarLevel != null) {
      return {'sugar': item.sugarLevel!.multiplier};
    }
    return null;
  }
}

class StockValidationResult {
  final bool isAvailable;
  final List<StockValidationFailure>? failures;

  StockValidationResult({required this.isAvailable, this.failures});

  factory StockValidationResult.success() =>
      StockValidationResult(isAvailable: true);

  factory StockValidationResult.failure(List<StockValidationFailure> failures) =>
      StockValidationResult(isAvailable: false, failures: failures);
}

class StockValidationFailure {
  final String inventoryItemId;
  final String? inventoryItemName;
  final double required;
  final double available;
  final MeasurementUnit? unit;
  final FailureReason reason;

  StockValidationFailure({
    required this.inventoryItemId,
    this.inventoryItemName,
    required this.required,
    required this.available,
    this.unit,
    required this.reason,
  });
}

enum FailureReason {
  itemNotFound,
  insufficientStock,
  itemInactive,
}
```

## 4.3 Validation Orchestrator

```dart
// lib/domain/sales/usecases/validate_sale_usecase.dart
class ValidateSaleUseCase {
  final SaleItemInputValidator _inputValidator;
  final SaleDomainValidator _domainValidator;
  final StockAvailabilityValidator _stockValidator;

  ValidateSaleUseCase({
    required SaleItemInputValidator inputValidator,
    required SaleDomainValidator domainValidator,
    required StockAvailabilityValidator stockValidator,
  })  : _inputValidator = inputValidator,
        _domainValidator = domainValidator,
        _stockValidator = stockValidator;

  Future<ComprehensiveValidationResult> validate({
    required List<SaleItem> items,
    bool skipStockCheck = false,
  }) async {
    final allErrors = <ValidationLayerError>[];

    // Layer 1: Input validation
    for (final item in items) {
      final result = _inputValidator.validate(item);
      if (!result.isValid) {
        allErrors.addAll(result.errors.map((e) => ValidationLayerError(
              layer: ValidationLayer.input,
              error: e,
            )));
      }
    }

    if (allErrors.isNotEmpty) {
      return ComprehensiveValidationResult.failures(allErrors);
    }

    // Layer 2: Domain validation
    for (final item in items) {
      final result = await _domainValidator.validate(item);
      if (!result.isValid) {
        allErrors.addAll(result.errors.map((e) => ValidationLayerError(
              layer: ValidationLayer.domain,
              error: e,
            )));
      }
    }

    if (allErrors.isNotEmpty) {
      return ComprehensiveValidationResult.failures(allErrors);
    }

    // Layer 3: Stock validation
    if (!skipStockCheck) {
      final stockResult = await _stockValidator.validateStockForItems(items);
      if (!stockResult.isAvailable) {
        allErrors.addAll(stockResult.failures!.map((f) => ValidationLayerError(
              layer: ValidationLayer.businessRule,
              error: ValidationError(
                field: 'stock.${f.inventoryItemId}',
                message: 'Insufficient stock for ${f.inventoryItemName ?? f.inventoryItemId}: '
                    'need ${f.required}${f.unit?.name ?? ''}, '
                    'have ${f.available}${f.unit?.name ?? ''}',
                code: 'INSUFFICIENT_STOCK',
              ),
            )));
      }
    }

    return allErrors.isEmpty
        ? ComprehensiveValidationResult.success()
        : ComprehensiveValidationResult.failures(allErrors);
  }
}

class ComprehensiveValidationResult {
  final bool isValid;
  final List<ValidationLayerError>? errors;

  ComprehensiveValidationResult({required this.isValid, this.errors});

  factory ComprehensiveValidationResult.success() =>
      ComprehensiveValidationResult(isValid: true);

  factory ComprehensiveValidationResult.failures(List<ValidationLayerError> errors) =>
      ComprehensiveValidationResult(isValid: false, errors: errors);
}

class ValidationLayerError {
  final ValidationLayer layer;
  final ValidationError error;

  ValidationLayerError({required this.layer, required this.error});
}

enum ValidationLayer {
  input,
  domain,
  businessRule,
  database,
}
```
