import 'package:borj/app/design/patterns/spring_curve.dart';
import 'package:borj/app/theme/app_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts at 0, ends at 1, soft overshoots, standard does not', () {
    final soft = SpringCurve(AppMotion.soft);
    final standard = SpringCurve(AppMotion.standard);
    expect(soft.transform(0), 0);
    expect(soft.transform(1), 1);
    final samples = [for (var i = 1; i < 100; i++) soft.transform(i / 100)];
    expect(samples.any((v) => v > 1.0), isTrue);
    final std = [for (var i = 1; i < 100; i++) standard.transform(i / 100)];
    expect(std.every((v) => v <= 1.0001), isTrue);
  });

  test('settle durations are finite and ordered', () {
    final snappy = SpringCurve.settleDuration(AppMotion.snappy);
    final standard = SpringCurve.settleDuration(AppMotion.standard);
    expect(snappy, lessThan(standard));
    expect(standard, lessThan(const Duration(seconds: 1)));
  });
}
