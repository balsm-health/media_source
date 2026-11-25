@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_source/src/extensions/file_extensions.dart';
import 'package:media_source/src/sources/file_media_source.dart';
import 'package:media_source/src/sources/memory_media_source.dart';

/// Web-only behavior of saveTo / moveTo. On web, `XFile.saveTo` only triggers
/// a browser download, so the destination path is never addressable and the
/// returned sources must stay backed by a readable blob.
void main() {
  final bytes = Uint8List.fromList(List<int>.generate(64, (i) => i));

  Future<DocumentFileMedia> blobFileMedia() => DocumentFileMedia.fromFile(
        XFile.fromData(bytes, name: 'doc.pdf', mimeType: 'application/pdf'),
        name: 'doc.pdf',
      );

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
}
