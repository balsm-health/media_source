@TestOn('vm')
// Writes to disk to prove saveToFolder stays inside its folder.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_source/media_source.dart';
import 'package:media_source/src/extensions/uri_extensions.dart';
import 'package:path/path.dart' as p;

const tempDir = 'test/assets/file_name_safety';

void main() {
  group('Uri.fileName', () {
    test('percent-decodes a normal name', () {
      expect(Uri.parse('https://x/a/my%20video.mp4').fileName, 'my video.mp4');
    });

    test('skips a trailing slash', () {
      expect(Uri.parse('https://x/videos/').fileName, 'videos');
      expect(Uri.parse('https://x/').fileName, '');
      expect(Uri.parse('https://x').fileName, '');
    });

    test('keeps encoded separators encoded so the name cannot be a path', () {
      expect(Uri.parse('https://evil/%2Ftmp%2Fpwn.mp4').fileName, '%2Ftmp%2Fpwn.mp4');
      expect(Uri.parse('https://evil/..%2F..%2Fx.mp4').fileName, '..%2F..%2Fx.mp4');
      expect(Uri.parse('https://evil/..%5Cx.mp4').fileName, '..%5Cx.mp4');
      // Uri.parse normalizes an encoded '..' segment away entirely.
      expect(Uri.parse('https://evil/a/%2E%2E').fileName, isNot('..'));
    });

    test('does not throw on invalid UTF-8 percent-encoding', () {
      expect(Uri.parse('https://x/%C3%28.mp4').fileName, '%C3%28.mp4');
      expect(() => VideoNetworkMedia(Uri.parse('https://x/%C3%28.mp4')), returnsNormally);
    });
  });

  group('saveToFolder stays inside the folder', () {
    setUp(() => PlatformUtils.instance.deleteDirectory(tempDir));
    tearDownAll(() => PlatformUtils.instance.deleteDirectory(tempDir));

    final bytes = Uint8List.fromList([1, 2, 3]);

    test('an absolute name is reduced to its base name', () async {
      final media = OtherTypeMemoryMedia(bytes, name: '${Directory.systemTemp.path}/escaped.bin');

      final saved = await media.saveToFolder(tempDir);

      expect(p.isWithin(tempDir, saved.file.path), isTrue);
      expect(p.basename(saved.file.path), 'escaped.bin');
    });

    test('a traversal name is reduced to its base name', () async {
      final media = OtherTypeMemoryMedia(bytes, name: '../../escaped.bin');

      final saved = await media.saveToFolder(tempDir);

      expect(p.isWithin(tempDir, saved.file.path), isTrue);
    });

    for (final bad in ['..', '.', '', 'dir/']) {
      test('rejects name "$bad" that has no usable base name', () async {
        final media = OtherTypeMemoryMedia(bytes, name: bad);
        expect(() => media.saveToFolder(tempDir), throwsArgumentError);
      });
    }

    test('moveToFolder uses the same guard', () async {
      final source = await OtherTypeMemoryMedia(bytes, name: 'm.bin').saveTo('$tempDir/src/m.bin');
      final file = await OtherTypeFileMedia.fromFile(source.file, name: '../../escaped.bin');

      final moved = await file.moveToFolder('$tempDir/out');

      expect(p.isWithin('$tempDir/out', moved.file.path), isTrue);
    });

    test('file and asset sources use the same guard', () async {
      final source = await OtherTypeMemoryMedia(bytes, name: 'src.bin').saveTo('$tempDir/src/src.bin');
      final file = await OtherTypeFileMedia.fromFile(source.file, name: '../../escaped.bin');

      final saved = await file.saveToFolder('$tempDir/out');

      expect(p.isWithin('$tempDir/out', saved.file.path), isTrue);
    });
  });
}
