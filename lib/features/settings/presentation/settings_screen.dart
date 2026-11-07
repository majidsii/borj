import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:borj/app/widgets/aurora_background.dart';
import 'package:borj/features/legacy_import/presentation/legacy_import_section.dart';
import 'package:borj/features/settings/presentation/appearance_section.dart';
import 'package:flutter/material.dart';

final class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = OriginalPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageTopPadding,
              OriginalDesignTokens.pageHorizontalPadding,
              OriginalDesignTokens.pageBottomPadding,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: OriginalDesignTokens.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          key: const ValueKey<String>('settings-back'),
                          tooltip: 'بازگشت',
                          onPressed: onBack,
                          icon: Icon(Icons.arrow_forward, color: palette.ink),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'تنظیمات',
                          style: TextStyle(
                            color: palette.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const AppearanceSection(),
                    const SizedBox(height: 20),
                    const LegacyImportSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
