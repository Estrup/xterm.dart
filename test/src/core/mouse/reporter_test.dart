import 'package:test/test.dart';
import 'package:xterm/src/core/mouse/reporter.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('MouseReporter', () {
    test('report() supports normal mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.normal,
      );

      expect(output, equals('\x1B[M !"'));
    });

    test('report() supports utf mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.utf,
      );

      expect(output, equals('\x1B[M !"'));
    });

    test('report() supports sgr mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.sgr,
      );

      expect(output, equals('\x1B[<0;1;1M'));
    });

    test('report() encodes wheel buttons without modifier bits', () {
      String sgr(TerminalMouseButton button) => MouseReporter.report(
            button,
            TerminalMouseButtonState.down,
            CellOffset(0, 0),
            MouseReportMode.sgr,
          );

      expect(sgr(TerminalMouseButton.wheelUp), equals('\x1B[<64;1;1M'));
      expect(sgr(TerminalMouseButton.wheelDown), equals('\x1B[<65;1;1M'));
      expect(sgr(TerminalMouseButton.wheelLeft), equals('\x1B[<66;1;1M'));
      expect(sgr(TerminalMouseButton.wheelRight), equals('\x1B[<67;1;1M'));

      final normal = MouseReporter.report(
        TerminalMouseButton.wheelUp,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.normal,
      );
      expect(normal, equals('\x1B[M`!"'));
    });

    test('report() supports urxvt mode', () {
      final output = MouseReporter.report(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(0, 0),
        MouseReportMode.urxvt,
      );

      expect(output, equals('\x1B[32;1;1M'));
    });
  });
}
