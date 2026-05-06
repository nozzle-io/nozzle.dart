# nozzle.dart

> This codebase is currently in its AI-slob prototyping phase: the code runs on momentum, vibes, and plausible intent.
> Proper debugging will be introduced once demand graduates from hypothetical to measurable.

Dart FFI bindings for [nozzle](https://github.com/nozzle-io/nozzle) — cross-platform GPU texture sharing between local processes.

## Disclaimer / Notice

This library is currently a work in progress and contains many incomplete features and unverified implementations.
Although it may appear usable at first glance, it may not function correctly.

## Build Requirements

- Dart SDK 3.3+
- C++17 compiler (clang / MSVC)
- macOS 12+, Windows 10+, or Linux

The nozzle C library is built from source via a git submodule. A `Makefile` compiles the shared library before `dart` loads it at runtime.

## Build

```bash
make
dart pub get
```

### Run Tests

```bash
make
dart pub get
dart test
```

## Usage

### Sender

```dart
import 'package:nozzle/nozzle.dart';

final sender = Sender.create(const SenderDesc(
  name: 'dart-sender',
  applicationName: 'MyApp',
  ringBufferSize: 3,
));
sender.close();

final frame = sender.acquireWritableFrame(1920, 1080, TextureFormat.rgba8Unorm);
final pixels = frame.lockWritablePixels(TextureOrigin.topLeft);
for (var y = 0; y < pixels.height; y++) {
  final row = pixels.row(y);
  for (var i = 0; i < row.length; i++) {
    row[i] = 0xFF;
  }
}
pixels.unmap();
sender.commitFrame(frame);
```

### Receiver

```dart
final receiver = Receiver.create(const ReceiverDesc(
  name: 'dart-sender',
  applicationName: 'MyViewer',
  receiveMode: ReceiveMode.latestOnly,
));
receiver.close();

final frame = receiver.acquireFrame(timeoutMs: 5000);
final info = frame.info();
print('${info.width}x${info.height} frame #${info.frameIndex}');
frame.release();
```

### Discovery

```dart
final senders = nozzle.enumerateSenders();
print('found ${senders.length} senders');
```

### GPU Check

```dart
if (isGpuAvailable()) {
  print('GPU available');
}
```

## Error Handling

All fallible operations throw [NozzleException] with a descriptive [ErrorCode]:

```dart
try {
  final frame = sender.acquireWritableFrame(0, 0, TextureFormat.unknown);
} on NozzleException catch (e) {
  if (e.code == ErrorCode.invalidArgument) {
    // handle bad args
  } else if (e.code == ErrorCode.unsupportedFormat) {
    // handle bad format
  }
}
```

## Texture Formats

| Format | Bytes/Pixel |
|--------|-------------|
| `r8Unorm` | 1 |
| `rg8Unorm` | 2 |
| `rgba8Unorm` / `bgra8Unorm` | 4 |
| `rgba8Srgb` / `bgra8Srgb` | 4 |
| `r16Unorm` | 2 |
| `rg16Unorm` | 4 |
| `rgba16Unorm` | 8 |
| `r16Float` | 2 |
| `rg16Float` | 4 |
| `rgba16Float` | 8 |
| `r32Float` | 4 |
| `rg32Float` | 8 |
| `rgba32Float` | 16 |
| `r32Uint` | 4 |
| `rgba32Uint` | 16 |
| `depth32Float` | 4 |

## Platform Notes

- **macOS**: Links Metal, IOSurface, Foundation, Accelerate, OpenGL frameworks automatically
- **Windows**: Links d3d11, dxgi, opengl32, bcrypt automatically
- **Linux**: Links drm, gbm, EGL, GL automatically

## License

MIT
