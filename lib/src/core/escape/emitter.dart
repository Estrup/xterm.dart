class EscapeEmitter {
  const EscapeEmitter();

  String primaryDeviceAttributes() {
    return '\x1b[?1;2c';
  }

  String secondaryDeviceAttributes() {
    const model = 0;
    const version = 0;
    return '\x1b[>$model;$version;0c';
  }

  String tertiaryDeviceAttributes() {
    return '\x1bP!|00000000\x1b\\';
  }

  String operatingStatus() {
    return '\x1b[0n';
  }

  String cursorPosition(int x, int y) {
    return '\x1b[$y;${x}R';
  }

  /// Reply to an OSC 10 / 11 color query: [rgb] (0xRRGGBB) in the
  /// 16-bit-per-channel form xterm uses.
  String defaultColor(int code, int rgb) {
    String channel(int shift) =>
        ((rgb >> shift) & 0xFF).toRadixString(16).padLeft(2, '0') * 2;
    return '\x1b]$code;rgb:${channel(16)}/${channel(8)}/${channel(0)}\x1b\\';
  }

  /// Color scheme report (`CSI ? 997 ; Ps n`): 1 is dark, 2 is light.
  String colorScheme({required bool dark}) {
    return '\x1b[?997;${dark ? 1 : 2}n';
  }

  String bracketedPaste(String text) {
    return '\x1b[200~$text\x1b[201~';
  }

  String size(int rows, int cols) {
    return '\x1b[8;$rows;${cols}t';
  }
}
