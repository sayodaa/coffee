import 'package:equatable/equatable.dart';

/// Money value object for handling currency
class Money extends Equatable {
  final double amount;
  final String currency;

  const Money(this.amount, {this.currency = 'USD'});

  static const Money zero = Money(0);

  Money operator +(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot add different currencies');
    }
    return Money(amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot subtract different currencies');
    }
    return Money(amount - other.amount, currency: currency);
  }

  Money operator *(int multiplier) {
    return Money(amount * multiplier, currency: currency);
  }

  Money operator /(int divisor) {
    return Money(amount / divisor, currency: currency);
  }

  bool get isZero => amount == 0;
  bool get isPositive => amount > 0;
  bool get isNegative => amount < 0;

  @override
  String toString() => '${amount.toStringAsFixed(2)} $currency';

  @override
  List<Object?> get props => [amount, currency];
}
