import 'package:borj/core/errors/app_failure.dart';

final class Money implements Comparable<Money> {
  const Money({
    required this.minorUnits,
    required this.currencyCode,
    required this.scale,
  }) : assert(currencyCode != ''),
       assert(scale >= 0 && scale <= 18),
       assert(minorUnits >= minInt64 && minorUnits <= maxInt64);

  static const int minInt64 = -9223372036854775808;
  static const int maxInt64 = 9223372036854775807;
  static const int financeScale = 0;
  static const String tomanCurrencyCode = 'IRT';
  static const Money zeroIRT = Money(
    minorUnits: 0,
    currencyCode: tomanCurrencyCode,
    scale: financeScale,
  );

  final int minorUnits;
  final String currencyCode;
  final int scale;

  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;
  bool get isZero => minorUnits == 0;

  Money get absolute =>
      minorUnits < 0 ? copyWith(minorUnits: checkedNegate(minorUnits)) : this;

  /// A lossy projection reserved for chart coordinates and progress visuals.
  /// Monetary calculations and labels must continue to use [minorUnits].
  double get majorUnitsForChart => minorUnits / _powerOfTen(scale);

  static Money parseMajorUnits(
    String raw, {
    required String currencyCode,
    required int scale,
  }) {
    final parsed = tryParseMajorUnits(
      raw,
      currencyCode: currencyCode,
      scale: scale,
    );
    if (parsed == null) {
      throw FormatException('Invalid exact money value: $raw');
    }
    return parsed;
  }

  static Money? tryParseMajorUnits(
    String raw, {
    required String currencyCode,
    required int scale,
  }) {
    if (currencyCode.isEmpty || scale < 0 || scale > 18) return null;

    var normalized = normalizeDigits(raw.trim());
    normalized = normalized
        .replaceAll('\u066C', '')
        .replaceAll(',', '')
        .replaceAll('_', '')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('\u066B', '.');

    if (normalized.isEmpty) return null;

    var negative = false;
    if (normalized.startsWith('-') || normalized.startsWith('−')) {
      negative = true;
      normalized = normalized.substring(1);
    } else if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }

    if (normalized.isEmpty ||
        !RegExp(r'^\d*(?:\.\d*)?$').hasMatch(normalized)) {
      return null;
    }

    final decimalIndex = normalized.indexOf('.');
    var whole = decimalIndex < 0
        ? normalized
        : normalized.substring(0, decimalIndex);
    final fraction = decimalIndex < 0
        ? ''
        : normalized.substring(decimalIndex + 1);

    if (fraction.length > scale) return null;
    if (whole.isEmpty) whole = '0';

    whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final scaledDigits = '$whole${fraction.padRight(scale, '0')}'.replaceFirst(
      RegExp(r'^0+(?=\d)'),
      '',
    );
    final unsigned = int.tryParse(scaledDigits.isEmpty ? '0' : scaledDigits);
    if (unsigned == null) return null;

    final signed = negative ? -unsigned : unsigned;
    if (signed < minInt64 || signed > maxInt64) return null;

    return Money(minorUnits: signed, currencyCode: currencyCode, scale: scale);
  }

  String formatMajorUnits({
    bool usePersianDigits = true,
    bool trimFractionZeros = true,
    String groupingSeparator = '٬',
    String decimalSeparator = '٫',
  }) {
    final negative = minorUnits < 0;
    final absoluteDigits = minorUnits.abs().toString().padLeft(scale + 1, '0');
    final whole = scale == 0
        ? absoluteDigits
        : absoluteDigits.substring(0, absoluteDigits.length - scale);
    var fraction = scale == 0
        ? ''
        : absoluteDigits.substring(absoluteDigits.length - scale);

    if (trimFractionZeros && fraction.isNotEmpty) {
      fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
    }

    final groupedWhole = _groupDigits(whole, groupingSeparator);
    final ascii = StringBuffer()
      ..write(negative ? '−' : '')
      ..write(groupedWhole);
    if (fraction.isNotEmpty) {
      ascii
        ..write(decimalSeparator)
        ..write(fraction);
    }

    return usePersianDigits
        ? toPersianDigits(ascii.toString())
        : ascii.toString();
  }

  Money operator +(Money other) {
    _requireCompatible(other);
    return copyWith(minorUnits: checkedAdd(minorUnits, other.minorUnits));
  }

  Money operator -(Money other) {
    _requireCompatible(other);
    return copyWith(minorUnits: checkedSubtract(minorUnits, other.minorUnits));
  }

  Money operator -() => copyWith(minorUnits: checkedNegate(minorUnits));

  Money operator *(int multiplier) =>
      copyWith(minorUnits: checkedMultiply(minorUnits, multiplier));

  /// This value as a rounded-half-up integer percentage of [total].
  ///
  /// Uses [BigInt] so `minorUnits * 100` can never wrap.
  int percentOf(Money total) {
    _requireCompatible(total);
    if (!total.isPositive) {
      throw ArgumentError('The total must be positive.');
    }
    final numerator =
        BigInt.from(minorUnits) * BigInt.from(100) +
        BigInt.from(total.minorUnits) ~/ BigInt.two;
    return (numerator ~/ BigInt.from(total.minorUnits)).toInt();
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  Money clamp(Money lowerLimit, Money upperLimit) {
    _requireCompatible(lowerLimit);
    _requireCompatible(upperLimit);
    if (lowerLimit > upperLimit) {
      throw ArgumentError('The lower money limit exceeds the upper limit.');
    }
    if (this < lowerLimit) return lowerLimit;
    if (this > upperLimit) return upperLimit;
    return this;
  }

  Money copyWith({int? minorUnits, String? currencyCode, int? scale}) {
    return Money(
      minorUnits: minorUnits ?? this.minorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
    );
  }

  @override
  int compareTo(Money other) {
    _requireCompatible(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  void _requireCompatible(Money other) {
    if (currencyCode != other.currencyCode || scale != other.scale) {
      throw ArgumentError('Money values use different currency definitions.');
    }
  }

  static final BigInt _minInt64Big = BigInt.from(minInt64);
  static final BigInt _maxInt64Big = BigInt.from(maxInt64);

  static int checkedAdd(int left, int right) {
    final result = left + right;
    if ((left >= 0) == (right >= 0) && (result >= 0) != (left >= 0)) {
      throw const MoneyOverflowFailure();
    }
    return result;
  }

  static int checkedSubtract(int left, int right) {
    final result = left - right;
    if ((left >= 0) != (right >= 0) && (result >= 0) != (left >= 0)) {
      throw const MoneyOverflowFailure();
    }
    return result;
  }

  static int checkedMultiply(int left, int right) {
    final product = BigInt.from(left) * BigInt.from(right);
    if (product < _minInt64Big || product > _maxInt64Big) {
      throw const MoneyOverflowFailure();
    }
    return product.toInt();
  }

  static int checkedNegate(int value) {
    if (value == minInt64) throw const MoneyOverflowFailure();
    return -value;
  }

  static int _powerOfTen(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index++) {
      value *= 10;
    }
    return value;
  }

  static String _groupDigits(String digits, String separator) {
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = (end - 3).clamp(0, digits.length).toInt();
      groups.insert(0, digits.substring(start, end));
    }
    return groups.join(separator);
  }

  static String normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var result = value;
    for (var index = 0; index < 10; index++) {
      result = result
          .replaceAll(persian[index], '$index')
          .replaceAll(arabic[index], '$index');
    }
    return result;
  }

  static String toPersianDigits(String value) {
    const latin = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.split('').map((character) {
      final index = latin.indexOf(character);
      return index < 0 ? character : persian[index];
    }).join();
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.minorUnits == minorUnits &&
        other.currencyCode == currencyCode &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode, scale);

  @override
  String toString() {
    return 'Money(minorUnits: $minorUnits, '
        'currencyCode: $currencyCode, scale: $scale)';
  }
}
