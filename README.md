<img src="https://github.com/balsm-health/media_source/raw/main/assets/wallpaper.png" alt="wallpaper" />


<h2 align="center">
  Media Source
</h2>

<p align="center">
   <a href="https://github.com/balsm-health/media_source/actions/workflows/build.yml">
    <img src="https://github.com/balsm-health/media_source/actions/workflows/build.yml/badge.svg?branch=main" alt="GitHub action">
  </a>

  <a href="https://codecov.io/gh/balsm-health/media_source" > 
 <img src="https://codecov.io/gh/balsm-health/media_source/graph/badge.svg?token=sSK2ZySczS"/> 
 </a>
  <a href="https://pub.dev/packages/media_source">
    <img alt="Pub Package" src="https://img.shields.io/pub/v/media_source">
  </a>
   <a href="https://pub.dev/packages/media_source">
    <img alt="Pub Points" src="https://img.shields.io/pub/points/media_source">
  </a>
  <br/>
  <a href="https://opensource.org/licenses/MIT">
    <img alt="MIT License" src="https://img.shields.io/badge/License-MIT-blue.svg">
  </a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20Web-blue" alt="Platforms">
</p>

---

A **type-safe**, **cross-platform** Flutter package that unifies media handling from **files**, **memory**, and **network** sources with **automatic type detection** and **seamless conversions**.

## Motivation

When building **media-rich applications**, you often need to handle media from **multiple sources**: **files** stored locally, data in **memory** (like camera captures or downloaded content), **URLs** from remote servers, and **assets** bundled with your app. Managing these different states becomes complex when you need to:

Inspired by Flutter's ```ImageProvider```, which unifies images from **assets**, **files**, **memory**, and **network** under a single API, this library applies the same idea to general media. The goal is to let you **swap sources freely** without changing your business logic.

- Load a **file** from disk, process it in **memory**, then **upload** it
- **Download** media from a URL, **cache** it locally, and **convert** it between formats
- Use bundled **assets** during development, then switch to **network** sources in production
- Handle **user-selected files**, **camera captures**, **network resources**, and **app assets** uniformly
- Switch between sources **without rewriting** your business logic

This package provides a **unified**, **type-safe API** to handle all these scenarios. Whether your media starts as a file, exists in memory, or comes from a network URL, you can work with it **consistently** and **convert between states** seamlessly.

## Features

- 🎯 **Type-safe media source abstraction** - Handle files, memory, network, and assets uniformly
- 📁 **Multiple source types** - `FileMediaSource`, `MemoryMediaSource`, `NetworkMediaSource`, `AssetMediaSource`, `ThumbnailMediaSource`
- 🖼️ **Thumbnail support** - Pair high-quality media with lightweight previews for optimized loading
- 🔍 **Automatic media type detection** - From file paths, MIME types, and byte data
- 💥 **Pattern matching API** - Type-safe `fold()` for elegant source handling
- 🔄 **Seamless conversions** - Convert between source types (file ↔ memory ↔ asset)
- 💾 **Rich file operations** - Move, copy, save, and delete with atomic operations
- 🌐 **Cross-platform support** - Works on Flutter mobile, web, and desktop
- 📦 **Flutter asset integration** - Load and convert media from app asset bundles with custom bundle support
- ⚡ **Lazy loading support** - Optimize performance with size hints to avoid unnecessary data loading
- 📊 **MIME type utilities** - Comprehensive mapping of extensions to media types
- 🧩 **Extension-based lookups** - Quick type checks with pre-built extension sets
- � **Human-readable sizes** - Built-in integration with `file_sized` (1.5.mb, 2.gb, etc.)
- 💪 **Built on `cross_file`** - Seamless cross-platform file handling
- ✅ **100% test coverage** - Production-ready and thoroughly tested
- 🛡️ **Fully type-safe** - Compile-time safety with generic type parameters
- 🔗 **Unified API** - Consistent interface across all media sources

## Getting started

Add `media_source` to your `pubspec.yaml`:

```yaml
dependencies:
  media_source: ^2.0.0
```

Then run:

```bash
flutter pub get
```

> 💡 **Quick Start**: Check out the complete [example/main.dart](example/main.dart) file for a comprehensive demonstration of all features.

## Usage

### Basic Media Type Detection

Type detection comes from [file_type_plus](https://pub.dev/packages/file_type_plus), which
`media_source` does not re-export. Add it to your dependencies to use `FileType` directly:

```dart
import 'package:file_type_plus/file_type_plus.dart';

// Detect from a file path (by extension, or by the MIME type when given)
final imageType = FileType.fromPath('/path/to/photo.jpg');
print(imageType.isAny([FileType.image])); // true

// Detect from bytes, with an optional MIME type hint
final bytes = await file.readAsBytes();
final videoType = FileType.fromBytes(bytes, 'video/mp4');
print(videoType.isAny([FileType.video])); // true
```

You rarely need this yourself: `FileMediaSource.fromPath` / `fromFile` and
`NetworkMediaSource.fromUrl` detect the type and return the matching subclass
(`VideoFileMedia`, `ImageNetworkMedia`, ...).

### Working with **File Media Source**

```dart
import 'package:media_source/media_source.dart';

// Create from file path
final video = await VideoFileMedia.fromPath(
  '/path/to/video.mp4',
  duration: Duration(seconds: 120),
);

// Access properties
print(video.name); // video.mp4
print(video.size); // File size
print(video.metadata.duration); // Duration(seconds: 120)

// File operations
await video.saveTo('/backup/video.mp4');
await video.moveTo('/new/location/video.mp4');
final memoryMedia = await video.convertToMemory();
await video.delete();

// Create from XFile
final file = XFile('/path/to/audio.mp3');
final audio = await AudioFileMedia.fromFile(
  file,
  name: 'song.mp3',
  duration: Duration(minutes: 3),
);
```

### Working with **Memory Media Source**

```dart
import 'package:media_source/media_source.dart';
import 'dart:typed_data';

// Create from byte data
final bytes = Uint8List.fromList([/* your data */]);
final image = ImageMemoryMedia(
  bytes,
  name: 'photo.jpg',
  mimeType: 'image/jpeg',
);

// Access properties
print(image.bytes); // Uint8List
print(image.size); // Size in bytes
print(image.name); // photo.jpg

// Save to file system
final fileMedia = await image.saveToFolder('/images');
print(fileMedia.file.path); // /images/photo.jpg

// Convert to different types
final videoMemory = VideoMemoryMedia(
  videoBytes,
  name: 'clip.mp4',
  duration: Duration(seconds: 10),
);
```

### Working with **Network Media Source**

```dart
import 'package:file_type_plus/file_type_plus.dart'; // for FileType
import 'package:media_source/media_source.dart';

// Create from URL with automatic type detection
final media = NetworkMediaSource.fromUrl(
  'https://example.com/video.mp4',
  mediaType: FileType.video,
  size: 5.mb,
  name: 'video.mp4',
);

// Create type-specific network media
final video = VideoNetworkMedia.url(
  'https://example.com/movie.mp4',
  name: 'movie.mp4',
  size: 150.mb,
  duration: Duration(minutes: 90),
);

final audio = AudioNetworkMedia(
  Uri.parse('https://example.com/song.mp3'),
  name: 'song.mp3',
  size: 5.mb,
  duration: Duration(minutes: 3, seconds: 45),
);

final image = ImageNetworkMedia.url(
  'https://example.com/photo.jpg',
  name: 'photo.jpg',
  size: 2.mb,
);

// Access properties
print(video.uri); // Uri object
print(video.name); // movie.mp4
print(video.size); // 150 MB
print(video.metadata.duration); // Duration
```

### Working with **Asset Media Source**

```dart
import 'package:media_source/media_source.dart';
import 'package:flutter/services.dart' show rootBundle;

// First, declare assets in your pubspec.yaml:
// flutter:
//   assets:
//     - assets/videos/
//     - assets/audio/
//     - assets/images/

// Load video asset
final video = await VideoAssetMedia.load(
  'assets/videos/intro.mp4',
  duration: Duration(seconds: 30),
  bundle: rootBundle, // optional, defaults to rootBundle
);

// Load audio asset
final audio = await AudioAssetMedia.load(
  'assets/audio/song.mp3',
  duration: Duration(minutes: 3, seconds: 45),
);

// Load image asset
final image = await ImageAssetMedia.load(
  'assets/images/logo.png',
);

// Access properties
print(video.assetPath); // assets/videos/intro.mp4
print(video.name); // intro.mp4
print(video.size); // Size in bytes
print(video.metadata.duration); // Duration(seconds: 30)

// Optimized loading with size hint (avoids loading entire asset)
final largeVideo = await VideoAssetMedia.load(
  'assets/videos/movie.mp4',
  duration: Duration(minutes: 90),
  size: 150.mb, // Provide size to avoid loading asset just to get size
);

// Convert to memory for processing
final memoryMedia = await video.convertToMemory();
print(memoryMedia.bytes.length); // Full asset loaded in memory

// Save asset to file system
final fileMedia = await video.saveTo('/path/to/save/intro.mp4');
print(fileMedia.file.path); // /path/to/save/intro.mp4

// Pattern matching works with asset media
final result = video.fold(
  file: (f) => 'File: ${f.file.path}',
  memory: (m) => 'Memory: ${m.size}',
  network: (n) => 'Network: ${n.uri}',
  asset: (a) => 'Asset: ${a.assetPath}',
  thumbnail: (t) => 'Thumbnail: ${t.name}',
  orElse: () => 'Unknown source',
);
print(result); // Asset: assets/videos/intro.mp4
```

**Asset Media Features:**
- 📦 **Flutter asset bundle integration** - Load media from app assets
- 🎯 **Type-safe asset loading** - Video, Audio, Image, Document asset types
- 🔄 **Seamless conversions** - Convert assets to memory or file sources
- 💾 **Lazy loading** - Provide size hint to avoid loading entire asset
- 🏗️ **Construction** - Create assets with `load()`. `ImageAssetMedia` also has a public
  synchronous constructor that uses the given `size` as-is (or null) without reading the bundle
- 🧩 **Pattern matching support** - Works with fold() for consistent API
- ✅ **Cross-platform** - Works on all Flutter platforms

> 💡 **Interactive Example**: Check out [example/asset_media_example.dart](example/asset_media_example.dart) for a complete Flutter app demonstrating all asset media features with an interactive UI.

### **Complete Example**

```dart
import 'package:media_source/media_source.dart';
import 'package:file_sized/file_sized.dart';

Future<void> processMedia() async {
  // Create a video file media
  final video = await VideoFileMedia.fromPath(
    '/path/to/video.mp4',
    duration: Duration(minutes: 2),
  );
  
  // Create a thumbnail for the video
  final thumb = await ImageFileMedia.fromPath('/path/to/thumbnail.jpg');
  final mediaWithThumb = ThumbnailMediaSource<VideoType, ImageType>(
    original: video,
    thumbnail: thumb,
  );

  // A ThumbnailMediaSource matches the `thumbnail` branch, never `file`,
  // so fold again on the wrapped original.
  final result = mediaWithThumb.fold<String>(
    thumbnail: (t) {
      final preview = t.hasThumbnail ? 'with preview' : 'no preview';
      print('Thumbnail size: ${t.thumbnail?.size}');
      print('Original size: ${t.original.size}');
      return t.original.fold(
        file: (f) => 'File ${f.name} ($preview)',
        network: (n) => 'Network ${n.uri} ($preview)',
        orElse: () => 'Other source ($preview)',
      );
    },
    orElse: () => 'Unknown media type',
  );
  print(result);

  // fold callbacks are synchronous: do async work on the source itself.
  final backup = await video.saveTo('/backup/video.mp4');
  final memoryMedia = await video.convertToMemory();
  print('Processing ${memoryMedia.bytes.length} bytes from ${backup.name}');
}
```

### **Type-Specific Operations** with **Pattern Matching**

```dart
import 'package:media_source/media_source.dart';

// Pattern matching on a media type (every source exposes it as `metadata`)
final song = await AudioFileMedia.fromPath('/music/song.mp3');

final description = song.metadata.fold(
  audio: (audio) => 'Audio file with duration: ${audio.duration}',
  video: (video) => 'Video file with duration: ${video.duration}',
  image: (image) => 'Image file',
  document: (doc) => 'Document file',
  url: (url) => 'URL reference',
  orElse: () => 'Other file type',
);

print(description);

// Pattern matching on MediaSource
final media = await VideoFileMedia.fromPath('/path/to/video.mp4');

final info = media.fold(
  file: (f) => 'File: ${f.file.path}',
  memory: (m) => 'Memory: ${m.size}',
  network: (n) => 'URL: ${n.uri}',
  asset: (a) => 'Asset: ${a.assetPath}',
  thumbnail: (t) => 'Thumbnail: ${t.name}',
  orElse: () => 'Unknown source',
);

print(info); // File: /path/to/video.mp4
```

## API Reference

### **Media types**

Media is classified by subtypes of `FileTypeImpl`, which extends `FileType` from
[file_type_plus](https://pub.dev/packages/file_type_plus):

- `ImageType` - Image media
- `AudioType` - Audio media with **optional duration**
- `VideoType` - Video media with **optional duration**
- `DocumentType` - Document media
- `UrlType` - A URL that is not classified as media
- `OtherType` - Unclassified media

Every source exposes its type as `metadata` (for example, `VideoFileMedia.metadata` is a `VideoType`).

**Methods:**
- `fold<T>({image, audio, video, document, url, required orElse})` - **Pattern matching** on a media type
- `FileType.fromPath`, `FileType.fromBytes` and `isAny` come from file_type_plus; import it to use them

### **MediaSource Implementations**

All sources share `name`, `mimeType`, `size` (nullable), `metadata`, and `fold`.
`MediaSource.isAnyType` is deprecated: it compares exact runtime types, so it never matches a
base type such as `FileMediaSource`. Use `is` checks or `fold` instead.

**FileMediaSource** - detects the type and returns the matching subclass
```dart
FileMediaSource.fromPath(String path, {String? name, FileSize? size, String? mimeType,
    Duration? duration, FileType? mediaType})
FileMediaSource.fromFile(XFile file, {...same options})

// Or a specific type: VideoFileMedia, AudioFileMedia, ImageFileMedia,
// DocumentFileMedia, OtherTypeFileMedia
VideoFileMedia.fromPath(String path, {String? name, Duration? duration, String? mimeType, FileSize? size})
```

**MemoryMediaSource** - one constructor per type
```dart
VideoMemoryMedia(Uint8List bytes, {required String? name, Duration? duration, String? mimeType})
ImageMemoryMedia(Uint8List bytes, {required String? name, String? mimeType})
// Also AudioMemoryMedia, DocumentMemoryMedia, OtherTypeMemoryMedia
```

**NetworkMediaSource**
```dart
NetworkMediaSource.fromUrl(String url, {String? name, FileSize? size, String? mimeType,
    Duration? duration, FileType? mediaType})
NetworkMediaSource.fromUrlOrNull(String? url, {...same options}) // null for null/empty/invalid URLs

// Or a specific type, from a Uri or with .url(String)
VideoNetworkMedia(Uri uri, {Duration? duration, String? mimeType, String? name, FileSize? size})
ImageNetworkMedia.url(String url, {String? mimeType, String? name, FileSize? size})
// Also AudioNetworkMedia, DocumentNetworkMedia, UnSupportedNetworkMedia

// A plain URL: size is null, MIME type is detected from the path (null if unknown)
UrlMedia(Uri uri)
UrlMedia.url(String url)
```

**AssetMediaSource** - one `load` per type; reads the asset to get its size unless `size` is given
```dart
VideoAssetMedia.load(String assetPath, {AssetBundle? bundle, String? name, Duration? duration,
    String? mimeType, FileSize? size})
ImageAssetMedia.load(String assetPath, {AssetBundle? bundle, String? name, String? mimeType, FileSize? size})
// Also AudioAssetMedia, DocumentAssetMedia, OtherTypeAssetMedia

// ImageAssetMedia only: synchronous, no bundle read, size used as given
ImageAssetMedia({required String assetPath, AssetBundle? bundle, String? name, FileSize? size, String? mimeType})
```

**ThumbnailMediaSource**
```dart
ThumbnailMediaSource({
  required MediaSource<M> original,
  MediaSource<T>? thumbnail,
})
```

### Working with **Thumbnail Media Source**

`ThumbnailMediaSource` is a powerful wrapper that pairs high-quality media with lightweight preview thumbnails, enabling optimized user experiences through progressive loading and bandwidth-efficient previews.

#### **When to Use Thumbnails**

✅ **Perfect for:**
- Video galleries (show thumbnail, load video on demand)
- Large image collections (display compressed previews)
- Media-rich feeds (load thumbnails first, full media on interaction)
- Bandwidth-constrained environments (mobile networks, slow connections)
- Progressive enhancement UX patterns

#### **Basic Usage**

```dart
import 'package:media_source/media_source.dart';

// 1. Create your sources
final video = await VideoFileMedia.fromPath('/storage/videos/movie.mp4');
final thumbnail = await ImageFileMedia.fromPath('/storage/cache/thumb_movie.jpg');

// 2. Wrap them in a ThumbnailMediaSource
// Types: <OriginalType, ThumbnailType>
final mediaWithThumb = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  thumbnail: thumbnail,
);

// 3. Access properties (delegates to original)
print(mediaWithThumb.name);      // movie.mp4
print(mediaWithThumb.size);      // Size of the video file
print(mediaWithThumb.metadata);  // VideoType metadata

// 4. Check if thumbnail exists
if (mediaWithThumb.hasThumbnail) {
  // Show thumbnail in UI
  final preview = mediaWithThumb.thumbnail!; 
  print('Preview: ${preview.name}');
  print('Preview size: ${preview.size}'); // Much smaller than original
}

// 5. Smart display logic
// Use thumbnail if present, otherwise use original
final sourceToDisplay = mediaWithThumb.thumbnail ?? mediaWithThumb.original;
```

#### **Advanced Usage Patterns**

**Progressive Loading in UI:**
```dart
import 'package:media_source/media_source.dart';
import 'package:flutter/material.dart';

class VideoGalleryItem extends StatefulWidget {
  final ThumbnailMediaSource<VideoType, ImageType> media;
  
  const VideoGalleryItem({required this.media});
  
  @override
  State<VideoGalleryItem> createState() => _VideoGalleryItemState();
}

class _VideoGalleryItemState extends State<VideoGalleryItem> {
  bool _loadingFullVideo = false;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _loadFullVideo(),
      child: Stack(
        children: [
          // Show thumbnail immediately
          if (widget.media.hasThumbnail)
            Image.memory(widget.media.thumbnail!.bytes),
          
          // Overlay with video info
          Positioned(
            bottom: 8,
            right: 8,
            child: Text('${widget.media.metadata.duration}'),
          ),
          
          // Loading indicator
          if (_loadingFullVideo)
            Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
  
  Future<void> _loadFullVideo() async {
    setState(() => _loadingFullVideo = true);
    // Load and play the full video
    final videoFile = widget.media.original;
    // ... play video ...
    setState(() => _loadingFullVideo = false);
  }
}
```

**Network Media with Thumbnail:**
```dart
import 'package:media_source/media_source.dart';
import 'package:file_sized/file_sized.dart';

// Create network video with thumbnail
final videoUrl = 'https://example.com/videos/movie.mp4';
final thumbUrl = 'https://example.com/thumbnails/movie_thumb.jpg';

final video = VideoNetworkMedia.url(
  videoUrl,
  name: 'movie.mp4',
  size: 150.mb,
  duration: Duration(minutes: 90),
);

final thumbnail = ImageNetworkMedia.url(
  thumbUrl,
  name: 'movie_thumb.jpg',
  size: 50.kb, // Much smaller!
);

// Combine them
final mediaWithThumb = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  thumbnail: thumbnail,
);

// In your UI, load thumbnail first (50KB)
// Then load full video only when user clicks (150MB)
```

**Generate Thumbnails from Video:**
```dart
import 'package:media_source/media_source.dart';

// Load original video
final video = await VideoFileMedia.fromPath('/path/to/video.mp4');

// Generate thumbnail (using your preferred video thumbnail package)
// Example: video_thumbnail, flutter_video_thumbnail, etc.
final thumbnailBytes = await generateVideoThumbnail(video.file.path);

final thumbnail = ImageMemoryMedia(
  thumbnailBytes,
  name: 'video_thumb.jpg',
  mimeType: 'image/jpeg',
);

// Create thumbnail media source
final mediaWithThumb = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  thumbnail: thumbnail,
);

// Optionally save thumbnail for future use
await thumbnail.saveTo('/cache/thumbnails/video_thumb.jpg');
```

**Handling Missing Thumbnails:**
```dart
import 'package:media_source/media_source.dart';

// Create media source without thumbnail initially
final video = await VideoFileMedia.fromPath('/path/to/video.mp4');
final mediaWithThumb = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  // thumbnail: null, // Optional - can be null
);

// Check before using
if (mediaWithThumb.hasThumbnail) {
  // Show thumbnail
  displayThumbnail(mediaWithThumb.thumbnail!);
} else {
  // Show placeholder or generate thumbnail on-demand
  showPlaceholder();
}

// Later, add thumbnail when available
final generatedThumb = await generateThumbnail(video);
final updatedMedia = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  thumbnail: generatedThumb,
);
```

**Mixed Media Types:**
```dart
import 'package:media_source/media_source.dart';

// Large image with compressed preview
final highResImage = await ImageFileMedia.fromPath('/photos/4k_photo.jpg');
final compressedPreview = await ImageFileMedia.fromPath('/cache/photo_preview.jpg');

final photoWithPreview = ThumbnailMediaSource<ImageType, ImageType>(
  original: highResImage,
  thumbnail: compressedPreview,
);

// Audio with album art
final audioTrack = await AudioFileMedia.fromPath('/music/song.mp3');
final albumArt = await ImageFileMedia.fromPath('/music/covers/album.jpg');

final musicWithArt = ThumbnailMediaSource<AudioType, ImageType>(
  original: audioTrack,
  thumbnail: albumArt,
);
```

**Pattern Matching with Thumbnails:**
```dart
import 'package:media_source/media_source.dart';

final media = ThumbnailMediaSource<VideoType, ImageType>(
  original: video,
  thumbnail: thumbnail,
);

// Pattern matching works seamlessly
final result = media.fold(
  file: (f) => 'File source: ${f.file.path}',
  memory: (m) => 'Memory source: ${m.size}',
  network: (n) => 'Network source: ${n.uri}',
  asset: (a) => 'Asset source: ${a.assetPath}',
  thumbnail: (t) {
    final hasThumb = t.hasThumbnail ? 'with' : 'without';
    return 'Thumbnail source $hasThumb preview: ${t.name}';
  },
  orElse: () => 'Unknown source',
);
```

#### **Key Features**

- 🎯 **Type-safe dual generics** - Separate types for original and thumbnail
- 📊 **Automatic delegation** - Properties delegate to original media
- 🔄 **Optional thumbnails** - Thumbnails can be null, check with `hasThumbnail`
- 🧩 **Pattern matching** - Matches the `thumbnail` branch of `fold()`; fold `original` to handle the wrapped source
- ⚡ **Performance optimization** - Load small thumbnails first, full media on demand
- 🌐 **Works with all sources** - File, Memory, Network, and Asset media
- 💾 **Bandwidth efficient** - Ideal for mobile and slow connections

#### **Best Practices**

1. **Always check `hasThumbnail`** before accessing the thumbnail
2. **Use compressed images** for thumbnails (JPEG with lower quality)
3. **Keep thumbnails small** - typically 50-200KB for videos, 10-50KB for images
4. **Cache thumbnails** - Save generated thumbnails to avoid regeneration
5. **Progressive loading** - Show thumbnail immediately, load full media on interaction
6. **Consider aspect ratio** - Maintain original aspect ratio in thumbnails
7. **Lazy generation** - Only generate thumbnails when needed


## Extensibility

You can **extend** the package to fit **custom domain needs**:

- Create a **new media type** by extending `FileTypeImpl` (see `lib/src/media_type.dart`).
- Create a **new media source** by extending `MediaSource<M extends FileType>` and, if it
  supports conversion, implementing `ToFileConvertableMedia` / `ToMemoryConvertableMedia`.
  The built-in base classes (`FileMediaSource`, `MemoryMediaSource`, ...) have private
  constructors and can't be extended outside the package.
- Create a **custom media factory** to centralize media creation logic and apply business rules.

### Custom Type and Source Example

Example — **custom type** and **source**:

```dart
import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:file_type_plus/file_type_plus.dart';
import 'package:media_source/media_source.dart';

class StickerType extends FileTypeImpl {
  StickerType() : super.copy(FileType.other);
  @override
  List<Object?> get props => const [];
}

class StickerMemoryMedia extends MediaSource<StickerType>
    implements ToFileConvertableMedia<StickerType> {
  StickerMemoryMedia(this.bytes, {required String name})
      : super(metadata: StickerType(), name: name, mimeType: 'image/webp', size: bytes.length.b);

  final Uint8List bytes;

  @override
  Future<FileMediaSource<StickerType>> saveTo(String path) async {
    final file = XFile.fromData(bytes, name: name, path: path);
    await PlatformUtils.instance.ensureParentDirectoryExists(path);
    await file.saveTo(path);
    // Return your own FileMediaSource<StickerType> implementation here
    throw UnimplementedError();
  }

  @override
  List<Object?> get props => [...super.props, bytes];
}
```

### Custom Media Factory Example

You can create **custom factories** to centralize media instantiation logic and apply business rules:

```dart
import 'dart:typed_data';
import 'package:file_type_plus/file_type_plus.dart';
import 'package:media_source/media_source.dart';

/// Enum to specify media source type
enum MediaSourceType { file, memory, network }

/// Custom factory that creates media based on conditions
class MediaFactory {
  /// Creates media based on the specified source type
  dynamic createMedia({
    required MediaSourceType source,
    String? path,
    Uint8List? bytes,
    String? url,
    String? name,
    String? mimeType,
    FileSize? size,
    Duration? duration,
  }) async {
    switch (source) {
      case MediaSourceType.file:
        if (path != null) {
          final fileType = FileType.fromPath(path);
          if (fileType.isAny([FileType.video])) {
            return VideoFileMedia.fromPath(path, name: name, duration: duration);
          }
          // Handle other types...
        }
        break;
      case MediaSourceType.memory:
        if (bytes != null) {
          final fileType = FileType.fromBytes(bytes, mimeType);
          if (fileType.isAny([FileType.image])) {
            return ImageMemoryMedia(bytes, name: name ?? 'image.jpg');
          }
          // Handle other types...
        }
        break;
      case MediaSourceType.network:
        if (url != null) {
          return VideoNetworkMedia.url(url, name: name, size: size);
        }
        break;
    }
    return null;
  }
}

/// Smart factory with optimization logic
class SmartMediaFactory {
  final bool preferMemoryForSmallFiles;
  final double smallFileSizeThresholdMB;

  SmartMediaFactory({
    this.preferMemoryForSmallFiles = true,
    this.smallFileSizeThresholdMB = 5.0,
  });

  /// Creates media with optimization based on file size
  Future<MediaSource?> createOptimized({
    required String path,
    FileSize? size,
  }) async {
    // For small files, prefer memory for better performance
    if (preferMemoryForSmallFiles && 
        size != null && 
        size.inMB < smallFileSizeThresholdMB) {
      // Load into memory for fast access
      // In production: read file and return MemoryMediaSource
    }
    
    // For large files, use file media
    return await VideoFileMedia.fromPath(path, size: size);
  }
}
```

**Benefits of custom factories:**
- **Centralize** media creation logic
- Apply **business rules** (size limits, caching strategies)
- Enable **testing** with mock media sources
- Handle **complex multi-source** scenarios
- Implement **optimization strategies** (memory vs. file based on size)

> 💡 See the complete factory example in [example/main.dart](example/main.dart)

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

### Web notes

Browsers have no writable file system, so on web:

- `saveTo` / `saveToFolder` trigger a browser download. The path only names the
  download; it is not readable afterwards. The returned `FileMediaSource` reads from
  the original data instead: a new blob URL for memory and asset sources, or the same
  `XFile` for file sources.
- `moveTo` / `moveToFolder` download the file and keep the original in place, because
  the returned source still reads from it.
- `delete` revokes blob URLs; other paths cannot be deleted and return `false`. A file
  source and the source returned by its `saveTo` / `moveTo` share one blob URL, so
  deleting either one makes both unreadable.
- Directory operations are no-ops.

## Additional information

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Issues

If you encounter any issues or have suggestions, please file them in the [issue tracker](https://github.com/balsm-health/media_source/issues).

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Author

Hossam Eldin Mahmoud - [GitHub](https://github.com/hossameldinmi), [LinkedIn](https://linkedin.com/in/hossameldinmi)

### Acknowledgments

- Uses [cross_file](https://pub.dev/packages/cross_file) for cross-platform file handling
- Built with [file_type_plus](https://pub.dev/packages/file_type_plus) for file type detection
- Size handling powered by [file_sized](https://pub.dev/packages/file_sized)