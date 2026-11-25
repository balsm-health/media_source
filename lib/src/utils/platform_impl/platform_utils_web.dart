import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:media_source/src/utils/platform_utils.dart';
import 'package:web/web.dart' as web;

/// Web implementation of [PlatformUtilsFacade].
///
/// On web, file system semantics differ from native platforms. This class
/// provides web-friendly implementations that operate on blob URLs and
/// in-memory data. Certain operations like creating directories are
/// no-ops in the browser environment.
class PlatformUtilsFacadeImpl extends PlatformUtilsFacade {
  /// Deletes a blob URL created for an [XFile] by revoking it when possible.
  ///
  /// Returns `true` if the blob URL was revoked; otherwise `false`.
  @override
  Future<bool> deleteFile(XFile file) async {
    try {
      if (file.path.startsWith('blob:')) {
        web.URL.revokeObjectURL(file.path);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Directory creation is a no-op on the web; returns immediately.
  ///
  /// Web browsers do not have a traditional file system with directories.
  /// This method does nothing and returns successfully.
  @override
  Future<void> ensureParentDirectoryExists(String filePath) async {
    // No-op on web: browsers don't have directory structures
    return;
  }

  /// Renaming is not supported on the web; always returns `false` so callers
  /// fall back to copy + delete.
  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async => false;

  /// Directory existence checks always return `true` on web.
  ///
  /// Since web browsers don't have traditional directories, we return `true`
  /// to maintain API compatibility and avoid breaking calling code.
  @override
  Future<bool> directoryExists(String directoryPath) async {
    // Always true on web since there are no real directories to check
    return true;
  }

  /// Deleting directories is a no-op on web; always returns `true`.
  ///
  /// Since web browsers don't have traditional directories, this is a no-op
  /// that returns `true` for API compatibility.
  @override
  Future<bool> deleteDirectory(String directoryPath) async {
    // No-op on web: browsers don't have directory structures
    return true;
  }

  /// Checks that the [XFile]'s resource is reachable without downloading it.
  ///
  /// `blob:` / `data:` URLs are fetched and the body is cancelled unread
  /// (blob URLs only support GET); the fetch result is authoritative, so a
  /// revoked blob URL reports `false` even if the [XFile] still caches bytes.
  /// Other URLs get a `HEAD` request and, when that fails, fall back to
  /// reading the bytes, which covers an [XFile] created with cached `bytes`
  /// and a non-addressable path.
  @override
  Future<bool> fileExists(XFile xFile) async {
    final path = xFile.path;
    if (path.isEmpty) return false;
    final inMemory = path.startsWith('blob:') || path.startsWith('data:');
    if (await _isReachable(path, inMemory: inMemory)) return true;
    if (inMemory) return false;
    try {
      await xFile.readAsBytes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isReachable(String url, {required bool inMemory}) async {
    try {
      final response = await web.window.fetch(url.toJS, web.RequestInit(method: inMemory ? 'GET' : 'HEAD')).toDart;
      if (inMemory) await response.body?.cancel().toDart;
      return response.ok;
    } catch (e) {
      return false;
    }
  }
}
