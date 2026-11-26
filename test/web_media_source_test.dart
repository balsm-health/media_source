@TestOn('browser')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_source/src/extensions/file_extensions.dart';
import 'package:media_source/src/sources/file_media_source.dart';
import 'package:media_source/src/sources/memory_media_source.dart';
import 'package:media_source/src/utils/platform_impl/platform_utils_web.dart';
import 'package:media_source/src/utils/platform_utils.dart';
import 'package:web/web.dart' as web;

/// Web-only behavior of saveTo / moveTo. On web, `XFile.saveTo` only triggers
/// a browser download, so the destination path is never addressable and the
/// returned sources must stay backed by a readable blob.
void main() {
  final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

  Future<DocumentFileMedia> blobFileMedia() =>
      DocumentFileMedia.fromFile(XFile.fromData(bytes, name: 'doc.pdf', mimeType: 'application/pdf'), name: 'doc.pdf');

  group('MemoryMediaSource.saveTo (web)', () {
    test('returns a blob-backed, readable and deletable file', () async {
      final memory = DocumentMemoryMedia(bytes, name: 'doc.pdf', mimeType: 'application/pdf');

      final saved = await memory.saveTo('downloads/doc.pdf');

      expect(saved.file.path, startsWith('blob:'));
      expect(await saved.file.readAsBytes(), bytes);
      expect(await saved.delete(), isTrue);
    });
  });

  group('FileMediaSource.saveTo (web)', () {
    test('keeps the original readable handle', () async {
      final media = await blobFileMedia();

      final saved = await media.saveTo('downloads/doc.pdf');

      expect(saved.file.path, media.file.path);
      expect(await saved.file.readAsBytes(), bytes);
      expect(saved.size, media.size);
    });
  });

  group('FileMediaSource.moveTo (web)', () {
    test('does not revoke the handle the returned source reads from', () async {
      final media = await blobFileMedia();

      final moved = await media.moveTo('downloads/moved.pdf');

      expect(await moved.file.exists(), isTrue);
      expect(await moved.file.readAsBytes(), bytes);
    });
  });

  group('PlatformUtils.fileExists (web)', () {
    test('is true for a live blob URL', () async {
      final file = XFile.fromData(bytes, name: 'a.bin');
      expect(await PlatformUtils.instance.fileExists(file), isTrue);
    });

    test('is false once the blob URL is revoked', () async {
      final file = XFile.fromData(bytes, name: 'a.bin');
      expect(await PlatformUtils.instance.deleteFile(file), isTrue);
      expect(await PlatformUtils.instance.fileExists(file), isFalse);
    });

    test('is false for an empty path', () async {
      expect(await PlatformUtils.instance.fileExists(XFile('')), isFalse);
    });

    test('is false for a URL that returns 404', () async {
      expect(await PlatformUtils.instance.fileExists(XFile('not/served/a.bin')), isFalse);
    });

    // The HTTP status is authoritative: a non-addressable path reports false
    // even when the XFile caches bytes. Use XFile.fromData for in-memory data.
    test('is false for a non-addressable path even with cached bytes', () async {
      final file = XFile('not/served/a.bin', bytes: bytes);
      expect(await PlatformUtils.instance.fileExists(file), isFalse);
    });
  });

  group('PlatformUtils.fileExists (web) with servers that reject HEAD', () {
    final originalFetch = PlatformUtilsFacadeImpl.fetch;
    final requests = <String>[];
    late List<int> statuses;

    setUp(() {
      requests.clear();
      PlatformUtilsFacadeImpl.fetch = (url, init) async {
        final range = (init.headers as web.Headers?)?.get('Range');
        requests.add('${init.method}${range == null ? '' : ' $range'}');
        return web.Response(null, web.ResponseInit(status: statuses.removeAt(0)));
      };
    });

    tearDown(() {
      PlatformUtilsFacadeImpl.fetch = originalFetch;
      PlatformUtilsFacadeImpl.fetchTimeout = const Duration(seconds: 10);
    });

    Future<bool> exists() => PlatformUtils.instance.fileExists(XFile('https://cdn.example/a.mp4'));

    for (final rejected in [403, 405, 501]) {
      test('retries a $rejected HEAD as a one-byte ranged GET', () async {
        statuses = [rejected, 206];
        expect(await exists(), isTrue);
        expect(requests, ['HEAD', 'GET bytes=0-0']);
      });
    }

    test('treats 416 on the ranged GET as an existing empty object', () async {
      statuses = [403, 416];
      expect(await exists(), isTrue);
    });

    test('reports false when the ranged GET is also refused', () async {
      statuses = [403, 403];
      expect(await exists(), isFalse);
    });

    test('treats 404 on HEAD as missing without a GET', () async {
      statuses = [404];
      expect(await exists(), isFalse);
      expect(requests, ['HEAD']);
    });

    test('times out instead of hanging and aborts the request', () async {
      web.AbortSignal? signal;
      PlatformUtilsFacadeImpl.fetchTimeout = const Duration(milliseconds: 50);
      PlatformUtilsFacadeImpl.fetch = (url, init) {
        signal = init.signal;
        return Completer<web.Response>().future;
      };

      expect(await exists(), isFalse);
      expect(signal!.aborted, isTrue);
    });
  });
}
