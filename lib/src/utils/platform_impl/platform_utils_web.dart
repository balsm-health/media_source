import 'dart:async';
import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
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

  /// Performs the HTTP requests behind [fileExists]. Replaceable in tests.
  @visibleForTesting
  static Future<web.Response> Function(String url, web.RequestInit init) fetch = _windowFetch;

  /// How long one existence request may take before the resource is treated
  /// as unreachable. Replaceable in tests.
  @visibleForTesting
  static Duration fetchTimeout = const Duration(seconds: 10);

  static Future<web.Response> _windowFetch(String url, web.RequestInit init) => web.window.fetch(url.toJS, init).toDart;

  /// HEAD statuses that mean "this server won't answer HEAD", not "missing":
  /// S3/GCS presigned URLs sign the method (403), and some servers or CDNs
  /// reject HEAD outright (405/501).
  static const _headRejectedStatuses = {403, 405, 501};

  /// Checks that the [XFile]'s resource is reachable without downloading it.
  ///
  /// `blob:` / `data:` URLs are fetched and the body is cancelled unread
  /// (blob URLs only support GET); other URLs get a `HEAD` request, retried as
  /// a one-byte ranged `GET` when the server rejects HEAD (403/405/501). Any
  /// other HTTP response is authoritative: a revoked blob or a 404 reports
  /// `false`, even if the [XFile] caches bytes (use `XFile.fromData` for
  /// in-memory data). Each request times out after [fetchTimeout] and then
  /// reports `false`. Only when the request itself fails (e.g. network or
  /// CORS error) does this fall back to reading the bytes.
  @override
  Future<bool> fileExists(XFile xFile) async {
    final path = xFile.path;
    if (path.isEmpty) return false;
    final reachable = await _isReachable(path);
    if (reachable != null) return reachable;
    try {
      await xFile.readAsBytes();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Returns whether [url] answered with a success status, or `null` when
  /// the request failed without a usable response.
  ///
  /// A revoked blob URL rejects the fetch, so for `blob:` / `data:` URLs a
  /// failure is a definite `false` rather than `null`.
  Future<bool?> _isReachable(String url) async {
    final inMemory = url.startsWith('blob:') || url.startsWith('data:');
    try {
      if (inMemory) return await _probe(url, 'GET');
      final status = await _status(url, 'HEAD');
      if (!_headRejectedStatuses.contains(status)) return status >= 200 && status < 300;
      return await _probe(url, 'GET', rangeFirstByte: true);
    } on TimeoutException {
      return false;
    } catch (e) {
      return inMemory ? false : null;
    }
  }

  /// Sends [method] to [url] and returns the status, cancelling any body.
  Future<int> _status(String url, String method, {bool rangeFirstByte = false}) async {
    final controller = web.AbortController();
    final headers = web.Headers();
    if (rangeFirstByte) headers.append('Range', 'bytes=0-0');
    final init = web.RequestInit(method: method, headers: headers, signal: controller.signal);
    final response = await fetch(url, init).timeout(
      fetchTimeout,
      onTimeout: () {
        controller.abort();
        throw TimeoutException('fileExists: $method $url timed out', fetchTimeout);
      },
    );
    await response.body?.cancel().toDart;
    return response.status;
  }

  Future<bool> _probe(String url, String method, {bool rangeFirstByte = false}) async {
    final status = await _status(url, method, rangeFirstByte: rangeFirstByte);
    return status >= 200 && status < 300;
  }
}
