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

These snippets show the successful lifecycle sequence. Keep senders and receivers
open until their frame operations are finished; `close()` destroys the native
object. The current binding does not guard subsequent operations on closed objects.

### Sender

```dart
import 'package:nozzle/nozzle.dart';

final sender = Sender.create(const SenderDesc(
  name: 'dart-sender',
  applicationName: 'MyApp',
  ringBufferSize: 3,
));
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
frame.release(); // commitFrame does not release the C frame wrapper.

// Keep sender alive while receivers need the published texture.
// At application shutdown, after all publishing is finished:
sender.close();
```

### Receiver

```dart
final receiver = Receiver.create(const ReceiverDesc(
  name: 'dart-sender',
  applicationName: 'MyViewer',
  receiveMode: ReceiveMode.latestOnly,
));
final frame = receiver.acquireFrame(timeoutMs: 5000);
final info = frame.info();
print('${info.width}x${info.height} frame #${info.frameIndex}');
frame.release();
receiver.close();
```

Do not close a sender immediately after publishing in a running application: it
unpublishes that sender. The white-fill example is not a channel-order test.
These snippets do not demonstrate failed writable-frame recovery; the current
Dart wrapper has no explicit discard method. Releasing a frame wrapper alone is
not a substitute for discarding an uncommitted sender reservation.

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

### Owned Metadata and Connection State

`Sender.info()` and `Receiver.connectedInfo()` use caller-owned native snapshots
and return owned Dart strings and values. Existing signatures, metadata fields
(including `nativeFormatModifier`), defaults, and native-error behavior remain
unchanged. Discovery keeps its separate enumeration allocation/free contract.

`Receiver.connectionSnapshot()` returns a `ConnectionSnapshot` with `connected`
and `info` copied together by one native call. `connectedInfo()` projects its
metadata, including the last-known identity after an observed disconnect.
`isConnected` reads the snapshot flag and returns false on `NozzleException`;
successful metadata retrieval alone no longer means connected. These getters
report last-observed state, not fresh liveness or an automatic reconnect.

Inline strings are decoded only within their native capacities and before
freeing the snapshot allocation. UTF-8 decoding remains strict: malformed data
throws `FormatException`, not silent replacement or a false connection result.
Returned values survive later calls and handle closure. This does not add
thread/race safety or make operations on closed handles valid; keep the existing
open-handle lifetime discipline.

The loaded native library must provide `nozzle_sender_get_info_snapshot` and
`nozzle_receiver_get_connected_info_snapshot` in addition to the existing
exports; the pinned core includes both. There is no borrowed-getter fallback.
Custom `NozzleBindings` implementations passed to `Nozzle.reload` must implement
these two additional methods and fill the complete inline snapshot structs.
Legacy low-level getters remain available, but the high-level getters no longer
use them.

### Metadata Test Boundaries

The normal CI test run discovers two required macOS same-process metadata cases
in `test/info_snapshot_test.dart`, using the locally built core dylib and real
Metal-backed handles. They check exact `senderClosed` after sender closure,
retained identity with a false connection flag, and owned UTF-8 values after both
handles close. Library/backend failures fail these cases; the existing optional
GPU tests and their skips are unchanged. These cases publish no frames and make
no pixel, cross-process, or Windows/Linux receiver-lifecycle claim.

All three OS jobs also run compiler-derived snapshot layout checks and synthetic
conversion checks through the [header-only probe](test/native/README.md), while
retaining the legacy ABI regressions. Synthetic fractional FPS and counters above
32 bits prove conversion, not observed native stream values or the full unsigned
64-bit range in Dart. Windows/Linux builds and portable checks do not substitute
for macOS lifecycle evidence.

## Error Handling

Native error codes are reported as [NozzleException] with a descriptive
[ErrorCode]. Strict snapshot UTF-8 decoding can separately throw
`FormatException` as described above:

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
