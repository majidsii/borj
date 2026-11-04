import 'package:dashboard_shakhsi/app/apple_visual/prototype/screens/quick_entry_parser.dart';
import 'package:flutter_test/flutter_test.dart';

Set<QuickTokenType> types(QuickEntry e) => e.tokens.map((t) => t.type).toSet();

void main() {
  test('lunch expense with amount, category and account', () {
    final e = parseQuickEntry('ناهار با علی ۴۵۰ تومن از کارت ملت');
    expect(e.kind, QuickKind.expense);
    expect(e.amountToman, 450);
    expect(e.category, 'خوراک');
    expect(e.account, 'کارت ملت');
    expect(e.title, 'ناهار با علی');
    expect(
      types(e),
      containsAll(<QuickTokenType>{
        QuickTokenType.amount,
        QuickTokenType.category,
        QuickTokenType.account,
      }),
    );
  });

  test('amount units and ASCII digits', () {
    expect(parseQuickEntry('450 هزار تومان شام').amountToman, 450000);
    expect(parseQuickEntry('۱۲ میلیون اجاره').amountToman, 12000000);
    expect(parseQuickEntry('2.5 میلیون').amountToman, 2500000);
    expect(parseQuickEntry('۴۵۰۰۰ اسنپ').amountToman, 45000);
  });

  test('appointment becomes a reminder with date and time', () {
    final e = parseQuickEntry('فردا ساعت ۱۰ دندانپزشکی');
    expect(e.kind, QuickKind.reminder);
    expect(e.dateLabel, 'پنجشنبه ۱۴ آبان');
    expect(e.timeLabel, '۱۰:۰۰');
    expect(e.category, 'سلامت');
    expect(e.title, 'دندانپزشکی');
  });

  test('monthly rent is a recurring payment', () {
    final e = parseQuickEntry('هر ماه پنجم اجاره ۱۲ میلیون');
    expect(e.kind, QuickKind.recurringPayment);
    expect(e.recurrenceLabel, 'هر ماه · روز ۵');
    expect(e.category, 'مسکن');
    expect(e.amountToman, 12000000);
  });

  test('duration is not an amount or a time', () {
    final e = parseQuickEntry('۲۰ دقیقه کتاب خواندم');
    expect(e.kind, QuickKind.task);
    expect(e.durationMinutes, 20);
    expect(e.amountToman, isNull);
    expect(e.timeLabel, isNull);
  });

  test('weekdays resolve forward from Wednesday', () {
    expect(parseQuickEntry('شنبه جلسه').dateLabel, 'شنبه ۱۶ آبان');
    expect(parseQuickEntry('یکشنبه جلسه').dateLabel, 'یکشنبه ۱۷ آبان');
    expect(parseQuickEntry('پس‌فردا جلسه').dateLabel, 'جمعه ۱۵ آبان');
    expect(parseQuickEntry('چهارشنبه جلسه').dateLabel, 'چهارشنبه ۲۰ آبان');
  });

  test('evening hour and month rollover', () {
    expect(parseQuickEntry('ساعت ۸ شب فیلم').timeLabel, '۲۰:۰۰');
    final e = parseQuickEntry('جمعه ساعت ۹ مهمانی', todayDay: 29);
    expect(e.dateLabel, 'جمعه ۱ آذر');
  });

  test('empty and plain text', () {
    expect(parseQuickEntry('').isEmpty, isTrue);
    expect(parseQuickEntry('  ').kind, QuickKind.none);
    expect(parseQuickEntry('خرید نان').kind, QuickKind.task);
  });

  test('token offsets point into the original text', () {
    const s = 'ناهار ۴۵۰ تومن';
    final e = parseQuickEntry(s);
    for (final t in e.tokens) {
      expect(s.substring(t.start, t.end), t.text);
    }
  });
}
