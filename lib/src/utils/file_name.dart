import 'package:path/path.dart' as p;

/// Joins [folderPath] and the base name of [name], so the result always stays
/// directly inside [folderPath].
///
/// Media names can come from untrusted input (URLs, uploads), so an absolute
/// name or one with `..` segments must not be able to escape the folder.
/// Throws an [ArgumentError] when [name] has no usable base name (empty, `.`,
/// `..`, or ending in a separator).
String joinSafeFileName(String folderPath, String name) {
  final base = p.basename(name);
  if (base.isEmpty || base == '.' || base == '..' || name.endsWith(p.separator) || name.endsWith('/')) {
    throw ArgumentError.value(name, 'name', 'is not a valid file name');
  }
  return p.join(folderPath, base);
}
