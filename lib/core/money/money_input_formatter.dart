import 'package:borj/core/money/money.dart';
import 'package:flutter/services.dart';

/// Formats a positive monetary amount while the user types.
///
/// The formatter accepts Persian, Arabic, and Latin digits, displays Persian
/// digits, groups the integer part with `٬`, and preserves up to
/// [maxFractionDigits] digits after `٫` without rounding.
final class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter({
    this.maxFractionDigits = Money.financeScale,
    this.maxIntegerDigits = 15,
  }) : assert(maxFractionDigits >= 0 && maxFractionDigits <= 18),
       assert(maxIntegerDigits > 0);

  final int maxFractionDigits;

  /// v1 kept at most 15 digits (`parseAmount`); the same cap keeps typed
  /// amounts far below the int64 limit.
  final int maxIntegerDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return TextEditingValue.empty;

    final rawCursor = newValue.selection.extentOffset
        .clamp(0, newValue.text.length)
        .toInt();
    final semanticBeforeCursor = _semanticLength(
      newValue.text.substring(0, rawCursor),
    );
    final editable = _sanitize(newValue.text);
    if (editable == null) return oldValue;

    final formatted = _format(editable);
    final cursor = _offsetForSemanticLength(formatted, semanticBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursor),
      composing: TextRange.empty,
    );
  }

  _EditableMoney? _sanitize(String raw) {
    final normalized = Money.normalizeDigits(raw);
    final integer = StringBuffer();
    final fraction = StringBuffer();
    var hasDecimal = false;

    for (final rune in normalized.runes) {
      final character = String.fromCharCode(rune);
      if (RegExp(r'\d').hasMatch(character)) {
        if (hasDecimal) {
          if (fraction.length < maxFractionDigits) fraction.write(character);
        } else {
          if (integer.length < maxIntegerDigits) integer.write(character);
        }
        continue;
      }
      if (character == '.' || character == '٫') {
        // A whole-unit currency refuses the separator. Without this, the
        // fraction digits that follow would be appended to the integer part
        // ("12.5" would become 125).
        if (maxFractionDigits == 0) return null;
        hasDecimal = true;
        continue;
      }
      if (character == ',' ||
          character == '٬' ||
          character == '_' ||
          character.trim().isEmpty) {
        continue;
      }
      if (character == '-' || character == '−' || character == '+') {
        return null;
      }
    }

    var whole = integer.toString();
    if (whole.isEmpty && !hasDecimal) return null;
    if (whole.isEmpty) whole = '0';
    whole = whole.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    return _EditableMoney(
      whole: whole,
      fraction: fraction.toString(),
      hasDecimal: hasDecimal,
    );
  }

  String _format(_EditableMoney value) {
    final grouped = _group(value.whole);
    final result = StringBuffer(Money.toPersianDigits(grouped));
    if (value.hasDecimal) {
      result
        ..write('٫')
        ..write(Money.toPersianDigits(value.fraction));
    }
    return result.toString();
  }

  static String _group(String digits) {
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      final start = (end - 3).clamp(0, digits.length).toInt();
      groups.insert(0, digits.substring(start, end));
    }
    return groups.join('٬');
  }

  static int _semanticLength(String value) {
    final normalized = Money.normalizeDigits(value);
    var count = 0;
    var decimalSeen = false;
    for (final rune in normalized.runes) {
      final character = String.fromCharCode(rune);
      if (RegExp(r'\d').hasMatch(character)) {
        count += 1;
      } else if ((character == '.' || character == '٫') && !decimalSeen) {
        decimalSeen = true;
        count += 1;
      }
    }
    return count;
  }

  static int _offsetForSemanticLength(String value, int target) {
    if (target <= 0) return 0;
    var count = 0;
    var decimalSeen = false;
    for (var offset = 0; offset < value.length; offset++) {
      final character = value[offset];
      final isDigit = '۰۱۲۳۴۵۶۷۸۹0123456789'.contains(character);
      final isDecimal = character == '٫' && !decimalSeen;
      if (isDigit || isDecimal) {
        if (isDecimal) decimalSeen = true;
        count += 1;
        if (count >= target) return offset + 1;
      }
    }
    return value.length;
  }
}

final class _EditableMoney {
  const _EditableMoney({
    required this.whole,
    required this.fraction,
    required this.hasDecimal,
  });

  final String whole;
  final String fraction;
  final bool hasDecimal;
}
