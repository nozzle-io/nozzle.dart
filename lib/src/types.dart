import 'dart:ffi';

/// Nozzle error codes returned by C API functions.
enum ErrorCode {
  ok(0),
  unknown(1),
  invalidArgument(2),
  unsupportedBackend(3),
  unsupportedFormat(4),
  deviceMismatch(5),
  resourceCreationFailed(6),
  sharedHandleFailed(7),
  senderNotFound(8),
  senderClosed(9),
  timeout(10),
  backendError(11);

  const ErrorCode(this.value);
  final int value;

  static ErrorCode fromValue(int v) =>
      ErrorCode.values.firstWhere((e) => e.value == v, orElse: () => unknown);

  String get message => switch (this) {
        ErrorCode.ok => 'ok',
        ErrorCode.unknown => 'unknown error',
        ErrorCode.invalidArgument => 'invalid argument',
        ErrorCode.unsupportedBackend => 'unsupported backend',
        ErrorCode.unsupportedFormat => 'unsupported format',
        ErrorCode.deviceMismatch => 'device mismatch',
        ErrorCode.resourceCreationFailed => 'resource creation failed',
        ErrorCode.sharedHandleFailed => 'shared handle failed',
        ErrorCode.senderNotFound => 'sender not found',
        ErrorCode.senderClosed => 'sender closed',
        ErrorCode.timeout => 'timeout',
        ErrorCode.backendError => 'backend error',
      };
}

/// GPU backend type.
enum BackendType {
  unknown(0),
  d3d11(1),
  metal(2),
  opengl(3),
  dmaBuf(4);

  const BackendType(this.value);
  final int value;

  static BackendType fromValue(int v) =>
      BackendType.values.firstWhere((e) => e.value == v, orElse: () => unknown);

  String get name => switch (this) {
        BackendType.d3d11 => 'd3d11',
        BackendType.metal => 'metal',
        BackendType.opengl => 'opengl',
        BackendType.dmaBuf => 'dma_buf',
        BackendType.unknown => 'unknown',
      };
}

/// Pixel format for textures.
enum TextureFormat {
  unknown(0),
  r8Unorm(1),
  rg8Unorm(2),
  rgba8Unorm(3),
  bgra8Unorm(4),
  rgba8Srgb(5),
  bgra8Srgb(6),
  r16Unorm(7),
  rg16Unorm(8),
  rgba16Unorm(9),
  r16Float(10),
  rg16Float(11),
  rgba16Float(12),
  r32Float(13),
  rg32Float(14),
  rgba32Float(15),
  r32Uint(16),
  rgba32Uint(17),
  depth32Float(18);

  const TextureFormat(this.value);
  final int value;

  static TextureFormat fromValue(int v) => TextureFormat.values
      .firstWhere((e) => e.value == v, orElse: () => unknown);

  /// Number of bytes per pixel, or 0 for unknown formats.
  int get bytesPerPixel => switch (this) {
        TextureFormat.r8Unorm => 1,
        TextureFormat.rg8Unorm => 2,
        TextureFormat.r16Unorm => 2,
        TextureFormat.r16Float => 2,
        TextureFormat.rgba8Unorm ||
        TextureFormat.bgra8Unorm ||
        TextureFormat.rgba8Srgb ||
        TextureFormat.bgra8Srgb ||
        TextureFormat.rg16Unorm ||
        TextureFormat.rg16Float ||
        TextureFormat.r32Float ||
        TextureFormat.r32Uint ||
        TextureFormat.depth32Float =>
          4,
        TextureFormat.rgba16Unorm ||
        TextureFormat.rgba16Float ||
        TextureFormat.rg32Float =>
          8,
        TextureFormat.rgba32Float || TextureFormat.rgba32Uint => 16,
        TextureFormat.unknown => 0,
      };
}

/// Controls how frames are acquired from a receiver.
enum ReceiveMode {
  latestOnly(0),
  sequentialBestEffort(1);

  const ReceiveMode(this.value);
  final int value;

  static ReceiveMode fromValue(int v) =>
      ReceiveMode.values.firstWhere((e) => e.value == v, orElse: () => latestOnly);
}

/// Frame acquisition result.
enum FrameStatus {
  newFrame(0),
  noNew(1),
  dropped(2),
  senderClosed(3),
  error(4);

  const FrameStatus(this.value);
  final int value;

  static FrameStatus fromValue(int v) => FrameStatus.values
      .firstWhere((e) => e.value == v, orElse: () => error);
}

/// Pixel data row ordering.
enum TextureOrigin {
  topLeft(0),
  bottomLeft(1);

  const TextureOrigin(this.value);
  final int value;

  static TextureOrigin fromValue(int v) => TextureOrigin.values
      .firstWhere((e) => e.value == v, orElse: () => topLeft);
}

/// How a texture format was determined.
enum FormatSource {
  unknown(0),
  requested(1),
  callerHint(2),
  nativeObserved(3);

  const FormatSource(this.value);
  final int value;

  static FormatSource fromValue(int v) => FormatSource.values
      .firstWhere((e) => e.value == v, orElse: () => unknown);
}

/// Identifies the type of a native GPU format value.
enum NativeFormatKind {
  unknown(0),
  mtlPixelFormat(1),
  dxgiFormat(2),
  drmFourcc(3),
  glInternalFormat(4);

  const NativeFormatKind(this.value);
  final int value;

  static NativeFormatKind fromValue(int v) => NativeFormatKind.values
      .firstWhere((e) => e.value == v, orElse: () => unknown);
}

/// Configuration for creating a sender.
class SenderDesc {
  const SenderDesc({
    required this.name,
    required this.applicationName,
    this.ringBufferSize = 3,
    this.allowFormatFallback = false,
  });

  final String name;
  final String applicationName;
  final int ringBufferSize;
  final bool allowFormatFallback;
}

/// Configuration for creating a receiver.
class ReceiverDesc {
  const ReceiverDesc({
    required this.name,
    required this.applicationName,
    this.receiveMode = ReceiveMode.latestOnly,
  });

  final String name;
  final String applicationName;
  final ReceiveMode receiveMode;
}

/// Configuration for frame acquisition timeout.
class AcquireDesc {
  const AcquireDesc({this.timeoutMs = 5000});

  final int timeoutMs;
}

/// Metadata about a sender.
class SenderInfo {
  const SenderInfo({
    required this.name,
    required this.applicationName,
    required this.id,
    required this.backend,
  });

  final String name;
  final String applicationName;
  final String id;
  final BackendType backend;
}

/// Detailed info about the connected sender.
class ConnectedSenderInfo {
  const ConnectedSenderInfo({
    required this.name,
    required this.applicationName,
    required this.id,
    required this.backend,
    required this.width,
    required this.height,
    required this.format,
    required this.estimatedFps,
    required this.frameCounter,
    required this.lastUpdateTimeNs,
  });

  final String name;
  final String applicationName;
  final String id;
  final BackendType backend;
  final int width;
  final int height;
  final TextureFormat format;
  final double estimatedFps;
  final int frameCounter;
  final int lastUpdateTimeNs;
}

/// Metadata about a frame.
class FrameInfo {
  const FrameInfo({
    required this.frameIndex,
    required this.timestampNs,
    required this.width,
    required this.height,
    required this.format,
    required this.droppedFrameCount,
  });

  final int frameIndex;
  final int timestampNs;
  final int width;
  final int height;
  final TextureFormat format;
  final int droppedFrameCount;
}

/// Configuration for wrapping a native GPU texture.
class TextureWrapDesc {
  const TextureWrapDesc({
    required this.nativeTexture,
    required this.width,
    required this.height,
    required this.format,
    required this.backend,
  });

  final Pointer<Void> nativeTexture;
  final int width;
  final int height;
  final TextureFormat format;
  final BackendType backend;
}

/// Detailed format resolution info.
class ResolvedTextureFormat {
  const ResolvedTextureFormat({
    required this.storageFormat,
    required this.semanticFormat,
    required this.formatSource,
    required this.nativeBackend,
    required this.nativeKind,
    required this.nativeValue,
    required this.channelOrder,
    required this.componentType,
    required this.componentBits,
    required this.channelCount,
    required this.bytesPerPixel,
  });

  final TextureFormat storageFormat;
  final TextureFormat semanticFormat;
  final FormatSource formatSource;
  final BackendType nativeBackend;
  final NativeFormatKind nativeKind;
  final int nativeValue;
  final int channelOrder;
  final int componentType;
  final int componentBits;
  final int channelCount;
  final int bytesPerPixel;
}

/// Exception thrown when a nozzle C API function returns a non-OK error code.
class NozzleException implements Exception {
  const NozzleException(this.code, this.message);

  final ErrorCode code;
  final String message;

  @override
  String toString() => 'NozzleException: $message (code: ${code.value})';
}
