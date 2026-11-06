import 'package:borj/app/theme/original_design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the original HTML layout measurements', () {
    expect(OriginalDesignTokens.contentMaxWidth, 780);
    expect(OriginalDesignTokens.pageHorizontalPadding, 16);
    expect(OriginalDesignTokens.pageTopPadding, 24);
    expect(OriginalDesignTokens.glassBlurSigma, 28);
    expect(OriginalDesignTokens.glassRadius, 26);
    expect(OriginalDesignTokens.cardRadius, 28);
    expect(OriginalDesignTokens.fieldRadius, 16);
  });

  test('softens only the dark aurora decoration layer', () {
    expect(OriginalDesignTokens.darkAuroraDecorationBlurSigma, 20);
    expect(OriginalDesignTokens.darkSheenBandOpacityScale, .65);
  });

  test('keeps the original Apple accent palette', () {
    expect(OriginalDesignTokens.lightAccent.toARGB32(), 0xFF007AFF);
    expect(OriginalDesignTokens.darkAccent.toARGB32(), 0xFF0A84FF);
    expect(OriginalDesignTokens.lightIncome.toARGB32(), 0xFF34C759);
    expect(OriginalDesignTokens.darkIncome.toARGB32(), 0xFF30D158);
    expect(OriginalDesignTokens.lightExpense.toARGB32(), 0xFFFF3B30);
    expect(OriginalDesignTokens.darkExpense.toARGB32(), 0xFFFF453A);
  });
}
