/// URI helper extensions used by the package.
///
/// Adds convenient accessors for extracting file-related information from
/// `Uri` instances.
extension UriExtensions on Uri {
  /// Returns the base name of the URI path (e.g., 'video.mp4').
  ///
  /// Uses the last non-empty path segment, percent-decoded (so
  /// `my%20video.mp4` becomes `my video.mp4`). A trailing slash is skipped
  /// (`/videos/` gives `videos`). Returns an empty string when the URI has no
  /// non-empty path segment (e.g. `https://example.com` or `https://example.com/`).
  ///
  /// The decoded name is only used when it is a plain file name. If decoding
  /// would introduce a path separator or a `.`/`..` segment (e.g. `%2F`), or
  /// the encoding is invalid UTF-8, the raw encoded segment is returned
  /// instead, so a URL can never turn the name into a path.
  String get fileName {
    final segments = path.split('/').where((s) => s.isNotEmpty);
    if (segments.isEmpty) return '';
    final encoded = segments.last;
    final String decoded;
    try {
      decoded = Uri.decodeComponent(encoded);
    } catch (_) {
      return encoded;
    }
    final isPlainName = !decoded.contains('/') && !decoded.contains(r'\') && decoded != '.' && decoded != '..';
    return isPlainName ? decoded : encoded;
  }
}
