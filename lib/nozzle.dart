/// Dart FFI bindings for the nozzle GPU texture sharing library.
///
/// nozzle enables local inter-process GPU texture sharing via Metal/IOSurface (macOS),
/// D3D11 (Windows), and DMA-BUF (Linux).
///
/// Before using this library, build the nozzle native library:
///
/// ```bash
/// make
/// ```
library nozzle;

export 'src/types.dart';
export 'src/wrappers.dart';
