# Media Source - AI Agent Instructions

## Project Overview

A type-safe, cross-platform Flutter package that unifies media handling from files, memory, network, and asset sources with automatic type detection and seamless conversions. Inspired by Flutter's `ImageProvider` pattern but extended to all media types.

## Architecture

### Core Abstraction: `MediaSource<M extends FileType>`
- Base class in [lib/src/sources/media_source.dart](../lib/src/sources/media_source.dart)
- Generic parameter `M` represents media type metadata (`VideoType`, `AudioType`, `ImageType`, etc.)
- All sources extend this base with specific implementations
- Pattern matching via `fold()` method for type-safe handling

### Source Types Hierarchy
Five main source implementations in [lib/src/sources/](../lib/src/sources/):
1. **FileMediaSource** - Cross-platform file handling via `cross_file`
2. **MemoryMediaSource** - In-memory byte data (`Uint8List`)
3. **NetworkMediaSource** - Remote URLs (URI and metadata only; no download or caching)
4. **AssetMediaSource** - Flutter asset bundle integration (read-only)
5. **ThumbnailMediaSource** - Wrapper pairing high-quality media with previews

### Media Type Detection
- Auto-detection in [lib/src/media_type.dart](../lib/src/media_type.dart)
- Uses `file_type_plus` for byte signature analysis
- Fallback to MIME type and extension-based detection
- Type-safe sealed class approach for media categories

### Conversion Mixins
- `ToMemoryConvertableMedia<M>` - Convert to in-memory representation
- `ToFileConvertableMedia<M>` - Convert to file-based representation
- Enables source transformations: memory/asset → file (`saveTo`), file/asset → memory (`convertToMemory`). Network sources don't convert; download the bytes yourself first

## Development Workflows

### Running Tests
```bash
# Run all tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/file_media_source_test.dart

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

### CI/CD Pipeline
- GitHub Actions workflow in [.github/workflows/build.yml](workflows/build.yml)
- Runs on push/PR to `main`: analyze → test → coverage upload to Codecov
- Target: 100% test coverage (currently achieved)

### Local Development
```bash
# Get dependencies
flutter pub get

# Analyze code
dart analyze

# Format code (optional)
dart format lib test

# Check the example compiles. It imports Flutter (asset sources use
# flutter/services), so `dart run` can't execute it; call its functions
# from a Flutter app to run them.
flutter analyze example
```

### Publishing to pub.dev
```bash
# Validate package before publishing
dart pub publish --dry-run

# Publish (requires authentication)
dart pub publish
```

## Code Conventions

### Naming Patterns
- Media source classes: `{Type}{Source}Media` (e.g., `VideoFileMedia`, `ImageMemoryMedia`)
- Factory constructors: `.fromPath()`, `.fromBytes()`, `.fromUri()`
- Type detection: `MediaType.fromPath()`, `MediaType.fromBytes()`, `MediaType.fromMimeType()`

### Generic Type Usage
- Always specify media type generics: `MediaSource<VideoType>`, not raw `MediaSource`
- Use specific types in function signatures: `VideoFileMedia` instead of `FileMediaSource<VideoType>`
- Pattern matching preserves type safety through generics

### Equatable Implementation
- All media sources implement `Equatable` for value equality
- Override `props` getter with all identifying properties
- Excludes derived/computed properties from equality checks

### File Size Handling
- Use `file_sized` package for human-readable sizes: `1.5.mb`, `2.gb`
- `FileSize?` type allows optional size information
- Asset sources must load to determine size (read-only limitation)

## Common Tasks

### Adding a New Media Type
1. Define type in [lib/src/media_type.dart](../lib/src/media_type.dart) extending `FileType`
2. Add MIME type mappings in extensions/utils
3. Create source implementations for each source type (File, Memory, Network, Asset)
4. Update pattern matching in `fold()` methods if needed
5. Add tests for each source type

### Creating Source Conversions
```dart
// Memory to File
final fileMedia = await memoryMedia.saveTo('/path/to/save.mp4');

// Asset to Memory
final memoryMedia = await assetMedia.convertToMemory();

// Network sources hold only a URI: download the bytes yourself, then
// wrap them, e.g. VideoMemoryMedia(bytes, name: 'video.mp4').saveTo(path)
```

### Pattern Matching Best Practices
```dart
// Use fold() for exhaustive type handling
final result = mediaSource.fold(
  file: (f) => handleFile(f),
  memory: (m) => handleMemory(m),
  network: (n) => handleNetwork(n),
  asset: (a) => handleAsset(a),
  orElse: () => handleDefault(),
);
```

## External Dependencies

### Key Packages
- `cross_file` - Cross-platform file abstraction (web/mobile/desktop)
- `file_type_plus` - Byte signature-based file type detection
- `file_sized` - Human-readable file size utilities
- `equatable` - Value equality for media sources
- `path` - Path manipulation utilities
- `web` - Web-specific APIs (Blob, URL)

### Platform Considerations
- **Web**: File operations use browser APIs, no actual filesystem access
- **Mobile/Desktop**: Full file system support via `cross_file`
- **Asset sources**: Flutter-specific, require asset bundle context

## Testing Strategy

### Test Structure
Tests organized by source type in `test/`:
- `file_media_source_test.dart` - File operations, conversions
- `memory_media_source_test.dart` - Byte handling, type detection
- `network_media_source_test.dart` - URL handling, remote sources
- `asset_media_source_test.dart` - Asset bundle integration
- `thumbnail_media_source_test.dart` - Wrapper behavior
- `media_type_test.dart` - Type detection logic

### Test Fixtures
- Sample files in `test/assets/` for integration tests
- Shared utilities in `test/shared/fixture.dart`
- Mock data generators for consistent test data

### Coverage Requirements
- **Minimum**: 90% line coverage (enforced by CI)
- **Current**: 100% achieved across all modules
- Use `flutter test --coverage` to verify before committing

## Special Features

### Thumbnail Support
- Wrap any media source with a preview: `ThumbnailMediaSource<VideoType, ImageType>`
- Access original or thumbnail based on use case (e.g., list vs. detail view)
- Supports different type combinations (video + image, document + image, etc.)

### Lazy Loading
- Size hints prevent unnecessary data loading
- `convertToMemory()` only loads when bytes are needed

### Cross-Platform File Handling
- Unified API across web, mobile, desktop via `cross_file`
- Web limitations: Files are ephemeral, no persistent paths
- Use `XFile.saveTo()` for cross-platform file operations

## Gotchas

- **Asset sizes**: Getting size requires loading entire asset into memory (Flutter limitation)
- **Web file paths**: Paths are blob URLs, not filesystem paths
- **MIME type priority**: Explicit MIME type overrides auto-detection
- **Generic type variance**: Use specific types (`VideoFileMedia`) in implementations, keep generics for abstractions
- **Equality checks**: Include `mimeType`, `name`, `size`, `metadata` in `props` for consistent equality

## Example Usage

See [example/main.dart](../example/main.dart) for comprehensive demonstrations of:
- Creating sources from different origins
- Converting between source types
- Pattern matching with `fold()`
- Custom media type implementations
- Thumbnail media handling
