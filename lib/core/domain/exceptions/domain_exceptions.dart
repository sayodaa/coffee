import 'package:equatable/equatable.dart';

/// Abstract base class for all domain exceptions
abstract class DomainException extends Equatable implements Exception {
  final String message;
  final String? code;

  const DomainException(this.message, {this.code});

  @override
  String toString() => 'DomainException: $message (code: $code)';

  @override
  List<Object?> get props => [message, code];
}

/// Thrown when there is insufficient stock for an inventory item
class InsufficientStockException extends DomainException {
  final String inventoryItemId;
  final double required;
  final double available;

  const InsufficientStockException({
    required this.inventoryItemId,
    required this.required,
    required this.available,
  }) : super(
          'Insufficient stock: required $required, available $available',
          code: 'INSUFFICIENT_STOCK',
        );

  @override
  List<Object?> get props => [...super.props, inventoryItemId, required, available];
}

/// Thrown when an inventory item is not found
class InventoryItemNotFoundException extends DomainException {
  final String inventoryItemId;

  const InventoryItemNotFoundException(this.inventoryItemId)
      : super(
          'Inventory item not found: $inventoryItemId',
          code: 'INVENTORY_NOT_FOUND',
        );

  @override
  List<Object?> get props => [...super.props, inventoryItemId];
}

/// Thrown when a recipe is not found for a product
class RecipeNotFoundException extends DomainException {
  final String productId;

  const RecipeNotFoundException(this.productId)
      : super(
          'Recipe not found for product: $productId',
          code: 'RECIPE_NOT_FOUND',
        );

  @override
  List<Object?> get props => [...super.props, productId];
}

/// Thrown when a product is not found
class ProductNotFoundException extends DomainException {
  final String productId;

  const ProductNotFoundException(this.productId)
      : super(
          'Product not found: $productId',
          code: 'PRODUCT_NOT_FOUND',
        );

  @override
  List<Object?> get props => [...super.props, productId];
}

/// Thrown when concurrent modification is detected
class ConcurrentModificationException extends DomainException {
  const ConcurrentModificationException()
      : super(
          'Inventory was modified by another transaction. Please retry.',
          code: 'CONCURRENT_MODIFICATION',
        );
}

/// Thrown when validation fails with multiple errors
class ValidationException extends DomainException {
  final List<DomainException> errors;

  const ValidationException(this.errors)
      : super(
          'Validation failed with ${errors.length} errors',
          code: 'VALIDATION_ERROR',
        );

  @override
  List<Object?> get props => [...super.props, errors];
}

/// Thrown when a transaction is not found
class TransactionNotFoundException extends DomainException {
  final String transactionId;

  const TransactionNotFoundException(this.transactionId)
      : super(
          'Transaction not found: $transactionId',
          code: 'TRANSACTION_NOT_FOUND',
        );

  @override
  List<Object?> get props => [...super.props, transactionId];
}

/// Thrown when an invalid return quantity is requested
class InvalidReturnQuantityException extends DomainException {
  final String inventoryItemId;
  final double requested;
  final double available;

  const InvalidReturnQuantityException({
    required this.inventoryItemId,
    required this.requested,
    required this.available,
  }) : super(
          'Invalid return quantity: requested $requested, available $available',
          code: 'INVALID_RETURN_QUANTITY',
        );

  @override
  List<Object?> get props => [...super.props, inventoryItemId, requested, available];
}

/// Thrown when product is inactive
class ProductInactiveException extends DomainException {
  final String productId;
  final String productName;

  const ProductInactiveException({
    required this.productId,
    required this.productName,
  }) : super(
          'Product is not active: $productName',
          code: 'PRODUCT_INACTIVE',
        );

  @override
  List<Object?> get props => [...super.props, productId, productName];
}

/// Thrown when a generic not found error occurs
class NotFoundException extends DomainException {
  const NotFoundException([String message = '']) : super(message, code: 'NOT_FOUND');
}

/// Thrown when an unexpected error occurs
class UnexpectedException extends DomainException {
  const UnexpectedException([String message = '']) : super(message, code: 'UNEXPECTED');
}

/// Thrown when an invalid quantity is provided
class InvalidQuantityException extends DomainException {
  const InvalidQuantityException([String message = '']) : super(message, code: 'INVALID_QUANTITY');
}

/// Thrown when an invalid adjustment is attempted
class InvalidAdjustmentException extends DomainException {
  const InvalidAdjustmentException([String message = '']) : super(message, code: 'INVALID_ADJUSTMENT');
}

/// Thrown when a negative stock would result
class NegativeStockException extends DomainException {
  const NegativeStockException([String message = '']) : super(message, code: 'NEGATIVE_STOCK');
}
