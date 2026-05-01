import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  testWidgets('render coordinates are not offset by MediaQuery padding', (
    tester,
  ) async {
    final key = GlobalKey<TerminalViewState>();
    final terminal = Terminal();

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(left: 24, top: 32),
          ),
          child: SizedBox(
            width: 400,
            height: 240,
            child: TerminalView(terminal, key: key, readOnly: true),
          ),
        ),
      ),
    );

    expect(
      key.currentState!.renderTerminal.getOffset(CellOffset(0, 0)),
      Offset.zero,
    );
  });
}
