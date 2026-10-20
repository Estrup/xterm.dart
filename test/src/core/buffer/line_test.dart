import 'package:test/test.dart';
import 'package:xterm/xterm.dart';

void main() {
  group('BufferLine.getText()', () {
    test('should return the text', () {
      final terminal = Terminal();
      terminal.write('Hello World');
      expect(terminal.buffer.lines[0].getText(), 'Hello World');
    });

    test('getText() should support wide characters', () {
      final text = '😀😁😂🤣😃';
      final terminal = Terminal();
      terminal.write(text);
      expect(terminal.buffer.lines[0].getText(), equals(text));
    });

    test('can specify a range', () {
      final terminal = Terminal();
      terminal.write('Hello World');
      expect(terminal.buffer.lines[0].getText(0, 5), 'Hello');
    });

    test('can handle invalid ranges', () {
      final terminal = Terminal();
      terminal.write('Hello World');
      expect(terminal.buffer.lines[0].getText(0, 100), 'Hello World');
    });

    test('can handle negative ranges', () {
      final terminal = Terminal();
      terminal.write('Hello World');
      expect(terminal.buffer.lines[0].getText(-100, 100), 'Hello World');
    });

    test('can handle reversed ranges', () {
      final terminal = Terminal();
      terminal.write('Hello World');
      expect(terminal.buffer.lines[0].getText(5, 0), '');
    });

    test('cells skipped by cursor movement are spaces', () {
      final terminal = Terminal();
      // Cursor Forward over the blanks, the way Claude Code draws text.
      terminal.write('Begge\x1b[1Cbilleder\x1b[3Cviser\x1b[10C');
      expect(terminal.buffer.lines[0].getText(), 'Begge billeder   viser');
      expect(terminal.buffer.lines[0].getText(0, 8), 'Begge bi');
      expect(terminal.buffer.lines[0].getText(5, 7), ' b');
    });

    test('erased cells inside the text are spaces', () {
      final terminal = Terminal();
      terminal.write('Hello World\x1b[6G\x1b[1X');
      expect(terminal.buffer.lines[0].getText(), 'Hello World');
    });

    test('blank cells next to wide characters', () {
      final terminal = Terminal();
      terminal.write('😀\x1b[1Ca😁');
      expect(terminal.buffer.lines[0].getText(), '😀 a😁');
      // Starting on the second half of a wide character adds nothing.
      expect(terminal.buffer.lines[0].getText(1), ' a😁');
    });
  });

  group('BufferLine.getTrimmedLength()', () {
    test('can get trimmed length', () {
      final line = BufferLine(10);

      final text = 'ABCDEF';

      for (var i = 0; i < text.length; i++) {
        line.setCodePoint(i, text.codeUnitAt(i));
      }

      expect(line.getTrimmedLength(), equals(text.length));
    });

    test('can get trimmed length with wide characters', () {
      final terminal = Terminal();
      final text = '😀😁😂🤣😃';

      terminal.write(text);

      expect(terminal.buffer.lines[0].getTrimmedLength(), equals(text.length));
    });

    test('can handle length larger than the line', () {
      final line = BufferLine(10);

      final text = 'ABCDEF';

      for (var i = 0; i < text.length; i++) {
        line.setCodePoint(i, text.codeUnitAt(i));
      }

      expect(line.getTrimmedLength(1000), equals(text.length));
    });

    test('can handle negative start', () {
      final line = BufferLine(10);

      final text = 'ABCDEF';

      for (var i = 0; i < text.length; i++) {
        line.setCodePoint(i, text.codeUnitAt(i));
      }

      expect(line.getTrimmedLength(-1000), equals(0));
    });
  });

  group('BufferLine.resize', () {
    test('can resize', () {
      final line = BufferLine(10);

      final text = 'ABCDEF';

      for (var i = 0; i < text.length; i++) {
        line.setCodePoint(i, text.codeUnitAt(i));
      }

      line.resize(20);

      expect(line.length, equals(20));
    });
  });

  group('Buffer.createAnchor', () {
    test('works', () {
      final terminal = Terminal();
      final line = terminal.buffer.lines[3];
      final anchor = line.createAnchor(5);

      terminal.insertLines(5);
      expect(anchor.x, 5);
      expect(anchor.y, 8);

      terminal.buffer.clear();
      expect(line.attached, false);
      expect(anchor.attached, false);
    });
  });
}
