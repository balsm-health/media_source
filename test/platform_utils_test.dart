@TestOn('vm')
// Exercises real directories; on web these operations are no-ops.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_source/media_source.dart';

const tempDir = 'test/assets/platform_utils_saved_to';

void main() {
  group('PlatformUtilsFacade.createDirectoryIfNotExists', () {
    setUpAll(() async {
      await PlatformUtils.instance.deleteDirectory(tempDir);
    });

    tearDownAll(() async {
      await PlatformUtils.instance.deleteDirectory(tempDir);
    });

    test('delegates to ensureParentDirectoryExists', () async {
      const filePath = '$tempDir/nested/file.txt';

      // ignore: deprecated_member_use_from_same_package
      await PlatformUtils.instance.createDirectoryIfNotExists(filePath);

      expect(await PlatformUtils.instance.directoryExists('$tempDir/nested'), isTrue);
    });
  });

  group('PlatformUtilsFacade.moveFile', () {
    const dir = '$tempDir/move';
    setUp(() async {
      await PlatformUtils.instance.deleteDirectory(dir);
      await Directory(dir).create(recursive: true);
    });
    tearDownAll(() => PlatformUtils.instance.deleteDirectory(tempDir));

    test('renames an existing file', () async {
      await File('$dir/a.bin').writeAsBytes([1, 2]);

      expect(await PlatformUtils.instance.moveFile('$dir/a.bin', '$dir/b.bin'), isTrue);
      expect(File('$dir/a.bin').existsSync(), isFalse);
      expect(File('$dir/b.bin').readAsBytesSync(), [1, 2]);
    });

    test('returns false for an empty source path', () async {
      expect(await PlatformUtils.instance.moveFile('', '$dir/b.bin'), isFalse);
    });

    test('returns false for a missing source', () async {
      expect(await PlatformUtils.instance.moveFile('$dir/missing.bin', '$dir/b.bin'), isFalse);
    });

    test('creates a missing destination folder instead of falling back to copy', () async {
      await File('$dir/a.bin').writeAsBytes([1, 2]);

      expect(await PlatformUtils.instance.moveFile('$dir/a.bin', '$dir/new/sub/b.bin'), isTrue);
      expect(File('$dir/a.bin').existsSync(), isFalse);
      expect(File('$dir/new/sub/b.bin').readAsBytesSync(), [1, 2]);
    });

    test('returns false instead of throwing when the rename fails', () async {
      await File('$dir/a.bin').writeAsBytes([1]);
      // The destination is an existing directory, so the rename fails.
      await Directory('$dir/taken').create();
      expect(await PlatformUtils.instance.moveFile('$dir/a.bin', '$dir/taken'), isFalse);
      expect(File('$dir/a.bin').existsSync(), isTrue);
    });

    test('returns false for a symbolic link so the caller copies its target', () async {
      await File('$dir/target.bin').writeAsBytes([7]);
      await Link('$dir/link.bin').create('target.bin');

      expect(await PlatformUtils.instance.moveFile('$dir/link.bin', '$dir/out/b.bin'), isFalse);
      expect(Link('$dir/link.bin').existsSync(), isTrue);
    }, skip: Platform.isWindows ? 'Creating symbolic links needs extra privileges on Windows' : false);
  });
}
