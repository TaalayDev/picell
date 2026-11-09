const int kMaxNameLength = 100;
const String _copyPrefix = 'Copy of ';

/// Name for a duplicate of [source]: "Copy of X", never "Copy of Copy of X",
/// and never longer than [kMaxNameLength] (the database column limit).
String copyName(String source) => normalizeCopyName('$_copyPrefix$source');

/// Collapses stacked "Copy of " prefixes into one and clamps the length.
/// Returns [name] unchanged when it is already fine.
String normalizeCopyName(String name) {
  var base = name;
  var prefixes = 0;
  while (base.startsWith(_copyPrefix) && base.length > _copyPrefix.length) {
    base = base.substring(_copyPrefix.length);
    prefixes++;
  }
  var result = prefixes > 0 ? '$_copyPrefix$base' : name;
  if (result.length > kMaxNameLength) {
    result = result.substring(0, kMaxNameLength).trimRight();
  }
  return result.isEmpty ? name.substring(0, name.length.clamp(1, kMaxNameLength)) : result;
}
