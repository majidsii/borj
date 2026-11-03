import 'package:flutter/material.dart';

import 'error_report.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  installSpikeErrorHooks();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: spikeErrorOverlay,
      home: const Scaffold(
        body: Center(
          child: Text(
            'A plain OK',
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}
