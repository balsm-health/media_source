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

    test('returns false instead of throwing when the rename fails', () async {
      await File('$dir/a.bin').writeAsBytes([1]);
      // Destination directory doesn't exist, so the rename fails.
      expect(await PlatformUtils.instance.moveFile('$dir/a.bin', '$dir/no/such/dir/b.bin'), isFalse);
      expect(File('$dir/a.bin').existsSync(), isTrue);
    });
  });
}
