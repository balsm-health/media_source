import 'package:path/path.dart' as p;

/// Characters Windows doesn't allow in file names. `:` also selects an NTFS
/// alternate data stream (`report.pdf:hidden`), which would hide the data
/// inside another file.
final _windowsInvalidChars = RegExp(r'[<>:"|?*\x00-\x1F]');

/// Windows device names, reserved with or without an extension (`NUL.txt`).
final _windowsReservedNames = RegExp(r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\..*)?$', caseSensitive: false);

/// Joins [folderPath] and the base name of [name], so the result always stays
/// directly inside [folderPath].
///
/// Media names can come from untrusted input (URLs, uploads), so an absolute
/// name or one with `..` segments must not be able to escape the folder.
/// Throws an [ArgumentError] when [name] has no usable base name (empty, `.`,
/// `..`, ending in a separator, or containing a NUL character).
///
/// On Windows it also rejects names Windows can't store as a plain file:
/// reserved characters (including `:`, which would write to an alternate data
/// stream), control characters, device names such as `CON` or `NUL.txt`, and
/// names ending in a dot or space.
///
/// [context] selects the path style and defaults to the current platform.
String joinSafeFileName(String folderPath, String name, {p.Context? context}) {
  final ctx = context ?? p.context;
  final base = ctx.basename(name);
  final invalid =
      base.isEmpty ||
      base == '.' ||
      base == '..' ||
      name.endsWith(ctx.separator) ||
      name.endsWith('/') ||
      base.contains('\x00') ||
      (ctx.style == p.Style.windows && _isUnsafeOnWindows(base));
  if (invalid) {
    throw ArgumentError.value(name, 'name', 'is not a valid file name');
  }
  return ctx.join(folderPath, base);
}

bool _isUnsafeOnWindows(String base) =>
    _windowsInvalidChars.hasMatch(base) ||
    _windowsReservedNames.hasMatch(base) ||
    base.endsWith('.') ||
    base.endsWith(' ');
