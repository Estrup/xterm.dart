import 'package:test/test.dart';
import 'package:xterm/core.dart';

void main() {
  group('Terminal SGR', () {
    int attrsAt(Terminal terminal, int x) =>
        terminal.buffer.lines[0].getAttributes(x);

    test('ignores CSI m sequences with a private marker', () {
      final terminal = Terminal();

      // XTMODKEYS set/reset, as sent by the Claude CLI.
      terminal.write('\x1b[>4;2mA\x1b[>4mB\x1b[?4mC');

      expect(attrsAt(terminal, 0), 0);
      expect(attrsAt(terminal, 1), 0);
      expect(attrsAt(terminal, 2), 0);
    });

    test('22 clears both bold and faint', () {
      final terminal = Terminal();

      terminal.write('\x1b[1mA\x1b[22mB\x1b[2mC\x1b[22mD');

      expect(attrsAt(terminal, 0), CellAttr.bold);
      expect(attrsAt(terminal, 1), 0);
      expect(attrsAt(terminal, 2), CellAttr.faint);
      expect(attrsAt(terminal, 3), 0);
    });
  });

  group('Terminal reported colors', () {
    test('answers OSC 10/11 queries once colors are set', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);

      terminal.write('\x1b]11;?\x1b\\');
      expect(output, isEmpty);

      terminal.setReportedColors(foreground: 0x1c1b1a, background: 0xffffff);
      terminal.write('\x1b]11;?\x07\x1b]10;?\x1b\\');

      expect(output, [
        '\x1b]11;rgb:ffff/ffff/ffff\x1b\\',
        '\x1b]10;rgb:1c1c/1b1b/1a1a\x1b\\',
      ]);
    });

    test('answers color scheme queries', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);

      terminal.setReportedColors(foreground: 0x000000, background: 0xffffff);
      terminal.write('\x1b[?996n');
      terminal.setReportedColors(foreground: 0xffffff, background: 0x1d1f24);
      terminal.write('\x1b[?996n');

      expect(output, ['\x1b[?997;2n', '\x1b[?997;1n']);
    });

    test('notifies scheme changes only when mode 2031 is on', () {
      final output = <String>[];
      final terminal = Terminal(onOutput: output.add);
      terminal.setReportedColors(foreground: 0xffffff, background: 0x1d1f24);

      terminal.setReportedColors(foreground: 0x000000, background: 0xffffff);
      expect(output, isEmpty);

      terminal.write('\x1b[?2031h');
      // Same scheme, different color: no notification.
      terminal.setReportedColors(foreground: 0x000000, background: 0xf5f5f5);
      expect(output, isEmpty);

      terminal.setReportedColors(foreground: 0xffffff, background: 0x1d1f24);
      expect(output, ['\x1b[?997;1n']);

      terminal.write('\x1b[?2031l');
      terminal.setReportedColors(foreground: 0x000000, background: 0xffffff);
      expect(output, ['\x1b[?997;1n']);
    });

    test('still passes color assignments to onPrivateOSC', () {
      final private = <String>[];
      final terminal = Terminal(onPrivateOSC: (code, _) => private.add(code));
      terminal.setReportedColors(foreground: 0x000000, background: 0xffffff);

      terminal.write('\x1b]11;#000000\x07');

      expect(private, ['11']);
    });
  });

  group('Terminal.inputHandler', () {
    test('can be set to null', () {
      final terminal = Terminal(inputHandler: null);
      expect(() => terminal.keyInput(TerminalKey.keyA), returnsNormally);
    });

    test('can be changed', () {
      final handler1 = _TestInputHandler();
      final handler2 = _TestInputHandler();
      final terminal = Terminal(inputHandler: handler1);

      terminal.keyInput(TerminalKey.keyA);
      expect(handler1.events, isNotEmpty);

      terminal.inputHandler = handler2;

      terminal.keyInput(TerminalKey.keyA);
      expect(handler2.events, isNotEmpty);
    });
  });

  group('Terminal.mouseInput', () {
    test('can handle mouse events', () {
      final output = <String>[];

      final terminal = Terminal(onOutput: output.add);

      terminal.mouseInput(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(10, 10),
      );

      expect(output, isEmpty);

      // enable mouse reporting
      terminal.write('\x1b[?1000h');

      terminal.mouseInput(
        TerminalMouseButton.left,
        TerminalMouseButtonState.down,
        CellOffset(10, 10),
      );

      expect(output, ['\x1B[M +,']);
    });
  });

  group('Terminal.reflowEnabled', () {
    test('prevents reflow when set to false', () {
      final terminal = Terminal(reflowEnabled: false);

      terminal.write('Hello World');
      terminal.resize(5, 5);

      expect(terminal.buffer.lines[0].toString(), 'Hello');
      expect(terminal.buffer.lines[1].toString(), isEmpty);
    });

    test('preserves hidden cells when reflow is disabled', () {
      final terminal = Terminal(reflowEnabled: false);

      terminal.write('Hello World');
      terminal.resize(5, 5);
      terminal.resize(20, 5);

      expect(terminal.buffer.lines[0].toString(), 'Hello World');
      expect(terminal.buffer.lines[1].toString(), isEmpty);
    });

    test('can be set at runtime', () {
      final terminal = Terminal(reflowEnabled: true);

      terminal.resize(5, 5);
      terminal.write('Hello World');
      terminal.reflowEnabled = false;
      terminal.resize(20, 5);

      expect(terminal.buffer.lines[0].toString(), 'Hello');
      expect(terminal.buffer.lines[1].toString(), ' Worl');
      expect(terminal.buffer.lines[2].toString(), 'd');
    });
  });

  group('Terminal.mouseInput', () {
    test('applys to the main buffer', () {
      final terminal = Terminal(
        wordSeparators: {
          'z'.codeUnitAt(0),
        },
      );

      expect(
        terminal.mainBuffer.wordSeparators,
        contains('z'.codeUnitAt(0)),
      );
    });

    test('applys to the alternate buffer', () {
      final terminal = Terminal(
        wordSeparators: {
          'z'.codeUnitAt(0),
        },
      );

      expect(
        terminal.altBuffer.wordSeparators,
        contains('z'.codeUnitAt(0)),
      );
    });
  });

  group('Terminal.onPrivateOSC', () {
    test(r'works with \a end', () {
      String? lastCode;
      List<String>? lastData;

      final terminal = Terminal(
        onPrivateOSC: (String code, List<String> data) {
          lastCode = code;
          lastData = data;
        },
      );

      terminal.write('\x1b]6\x07');

      expect(lastCode, '6');
      expect(lastData, []);

      terminal.write('\x1b]66;hello world\x07');

      expect(lastCode, '66');
      expect(lastData, ['hello world']);

      terminal.write('\x1b]666;hello;world\x07');

      expect(lastCode, '666');
      expect(lastData, ['hello', 'world']);

      terminal.write('\x1b]hello;world\x07');

      expect(lastCode, 'hello');
      expect(lastData, ['world']);
    });

    test(r'works with \x1b\ end', () {
      String? lastCode;
      List<String>? lastData;

      final terminal = Terminal(
        onPrivateOSC: (String code, List<String> data) {
          lastCode = code;
          lastData = data;
        },
      );

      terminal.write('\x1b]6\x1b\\');

      expect(lastCode, '6');
      expect(lastData, []);

      terminal.write('\x1b]66;hello world\x1b\\');

      expect(lastCode, '66');
      expect(lastData, ['hello world']);

      terminal.write('\x1b]666;hello;world\x1b\\');

      expect(lastCode, '666');
      expect(lastData, ['hello', 'world']);

      terminal.write('\x1b]hello;world\x1b\\');

      expect(lastCode, 'hello');
      expect(lastData, ['world']);
    });

    test('do not receive common osc', () {
      String? lastCode;
      List<String>? lastData;

      final terminal = Terminal(
        onPrivateOSC: (String code, List<String> data) {
          lastCode = code;
          lastData = data;
        },
      );

      terminal.write('\x1b]0;hello world\x07');

      expect(lastCode, isNull);
      expect(lastData, isNull);
    });
  });
}

class _TestInputHandler implements TerminalInputHandler {
  final events = <TerminalKeyboardEvent>[];

  @override
  String? call(TerminalKeyboardEvent event) {
    events.add(event);
    return null;
  }
}
