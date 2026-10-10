import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/src/ui/painter.dart';
import 'package:xterm/xterm.dart';

const _white = Color(0xFFFFFFFF);
const _dark = Color(0xFF1D1F24);

TerminalPainter _painter({required Color background, double contrast = 1}) {
  final base = TerminalThemes.defaultTheme;
  return TerminalPainter(
    theme: TerminalTheme(
      cursor: base.cursor,
      selection: base.selection,
      foreground: base.foreground,
      background: background,
      black: base.black,
      white: base.white,
      red: base.red,
      green: base.green,
      yellow: base.yellow,
      blue: base.blue,
      magenta: base.magenta,
      cyan: base.cyan,
      brightBlack: base.brightBlack,
      brightRed: base.brightRed,
      brightGreen: base.brightGreen,
      brightYellow: base.brightYellow,
      brightBlue: base.brightBlue,
      brightMagenta: base.brightMagenta,
      brightCyan: base.brightCyan,
      brightWhite: base.brightWhite,
      searchHitBackground: base.searchHitBackground,
      searchHitBackgroundCurrent: base.searchHitBackgroundCurrent,
      searchHitForeground: base.searchHitForeground,
      minimumContrast: contrast,
    ),
    textStyle: const TerminalStyle(),
    textScaler: TextScaler.noScaling,
  );
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  group('TerminalPainter.ensureContrast', () {
    test('leaves colors alone by default', () {
      final painter = _painter(background: _white);
      const faint = Color(0xFFF5F5F5);

      expect(painter.ensureContrast(faint, _white), faint);
    });

    test('darkens text that is too light for a light background', () {
      final painter = _painter(background: _white, contrast: 3.5);
      // Dimmed near-white text, as a dark-themed app draws it on white.
      final faint = Color.lerp(_white, const Color(0xFFEBEBEB), 0.5)!;

      final result = painter.ensureContrast(faint, _white);

      expect(_contrast(result, _white), greaterThanOrEqualTo(3.5));
      // Only as much as needed, so dim text stays dimmer than normal text.
      expect(_contrast(result, _white), lessThan(3.6));
    });

    test('lightens text that is too dark for a dark background', () {
      final painter = _painter(background: _dark, contrast: 3.5);
      const subtle = Color(0xFF3A3A3A);

      final result = painter.ensureContrast(subtle, _dark);

      expect(_contrast(result, _dark), greaterThanOrEqualTo(3.5));
      expect(result.computeLuminance(), greaterThan(subtle.computeLuminance()));
    });

    test('keeps readable colors unchanged', () {
      final painter = _painter(background: _white, contrast: 3.5);
      const text = Color(0xFF1C1B1A);
      const red = Color(0xFFB91C1C);

      expect(painter.ensureContrast(text, _white), text);
      expect(painter.ensureContrast(red, _white), red);
    });
  });
}
