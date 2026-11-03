import 'package:dashboard_shakhsi/core/money/money_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const formatter = MoneyInputFormatter(maxFractionDigits: 8);

  TextEditingValue edit(String text, {int? offset}) {
    return formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: offset ?? text.length),
      ),
    );
  }

  test('groups the integer part live and renders Persian digits', () {
    final result = edit('123456789');

    expect(result.text, '۱۲۳٬۴۵۶٬۷۸۹');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('accepts Arabic digits and preserves a trailing decimal separator', () {
    expect(edit('١٢٣٤.').text, '۱٬۲۳۴٫');
    expect(edit('١٢٣٤.٥٠').text, '۱٬۲۳۴٫۵۰');
  });

  test('limits fractional input to eight digits without rounding', () {
    expect(edit('1234.123456789').text, '۱٬۲۳۴٫۱۲۳۴۵۶۷۸');
  });

  test('keeps the caret at the same logical digit position', () {
    final result = edit('12345', offset: 3);

    expect(result.text, '۱۲٬۳۴۵');
    expect(result.selection.baseOffset, 4);
  });

  test('allows clearing the field', () {
    final result = formatter.formatEditUpdate(
      const TextEditingValue(
        text: '۱۲۳',
        selection: TextSelection.collapsed(offset: 3),
      ),
      TextEditingValue.empty,
    );

    expect(result, TextEditingValue.empty);
  });

  test('the whole-toman formatter rejects a decimal separator', () {
    const wholeFormatter = MoneyInputFormatter();
    const previous = TextEditingValue(
      text: '۱۲',
      selection: TextSelection.collapsed(offset: 2),
    );

    for (final typed in <String>['12.', '12٫', '12.5']) {
      final result = wholeFormatter.formatEditUpdate(
        previous,
        TextEditingValue(
          text: typed,
          selection: TextSelection.collapsed(offset: typed.length),
        ),
      );
      expect(result, previous, reason: 'typed "$typed" must be refused');
    }
  });

  test('the whole-toman formatter still groups digits', () {
    const wholeFormatter = MoneyInputFormatter();
    final result = wholeFormatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: '1234567',
        selection: TextSelection.collapsed(offset: 7),
      ),
    );

    expect(result.text, '۱٬۲۳۴٬۵۶۷');
  });
}
