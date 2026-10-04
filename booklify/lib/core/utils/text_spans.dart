/// A slice of a larger text, with offsets into the original string.
class TextSpanRange {
  final int start;
  final int end;

  const TextSpanRange(this.start, this.end);

  String of(String text) => text.substring(start, end);
}

final _blankLine = RegExp(r'\r?\n[ \t]*\r?\n');
final _lineBreak = RegExp(r'\r?\n');

/// Splits [text] into paragraphs, returning offsets into [text] itself so
/// callers can slice the original book content.
///
/// Paragraphs are separated by blank lines (`\n\n` or Windows `\r\n\r\n`).
/// If that yields a single paragraph — text written with one line break
/// between paragraphs — single line breaks are used instead.
List<TextSpanRange> splitParagraphs(String text) {
  final byBlank = _split(text, _blankLine);
  if (byBlank.length > 1) return byBlank;
  return _split(text, _lineBreak);
}

List<TextSpanRange> _split(String text, RegExp separator) {
  final spans = <TextSpanRange>[];
  var cursor = 0;
  for (final m in separator.allMatches(text)) {
    _addTrimmed(spans, text, cursor, m.start);
    cursor = m.end;
  }
  _addTrimmed(spans, text, cursor, text.length);
  return spans;
}

/// Adds [start, end) to [spans] with surrounding whitespace excluded.
void _addTrimmed(List<TextSpanRange> spans, String text, int start, int end) {
  final range = trimRange(text, start, end);
  if (range != null) spans.add(range);
}

/// [start, end) narrowed to exclude leading/trailing whitespace, or null if
/// the range is blank.
TextSpanRange? trimRange(String text, int start, int end) {
  while (start < end && _isSpace(text.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isSpace(text.codeUnitAt(end - 1))) {
    end--;
  }
  return end > start ? TextSpanRange(start, end) : null;
}

bool _isSpace(int c) => c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D || c == 0xA0;

/// Word count that treats any whitespace (including line breaks) as a gap.
int countWords(String text) =>
    text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

/// [text] with Windows line endings normalised to `\n` (for display only —
/// offsets always refer to the original string).
String normalizeLineEndings(String text) => text.replaceAll('\r\n', '\n');

/// Splits [count] items into [groups] runs that differ in size by at most one.
/// Returns the start index of each group plus a final [count].
List<int> evenGroupBounds(int count, int groups) {
  final g = groups.clamp(1, count < 1 ? 1 : count);
  return List.generate(g + 1, (i) => (i * count) ~/ g);
}
