import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'bindings.dart';
import 'types.dart';

class Nozzle {
  Nozzle._(this._bindings);

  final NozzleBindings _bindings;

  static Nozzle _instance = Nozzle._(loadBindings());

  static Nozzle get instance => _instance;

  static Nozzle reload(NozzleBindings bindings) {
    _instance = Nozzle._(bindings);
    return _instance;
  }
}

void _checkOk(int code) {
  final ec = ErrorCode.fromValue(code);
  if (ec != ErrorCode.ok) {
    throw NozzleException(ec, ec.message);
  }
}

/// Provides access to frame pixel data.
class MappedPixels {
  MappedPixels({
    required this.data,
    required this.rowStrideBytes,
    required this.width,
    required this.height,
    required this.format,
    required this.origin,
  })  : _frame = null,
        _writable = false,
        _bindings = null;

  MappedPixels._fromFfi({
    required this.data,
    required this.rowStrideBytes,
    required this.width,
    required this.height,
    required this.format,
    required this.origin,
    required Pointer<Void> frame,
    required bool writable,
    required NozzleBindings bindings,
  })  : _frame = frame,
        _writable = writable,
        _bindings = bindings;

  final Uint8List data;
  final int rowStrideBytes;
  final int width;
  final int height;
  final TextureFormat format;
  final TextureOrigin origin;
  final Pointer<Void>? _frame;
  final bool _writable;
  final NozzleBindings? _bindings;

  /// Returns a byte view for the given row, or throws [RangeError] if out of bounds.
  Uint8List row(int y) {
    if (y < 0 || y >= height) {
      throw RangeError.range(y, 0, height - 1, 'y');
    }
    final start = y * rowStrideBytes;
    return Uint8List.sublistView(data, start, start + rowStrideBytes);
  }

  /// Releases the pixel mapping.
  void unmap() {
    final frame = _frame;
    final bindings = _bindings;
    if (frame == null || bindings == null) return;
    if (_writable) {
      bindings.nozzle_frame_unlock_writable_pixels(frame.cast());
    } else {
      bindings.nozzle_frame_unlock_pixels(frame.cast());
    }
  }
}

/// Sends GPU textures to a named receiver.
class Sender {
  Sender._(this._ptr, this._bindings);

  final Pointer<NozzleSender> _ptr;
  final NozzleBindings _bindings;
  bool _closed = false;

  factory Sender.create(SenderDesc desc) {
    final b = Nozzle.instance._bindings;
    final cName = desc.name.toNativeUtf8();
    final cAppName = desc.applicationName.toNativeUtf8();
    final nativeDesc = malloc<NativeNozzleSenderDesc>();
    nativeDesc.ref
      ..name = cName
      ..application_name = cAppName
      ..ring_buffer_size = desc.ringBufferSize
      ..allow_format_fallback = desc.allowFormatFallback ? 1 : 0;

    final outSender = malloc<Pointer<NozzleSender>>();
    try {
      final code = b.nozzle_sender_create(nativeDesc, outSender);
      _checkOk(code);
      return Sender._(outSender.value, b);
    } finally {
      malloc.free(cName);
      malloc.free(cAppName);
      malloc.free(nativeDesc);
      malloc.free(outSender);
    }
  }

  void close() {
    if (!_closed) {
      _bindings.nozzle_sender_destroy(_ptr);
      _closed = true;
    }
  }

  void publishTexture(Texture tex) {
    _bindings.nozzle_sender_publish_texture(_ptr, tex._ptr);
  }

  Frame acquireWritableFrame(int width, int height, TextureFormat format) {
    final outFrame = malloc<Pointer<NozzleFrame>>();
    try {
      final code = _bindings.nozzle_sender_acquire_writable_frame(
          _ptr, width, height, format.value, outFrame);
      _checkOk(code);
      return Frame._(outFrame.value, _bindings);
    } finally {
      malloc.free(outFrame);
    }
  }

  void commitFrame(Frame frame) {
    _checkOk(_bindings.nozzle_sender_commit_frame(_ptr, frame._ptr));
  }

  void publishGlTexture(
      int glName, int glTarget, int width, int height, TextureFormat format) {
    _checkOk(_bindings.nozzle_sender_publish_gl_texture(
        _ptr, glName, glTarget, width, height, format.value));
  }

  void publishNativeTexture(
      Pointer<Void> nativeTex, int width, int height, TextureFormat format) {
    _checkOk(_bindings.nozzle_sender_publish_native_texture(
        _ptr, nativeTex, width, height, format.value));
  }

  SenderInfo info() {
    final outInfo = malloc<NativeNozzleSenderInfo>();
    try {
      _checkOk(_bindings.nozzle_sender_get_info(_ptr, outInfo));
      final ref = outInfo.ref;
      return SenderInfo(
        name: ref.name.toDartString(),
        applicationName: ref.application_name.toDartString(),
        id: ref.id.toDartString(),
        backend: BackendType.fromValue(ref.backend),
      );
    } finally {
      malloc.free(outInfo);
    }
  }
}

/// Receives GPU textures from a named sender.
class Receiver {
  Receiver._(this._ptr, this._bindings);

  final Pointer<NozzleReceiver> _ptr;
  final NozzleBindings _bindings;
  bool _closed = false;

  factory Receiver.create(ReceiverDesc desc) {
    final b = Nozzle.instance._bindings;
    final cName = desc.name.toNativeUtf8();
    final cAppName = desc.applicationName.toNativeUtf8();
    final nativeDesc = malloc<NativeNozzleReceiverDesc>();
    nativeDesc.ref
      ..name = cName
      ..application_name = cAppName
      ..receive_mode = desc.receiveMode.value;

    final outReceiver = malloc<Pointer<NozzleReceiver>>();
    try {
      final code = b.nozzle_receiver_create(nativeDesc, outReceiver);
      _checkOk(code);
      return Receiver._(outReceiver.value, b);
    } finally {
      malloc.free(cName);
      malloc.free(cAppName);
      malloc.free(nativeDesc);
      malloc.free(outReceiver);
    }
  }

  void close() {
    if (!_closed) {
      _bindings.nozzle_receiver_destroy(_ptr);
      _closed = true;
    }
  }

  Frame acquireFrame({int timeoutMs = 5000}) {
    final acquireDesc = malloc<NativeNozzleAcquireDesc>();
    acquireDesc.ref.timeout_ms = timeoutMs;
    final outFrame = malloc<Pointer<NozzleFrame>>();
    try {
      final code =
          _bindings.nozzle_receiver_acquire_frame(_ptr, acquireDesc, outFrame);
      _checkOk(code);
      return Frame._(outFrame.value, _bindings);
    } finally {
      malloc.free(acquireDesc);
      malloc.free(outFrame);
    }
  }

  ConnectedSenderInfo connectedInfo() {
    final outInfo = malloc<NativeNozzleConnectedSenderInfo>();
    try {
      _checkOk(_bindings.nozzle_receiver_get_connected_info(_ptr, outInfo));
      final ref = outInfo.ref;
      return ConnectedSenderInfo(
        name: ref.name.toDartString(),
        applicationName: ref.application_name.toDartString(),
        id: ref.id.toDartString(),
        backend: BackendType.fromValue(ref.backend),
        width: ref.width,
        height: ref.height,
        format: TextureFormat.fromValue(ref.format),
        estimatedFps: ref.estimated_fps,
        frameCounter: ref.frame_counter,
        lastUpdateTimeNs: ref.last_update_time_ns,
      );
    } finally {
      malloc.free(outInfo);
    }
  }

  bool get isConnected {
    try {
      connectedInfo();
      return true;
    } on NozzleException {
      return false;
    }
  }
}

/// Represents a GPU texture frame.
class Frame {
  Frame._(this._ptr, this._bindings);

  final Pointer<NozzleFrame> _ptr;
  final NozzleBindings _bindings;

  void release() {
    _bindings.nozzle_frame_release(_ptr);
  }

  FrameInfo info() {
    final outInfo = malloc<NativeNozzleFrameInfo>();
    try {
      _checkOk(_bindings.nozzle_frame_get_info(_ptr, outInfo));
      final ref = outInfo.ref;
      return FrameInfo(
        frameIndex: ref.frame_index,
        timestampNs: ref.timestamp_ns,
        width: ref.width,
        height: ref.height,
        format: TextureFormat.fromValue(ref.format),
        droppedFrameCount: ref.dropped_frame_count,
      );
    } finally {
      malloc.free(outInfo);
    }
  }

  MappedPixels lockPixels(TextureOrigin origin) {
    return _lockPixels(origin, false);
  }

  MappedPixels lockWritablePixels(TextureOrigin origin) {
    return _lockPixels(origin, true);
  }

  MappedPixels _lockPixels(TextureOrigin origin, bool writable) {
    final outPixels = malloc<NativeNozzleMappedPixels>();
    try {
      final code = writable
          ? _bindings.nozzle_frame_lock_writable_pixels_with_origin(
              _ptr, origin.value, outPixels)
          : _bindings.nozzle_frame_lock_pixels_with_origin(
              _ptr, origin.value, outPixels);
      _checkOk(code);
      final ref = outPixels.ref;
      final totalSize = ref.height * ref.row_stride_bytes;
      final data = ref.data.cast<Uint8>().asTypedList(totalSize);
      return MappedPixels._fromFfi(
        data: data,
        rowStrideBytes: ref.row_stride_bytes,
        width: ref.width,
        height: ref.height,
        format: TextureFormat.fromValue(ref.format),
        origin: TextureOrigin.fromValue(ref.origin),
        frame: _ptr.cast(),
        writable: writable,
        bindings: _bindings,
      );
    } finally {
      malloc.free(outPixels);
    }
  }

  void copyToGlTexture(
      int glName, int glTarget, int width, int height, TextureFormat format) {
    _checkOk(_bindings.nozzle_frame_copy_to_gl_texture(
        _ptr, glName, glTarget, width, height, format.value));
  }

  void copyToNativeTexture(
      Pointer<Void> nativeTex, int width, int height, TextureFormat format) {
    _checkOk(_bindings.nozzle_frame_copy_to_native_texture(
        _ptr, nativeTex, width, height, format.value));
  }

  ResolvedTextureFormat resolvedFormat() {
    final outResolved = malloc<NativeNozzleResolvedTextureFormat>();
    try {
      _checkOk(_bindings.nozzle_frame_get_resolved_format(_ptr, outResolved));
      final ref = outResolved.ref;
      return ResolvedTextureFormat(
        storageFormat: TextureFormat.fromValue(ref.storage_format),
        semanticFormat: TextureFormat.fromValue(ref.semantic_format),
        formatSource: FormatSource.fromValue(ref.format_source),
        nativeBackend: BackendType.fromValue(ref.native_backend),
        nativeKind: NativeFormatKind.fromValue(ref.native_kind),
        nativeValue: ref.native_value,
        channelOrder: ref.channel_order,
        componentType: ref.component_type,
        componentBits: ref.component_bits,
        channelCount: ref.channel_count,
        bytesPerPixel: ref.bytes_per_pixel,
      );
    } finally {
      malloc.free(outResolved);
    }
  }
}

/// Represents a wrapped native GPU texture.
class Texture {
  Texture._(this._ptr, this._bindings);

  final Pointer<NozzleTexture> _ptr;
  final NozzleBindings _bindings;
  bool _closed = false;

  factory Texture.wrap(TextureWrapDesc desc) {
    final b = Nozzle.instance._bindings;
    final nativeDesc = malloc<NativeNozzleTextureWrapDesc>();
    nativeDesc.ref
      ..native_texture = desc.nativeTexture
      ..width = desc.width
      ..height = desc.height
      ..format = desc.format.value
      ..backend = desc.backend.value;

    final outTexture = malloc<Pointer<NozzleTexture>>();
    try {
      final code = b.nozzle_texture_wrap(nativeDesc, outTexture);
      _checkOk(code);
      return Texture._(outTexture.value, b);
    } finally {
      malloc.free(nativeDesc);
      malloc.free(outTexture);
    }
  }

  void close() {
    if (!_closed) {
      _bindings.nozzle_texture_destroy(_ptr);
      _closed = true;
    }
  }
}

/// Represents a GPU device.
class Device {
  Device._(this._ptr, this._bindings);

  final Pointer<NozzleDevice> _ptr;
  final NozzleBindings _bindings;
  bool _closed = false;

  factory Device.getDefault() {
    final b = Nozzle.instance._bindings;
    final outDevice = malloc<Pointer<NozzleDevice>>();
    try {
      final code = b.nozzle_device_get_default(outDevice);
      _checkOk(code);
      return Device._(outDevice.value, b);
    } finally {
      malloc.free(outDevice);
    }
  }

  void close() {
    if (!_closed) {
      _bindings.nozzle_device_destroy(_ptr);
      _closed = true;
    }
  }
}

/// Enumerates active senders and returns the list of [SenderInfo].
List<SenderInfo> enumerateSenders() {
  final b = Nozzle.instance._bindings;
  final outArray = malloc<NativeNozzleSenderInfoArray>();
  try {
    _checkOk(b.nozzle_enumerate_senders(outArray));
    final ref = outArray.ref;
    final count = ref.count;
    final result = <SenderInfo>[];
    for (var i = 0; i < count; i++) {
      final item = (ref.items + i).ref;
      result.add(SenderInfo(
        name: item.name.toDartString(),
        applicationName: item.application_name.toDartString(),
        id: item.id.toDartString(),
        backend: BackendType.fromValue(item.backend),
      ));
    }
    b.nozzle_free_sender_info_array(outArray);
    return result;
  } catch (_) {
    b.nozzle_free_sender_info_array(outArray);
    rethrow;
  }
}

/// Rearranges channel order in pixel data.
void swizzleChannels(Pointer<Void> src, Pointer<Void> dst, int width, int height,
    int srcRowBytes, int dstRowBytes, TextureFormat format, List<int> permuteMap) {
  assert(permuteMap.length == 4);
  final b = Nozzle.instance._bindings;
  final permutePtr = malloc<Uint8>(4);
  try {
    for (var i = 0; i < 4; i++) {
      permutePtr[i] = permuteMap[i];
    }
    _checkOk(b.nozzle_swizzle_channels(src, dst, width, height, srcRowBytes,
        dstRowBytes, format.value, permutePtr));
  } finally {
    malloc.free(permutePtr);
  }
}

/// Converts 16-bit pixel data to 32-bit.
void widenUint16ToUint32(Pointer<Void> src, Pointer<Void> dst, int width,
    int height, int srcRowBytes, int dstRowBytes, int channels) {
  final b = Nozzle.instance._bindings;
  _checkOk(b.nozzle_widen_uint16_to_uint32(
      src, dst, width, height, srcRowBytes, dstRowBytes, channels));
}

/// Converts 32-bit unsigned integer pixel data to float.
void convertUint32ToFloat32(Pointer<Void> src, Pointer<Void> dst, int width,
    int height, int srcRowBytes, int dstRowBytes, int channels) {
  final b = Nozzle.instance._bindings;
  _checkOk(b.nozzle_convert_uint32_to_float32(
      src, dst, width, height, srcRowBytes, dstRowBytes, channels));
}

/// Checks if a GPU backend is available by attempting sender creation.
bool isGpuAvailable() {
  try {
    final sender = Sender.create(const SenderDesc(
      name: 'nozzle-dart-gpu-check',
      applicationName: 'nozzle-dart',
      ringBufferSize: 1,
    ));
    sender.close();
    return true;
  } on NozzleException {
    return false;
  }
}
