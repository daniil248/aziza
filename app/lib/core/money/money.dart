import 'package:intl/intl.dart';

/// Money value object. Always stores integer minor units (1 ₸ = 100 minor).
/// Avoid float arithmetic on prices. Always go through this.
class Money {
  const Money(this.minor);

  final int minor;

  static const Money zero = Money(0);

  factory Money.fromMajor(num major) => Money((major * 100).round());

  Money operator +(Money other) => Money(minor + other.minor);
  Money operator -(Money other) => Money(minor - other.minor);
  Money operator *(int qty) => Money(minor * qty);

  bool get isZero => minor == 0;

  /// Formats as "1 250 ₸" using kk-KZ locale conventions (NB-space thousands).
  String format([String? localeOverride]) {
    final fmt = NumberFormat.currency(
      locale: localeOverride ?? 'kk_KZ',
      symbol: '₸',
      decimalDigits: 0,
    );
    return fmt.format(minor / 100);
  }

  @override
  String toString() => format();
}
