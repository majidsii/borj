import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the adapter and bootstrap import liquid_glass_renderer', () {
    const allowed = {
      'lib/app/apple_visual/widgets/apple_liquid_glass.dart',
      'lib/app/bootstrap/app_bootstrap.dart',
    };
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where(
          (f) => f.readAsStringSync().contains('package:liquid_glass_renderer'),
        )
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where((p) => !allowed.contains(p))
        .toList();
    expect(offenders, isEmpty);
  });
}
