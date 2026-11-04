// SPIKE: pure-Dart natural Persian quick-entry parser (no Flutter imports).

/// Kind of recognised token.
enum QuickTokenType {
  amount,
  date,
  time,
  recurrence,
  category,
  account,
  duration,
}

/// What the whole sentence is interpreted as.
enum QuickKind { none, expense, task, reminder, recurringPayment }

/// A recognised span of the input text.
class QuickToken {
  const QuickToken({
    required this.type,
    required this.start,
    required this.end,
    required this.text,
    required this.label,
  });

  final QuickTokenType type;
  final int start;
  final int end;

  /// Original text of the span.
  final String text;

  /// Human readable (Persian digits) interpretation shown on the chip.
  final String label;

  /// Stable identity used to match chips between keystrokes.
  String get key => '${type.name}:$text';
}

/// Structured interpretation of a sentence.
class QuickEntry {
  const QuickEntry({
    required this.tokens,
    required this.kind,
    required this.title,
    this.amountToman,
    this.category,
    this.account,
    this.dateLabel,
    this.timeLabel,
    this.recurrenceLabel,
    this.durationMinutes,
  });

  final List<QuickToken> tokens;
  final QuickKind kind;
  final String title;
  final int? amountToman;
  final String? category;
  final String? account;
  final String? dateLabel;
  final String? timeLabel;
  final String? recurrenceLabel;
  final int? durationMinutes;

  bool get isEmpty => kind == QuickKind.none;
}

const String _faDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Persian digits for [input] (ASCII digits are converted).
String faDigits(String input) {
  final out = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x30 && unit <= 0x39) {
      out.write(_faDigits[unit - 0x30]);
    } else {
      out.write(String.fromCharCode(unit));
    }
  }
  return out.toString();
}

/// Groups digits with the Persian thousands separator.
String faGrouped(int value) {
  final s = value.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      b.write('٬');
    }
    b.write(s[i]);
  }
  return faDigits(b.toString());
}

/// Same-length normalisation: Persian/Arabic digits to ASCII, Arabic letter
/// variants to Persian. Offsets stay valid for the original text.
String normalizeQuickText(String input) {
  final out = StringBuffer();
  for (final unit in input.runes) {
    if (unit >= 0x06F0 && unit <= 0x06F9) {
      out.writeCharCode(0x30 + unit - 0x06F0);
    } else if (unit >= 0x0660 && unit <= 0x0669) {
      out.writeCharCode(0x30 + unit - 0x0660);
    } else if (unit == 0x064A) {
      out.writeCharCode(0x06CC);
    } else if (unit == 0x0643) {
      out.writeCharCode(0x06A9);
    } else {
      out.writeCharCode(unit);
    }
  }
  return out.toString();
}

const List<String> kWeekdayNames = <String>[
  'شنبه',
  'یکشنبه',
  'دوشنبه',
  'سه‌شنبه',
  'چهارشنبه',
  'پنجشنبه',
  'جمعه',
];

const List<String> kJalaliMonths = <String>[
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

int _monthLength(int month) => month <= 6 ? 31 : (month <= 11 ? 30 : 29);

/// Jalali label such as «پنجشنبه ۱۴ آبان», [days] after the reference day.
String jalaliDayLabel({
  required int weekday,
  required int month,
  required int day,
  required int days,
}) {
  var m = month;
  var d = day + days;
  while (d > _monthLength(m)) {
    d -= _monthLength(m);
    m = m == 12 ? 1 : m + 1;
  }
  final wd = kWeekdayNames[(weekday + days) % 7];
  return faDigits('$wd $d ${kJalaliMonths[m - 1]}');
}

const String _b = r'(?<![\p{L}\d])';
const String _e = r'(?![\p{L}\d])';

const Map<String, int> _ordinals = <String, int>{
  'اول': 1,
  'دوم': 2,
  'سوم': 3,
  'چهارم': 4,
  'پنجم': 5,
  'ششم': 6,
  'هفتم': 7,
  'هشتم': 8,
  'نهم': 9,
  'دهم': 10,
  'پانزدهم': 15,
  'بیستم': 20,
  'سی‌ام': 30,
};

const Map<String, String> _categories = <String, String>{
  'ناهار': 'خوراک',
  'شام': 'خوراک',
  'صبحانه': 'خوراک',
  'سوپرمارکت': 'خوراک',
  'رستوران': 'خوراک',
  'کافه': 'خوراک',
  'اسنپ': 'رفت‌وآمد',
  'تاکسی': 'رفت‌وآمد',
  'بنزین': 'رفت‌وآمد',
  'مترو': 'رفت‌وآمد',
  'اجاره': 'مسکن',
  'قبض': 'مسکن',
  'دندانپزشکی': 'سلامت',
  'دارو': 'سلامت',
  'سینما': 'تفریح',
};

/// Parses [input]. Reference "today" defaults to Wednesday 13 Aban 1405.
QuickEntry parseQuickEntry(
  String input, {
  int todayWeekday = 4,
  int todayMonth = 8,
  int todayDay = 13,
}) {
  final text = normalizeQuickText(input);
  final tokens = <QuickToken>[];
  int? amount;
  int? minutes;
  String? category;
  String? account;
  String? dateLabel;
  String? timeLabel;
  String? recurrence;
  var dayOffset = -1;

  bool free(int s, int e) => tokens.every((t) => e <= t.start || s >= t.end);

  void add(Match m, QuickTokenType type, String label) {
    if (!free(m.start, m.end)) {
      return;
    }
    tokens.add(
      QuickToken(
        type: type,
        start: m.start,
        end: m.end,
        text: input.substring(m.start, m.end),
        label: label,
      ),
    );
  }

  RegExp re(String p) => RegExp(p, unicode: true);

  // Recurrence (+ optional ordinal day of month).
  final ordAlt = _ordinals.keys.join('|');
  for (final m in re(
    '$_bهر\\s+(روز|هفته|ماه|سال)(?:\\s+($ordAlt|\\d{1,2}\\s*ام))?$_e',
  ).allMatches(text)) {
    final unit = m.group(1)!;
    final ord = m.group(2);
    var label = 'هر $unit';
    if (ord != null) {
      final n = _ordinals[ord] ?? int.parse(ord.replaceAll(RegExp(r'\D'), ''));
      label = 'هر $unit · روز $n';
    }
    recurrence = faDigits(label);
    add(m, QuickTokenType.recurrence, recurrence);
  }

  // Time: «ساعت ۱۰», «ساعت ۱۰:۳۰», optional day-part.
  for (final m in re(
    '$_bساعت\\s*(\\d{1,2})(?:[:٫.](\\d{2}))?(?:\\s*(صبح|ظهر|عصر|شب))?$_e',
  ).allMatches(text)) {
    var h = int.parse(m.group(1)!);
    final min = int.tryParse(m.group(2) ?? '0') ?? 0;
    final part = m.group(3);
    if ((part == 'عصر' || part == 'شب') && h < 12) {
      h += 12;
    }
    if (h > 23 || min > 59) {
      continue;
    }
    final label = faDigits(
      '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}',
    );
    timeLabel = label;
    add(m, QuickTokenType.time, label);
  }

  // Duration: «۲۰ دقیقه», «۲ ساعت».
  for (final m in re('$_b(\\d+)\\s*(دقیقه|ساعت)$_e').allMatches(text)) {
    final n = int.parse(m.group(1)!);
    final mins = m.group(2) == 'ساعت' ? n * 60 : n;
    if (free(m.start, m.end)) {
      minutes = mins;
    }
    add(m, QuickTokenType.duration, faDigits('${m.group(1)} ${m.group(2)}'));
  }

  // Amount: number + (میلیون|هزار) + optional تومان, or number + تومان.
  for (final m in re(
    '$_b(\\d+(?:[.٫]\\d+)?)\\s*(میلیون|هزار)?\\s*(تومان|تومن|ریال)?$_e',
  ).allMatches(text)) {
    final scale = m.group(2);
    final unit = m.group(3);
    final raw = double.parse(m.group(1)!.replaceAll('٫', '.'));
    if (scale == null && unit == null && raw < 1000) {
      continue;
    }
    var value = raw;
    if (scale == 'میلیون') {
      value *= 1000000;
    } else if (scale == 'هزار') {
      value *= 1000;
    }
    if (unit == 'ریال') {
      value /= 10;
    }
    if (!free(m.start, m.end)) {
      continue;
    }
    amount = value.round();
    add(m, QuickTokenType.amount, '${faGrouped(amount)} تومان');
  }

  // Account.
  for (final m in re('$_b(کارت\\s+[\\p{L}]+|نقدی|نقد)$_e').allMatches(text)) {
    account = input.substring(m.start, m.end);
    add(m, QuickTokenType.account, account);
  }

  // Dates.
  const wd =
      'یکشنبه|دوشنبه|سه‌شنبه|سه شنبه|چهارشنبه|پنجشنبه|پنج شنبه|'
      'شنبه|جمعه';
  for (final m in re('$_b(امروز|پس[‌ ]?فردا|فردا|$wd)$_e').allMatches(text)) {
    final w = m.group(1)!;
    int off;
    if (w == 'امروز') {
      off = 0;
    } else if (w == 'فردا') {
      off = 1;
    } else if (w.startsWith('پس')) {
      off = 2;
    } else {
      final idx = switch (w.replaceAll(' ', '').replaceAll('‌', '')) {
        'شنبه' => 0,
        'یکشنبه' => 1,
        'دوشنبه' => 2,
        'سهشنبه' => 3,
        'چهارشنبه' => 4,
        'پنجشنبه' => 5,
        _ => 6,
      };
      off = (idx - todayWeekday) % 7;
      if (off == 0) {
        off = 7;
      }
    }
    if (free(m.start, m.end) && dayOffset < 0) {
      dayOffset = off;
      dateLabel = jalaliDayLabel(
        weekday: todayWeekday,
        month: todayMonth,
        day: todayDay,
        days: off,
      );
      add(m, QuickTokenType.date, dateLabel);
    }
  }

  // Category keywords.
  for (final entry in _categories.entries) {
    for (final m in re('$_b${entry.key}$_e').allMatches(text)) {
      if (category == null && free(m.start, m.end)) {
        category = entry.value;
        add(m, QuickTokenType.category, entry.value);
      }
    }
  }

  tokens.sort((a, b) => a.start.compareTo(b.start));

  final wantsReminder = re('$_b(یادآوری|یادآور|یادم|زنگ)$_e').hasMatch(text);
  final QuickKind kind;
  if (text.trim().isEmpty) {
    kind = QuickKind.none;
  } else if (recurrence != null && amount != null) {
    kind = QuickKind.recurringPayment;
  } else if (amount != null) {
    kind = QuickKind.expense;
  } else if (wantsReminder ||
      (timeLabel != null && dateLabel != null && minutes == null)) {
    kind = QuickKind.reminder;
  } else if (tokens.isNotEmpty || text.trim().length > 2) {
    kind = QuickKind.task;
  } else {
    kind = QuickKind.none;
  }

  // Title: drop value tokens (keep category word), tidy fillers.
  final title = StringBuffer();
  var cursor = 0;
  for (final t in tokens) {
    if (t.type == QuickTokenType.category) {
      continue;
    }
    title.write(input.substring(cursor, t.start));
    title.write(' ');
    cursor = t.end;
  }
  title.write(input.substring(cursor));
  var clean = title.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  final filler = RegExp(r'^(از|به|در|برای|با)\s+|\s+(از|به|در|برای)$');
  while (filler.hasMatch(clean) && clean.contains(' ')) {
    clean = clean.replaceFirst(filler, '').trim();
  }

  return QuickEntry(
    tokens: List<QuickToken>.unmodifiable(tokens),
    kind: kind,
    title: clean,
    amountToman: amount,
    category: category,
    account: account,
    dateLabel: dateLabel,
    timeLabel: timeLabel,
    recurrenceLabel: recurrence,
    durationMinutes: minutes,
  );
}

/// Persian name of [kind].
String quickKindLabel(QuickKind kind) => switch (kind) {
  QuickKind.none => 'در انتظار',
  QuickKind.expense => 'خرج',
  QuickKind.task => 'کار',
  QuickKind.reminder => 'یادآور',
  QuickKind.recurringPayment => 'پرداخت تکراری',
};
