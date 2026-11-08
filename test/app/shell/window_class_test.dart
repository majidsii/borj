import 'package:borj/app/shell/window_class.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('breakpoints at 600 and 1024', () {
    expect(WindowClass.forWidth(320), WindowClass.compact);
    expect(WindowClass.forWidth(599), WindowClass.compact);
    expect(WindowClass.forWidth(599.9), WindowClass.compact);
    expect(WindowClass.forWidth(600), WindowClass.medium);
    expect(WindowClass.forWidth(1023), WindowClass.medium);
    expect(WindowClass.forWidth(1023.9), WindowClass.medium);
    expect(WindowClass.forWidth(1024), WindowClass.expanded);
    expect(WindowClass.forWidth(1440), WindowClass.expanded);
  });

  testWidgets('of(context) follows the window width', (tester) async {
    WindowClass? seen;
    Future<void> pumpAt(double width) async {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              seen = WindowClass.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
    }

    await pumpAt(599);
    expect(seen, WindowClass.compact);
    await pumpAt(1024);
    expect(seen, WindowClass.expanded);
  });
}
