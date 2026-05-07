import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ========== Opaque Types ==========

base class NozzleSender extends Opaque {}
base class NozzleReceiver extends Opaque {}
base class NozzleFrame extends Opaque {}
base class NozzleTexture extends Opaque {}
base class NozzleDevice extends Opaque {}

// ========== FFI Structs ==========

base class NativeNozzleSenderDesc extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> application_name;
  @Uint32()
  external int ring_buffer_size;
  @Int32()
  external int allow_format_fallback;
}

base class NativeNozzleReceiverDesc extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> application_name;
  @Uint32()
  external int receive_mode;
}

base class NativeNozzleAcquireDesc extends Struct {
  @Uint64()
  external int timeout_ms;
}

base class NativeNozzleSenderInfo extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> application_name;
  external Pointer<Utf8> id;
  @Uint32()
  external int backend;
}

base class NativeNozzleConnectedSenderInfo extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> application_name;
  external Pointer<Utf8> id;
  @Uint32()
  external int backend;
  @Uint32()
  external int width;
  @Uint32()
  external int height;
  @Uint32()
  external int format;
  @Uint32()
  external int semantic_format;
  @Double()
  external double estimated_fps;
  @Uint64()
  external int frame_counter;
  @Uint64()
  external int last_update_time_ns;
  @Uint64()
  external int native_format_modifier;
}

base class NativeNozzleFrameInfo extends Struct {
  @Uint64()
  external int frame_index;
  @Uint64()
  external int timestamp_ns;
  @Uint32()
  external int width;
  @Uint32()
  external int height;
  @Uint32()
  external int format;
  @Uint32()
  external int semantic_format;
  @Uint32()
  external int transfer_mode;
  @Uint32()
  external int sync_mode;
  @Uint32()
  external int dropped_frame_count;
}

base class NativeNozzleSenderInfoArray extends Struct {
  external Pointer<NativeNozzleSenderInfo> items;
  @Uint32()
  external int count;
}

base class NativeNozzleTextureWrapDesc extends Struct {
  external Pointer<Void> native_texture;
  @Uint32()
  external int width;
  @Uint32()
  external int height;
  @Uint32()
  external int format;
  @Uint32()
  external int backend;
}

base class NativeNozzleResolvedTextureFormat extends Struct {
  @Uint32()
  external int storage_format;
  @Uint32()
  external int semantic_format;
  @Uint32()
  external int format_source;
  @Uint32()
  external int native_backend;
  @Uint32()
  external int native_kind;
  @Uint32()
  external int native_value;
  @Uint32()
  external int channel_order;
  @Uint32()
  external int component_type;
  @Uint8()
  external int component_bits;
  @Uint8()
  external int channel_count;
  @Uint8()
  external int bytes_per_pixel;
}

base class NativeNozzleMappedPixels extends Struct {
  external Pointer<Void> data;
  @Int64()
  external int row_stride_bytes;
  @Uint32()
  external int width;
  @Uint32()
  external int height;
  @Uint32()
  external int format;
  @Uint32()
  external int origin;
}

// ========== Pointer Type Aliases ==========

typedef NozzleSenderPtr = Pointer<NozzleSender>;
typedef NozzleReceiverPtr = Pointer<NozzleReceiver>;
typedef NozzleFramePtr = Pointer<NozzleFrame>;
typedef NozzleTexturePtr = Pointer<NozzleTexture>;
typedef NozzleDevicePtr = Pointer<NozzleDevice>;

// ========== Native Function Typedefs ==========

typedef _SenderCreateNative = Uint32 Function(
    Pointer<NativeNozzleSenderDesc>, Pointer<Pointer<NozzleSender>>);
typedef _SenderDestroyNative = Void Function(NozzleSenderPtr);
typedef _SenderPublishTextureNative = Uint32 Function(
    NozzleSenderPtr, NozzleTexturePtr);
typedef _SenderAcquireWritableFrameNative = Uint32 Function(
    NozzleSenderPtr, Uint32, Uint32, Uint32, Pointer<Pointer<NozzleFrame>>);
typedef _SenderCommitFrameNative = Uint32 Function(
    NozzleSenderPtr, NozzleFramePtr);
typedef _SenderPublishGlTextureNative = Uint32 Function(
    NozzleSenderPtr, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef _SenderPublishNativeTextureNative = Uint32 Function(
    NozzleSenderPtr, Pointer<Void>, Uint32, Uint32, Uint32);
typedef _SenderGetInfoNative = Uint32 Function(
    NozzleSenderPtr, Pointer<NativeNozzleSenderInfo>);
typedef _ReceiverCreateNative = Uint32 Function(
    Pointer<NativeNozzleReceiverDesc>, Pointer<Pointer<NozzleReceiver>>);
typedef _ReceiverDestroyNative = Void Function(NozzleReceiverPtr);
typedef _ReceiverAcquireFrameNative = Uint32 Function(NozzleReceiverPtr,
    Pointer<NativeNozzleAcquireDesc>, Pointer<Pointer<NozzleFrame>>);
typedef _ReceiverGetConnectedInfoNative = Uint32 Function(NozzleReceiverPtr,
    Pointer<NativeNozzleConnectedSenderInfo>);
typedef _FrameReleaseNative = Void Function(NozzleFramePtr);
typedef _FrameGetInfoNative = Uint32 Function(
    NozzleFramePtr, Pointer<NativeNozzleFrameInfo>);
typedef _FrameLockPixelsNative = Uint32 Function(
    NozzleFramePtr, Uint32, Pointer<NativeNozzleMappedPixels>);
typedef _FrameUnlockPixelsNative = Void Function(NozzleFramePtr);
typedef _FrameLockWritablePixelsNative = Uint32 Function(
    NozzleFramePtr, Uint32, Pointer<NativeNozzleMappedPixels>);
typedef _FrameUnlockWritablePixelsNative = Void Function(NozzleFramePtr);
typedef _FrameCopyToGlTextureNative = Uint32 Function(
    NozzleFramePtr, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef _FrameCopyToNativeTextureNative = Uint32 Function(
    NozzleFramePtr, Pointer<Void>, Uint32, Uint32, Uint32);
typedef _FrameGetResolvedFormatNative = Uint32 Function(NozzleFramePtr,
    Pointer<NativeNozzleResolvedTextureFormat>);
typedef _EnumerateSendersNative = Uint32 Function(
    Pointer<NativeNozzleSenderInfoArray>);
typedef _FreeSenderInfoArrayNative = Void Function(
    Pointer<NativeNozzleSenderInfoArray>);
typedef _DeviceGetDefaultNative = Uint32 Function(
    Pointer<Pointer<NozzleDevice>>);
typedef _DeviceDestroyNative = Void Function(NozzleDevicePtr);
typedef _TextureWrapNative = Uint32 Function(Pointer<NativeNozzleTextureWrapDesc>,
    Pointer<Pointer<NozzleTexture>>);
typedef _TextureDestroyNative = Void Function(NozzleTexturePtr);
typedef _SwizzleChannelsNative = Uint32 Function(Pointer<Void>, Pointer<Void>,
    Uint32, Uint32, Uint32, Uint32, Uint32, Pointer<Uint8>);
typedef _WidenUint16ToUint32Native = Uint32 Function(Pointer<Void>,
    Pointer<Void>, Uint32, Uint32, Uint32, Uint32, Uint32);
typedef _ConvertUint32ToFloat32Native = Uint32 Function(Pointer<Void>,
    Pointer<Void>, Uint32, Uint32, Uint32, Uint32, Uint32);

// ========== Dart Function Typedefs ==========

typedef _SenderCreateDart = int Function(
    Pointer<NativeNozzleSenderDesc>, Pointer<Pointer<NozzleSender>>);
typedef _SenderDestroyDart = void Function(NozzleSenderPtr);
typedef _SenderPublishTextureDart = int Function(
    NozzleSenderPtr, NozzleTexturePtr);
typedef _SenderAcquireWritableFrameDart = int Function(
    NozzleSenderPtr, int, int, int, Pointer<Pointer<NozzleFrame>>);
typedef _SenderCommitFrameDart = int Function(
    NozzleSenderPtr, NozzleFramePtr);
typedef _SenderPublishGlTextureDart = int Function(
    NozzleSenderPtr, int, int, int, int, int);
typedef _SenderPublishNativeTextureDart = int Function(
    NozzleSenderPtr, Pointer<Void>, int, int, int);
typedef _SenderGetInfoDart = int Function(
    NozzleSenderPtr, Pointer<NativeNozzleSenderInfo>);
typedef _ReceiverCreateDart = int Function(
    Pointer<NativeNozzleReceiverDesc>, Pointer<Pointer<NozzleReceiver>>);
typedef _ReceiverDestroyDart = void Function(NozzleReceiverPtr);
typedef _ReceiverAcquireFrameDart = int Function(NozzleReceiverPtr,
    Pointer<NativeNozzleAcquireDesc>, Pointer<Pointer<NozzleFrame>>);
typedef _ReceiverGetConnectedInfoDart = int Function(NozzleReceiverPtr,
    Pointer<NativeNozzleConnectedSenderInfo>);
typedef _FrameReleaseDart = void Function(NozzleFramePtr);
typedef _FrameGetInfoDart = int Function(
    NozzleFramePtr, Pointer<NativeNozzleFrameInfo>);
typedef _FrameLockPixelsDart = int Function(
    NozzleFramePtr, int, Pointer<NativeNozzleMappedPixels>);
typedef _FrameUnlockPixelsDart = void Function(NozzleFramePtr);
typedef _FrameLockWritablePixelsDart = int Function(
    NozzleFramePtr, int, Pointer<NativeNozzleMappedPixels>);
typedef _FrameUnlockWritablePixelsDart = void Function(NozzleFramePtr);
typedef _FrameCopyToGlTextureDart = int Function(
    NozzleFramePtr, int, int, int, int, int);
typedef _FrameCopyToNativeTextureDart = int Function(
    NozzleFramePtr, Pointer<Void>, int, int, int);
typedef _FrameGetResolvedFormatDart = int Function(NozzleFramePtr,
    Pointer<NativeNozzleResolvedTextureFormat>);
typedef _EnumerateSendersDart = int Function(
    Pointer<NativeNozzleSenderInfoArray>);
typedef _FreeSenderInfoArrayDart = void Function(
    Pointer<NativeNozzleSenderInfoArray>);
typedef _DeviceGetDefaultDart = int Function(Pointer<Pointer<NozzleDevice>>);
typedef _DeviceDestroyDart = void Function(NozzleDevicePtr);
typedef _TextureWrapDart = int Function(Pointer<NativeNozzleTextureWrapDesc>,
    Pointer<Pointer<NozzleTexture>>);
typedef _TextureDestroyDart = void Function(NozzleTexturePtr);
typedef _SwizzleChannelsDart = int Function(Pointer<Void>, Pointer<Void>, int,
    int, int, int, int, Pointer<Uint8>);
typedef _WidenUint16ToUint32Dart = int Function(Pointer<Void>, Pointer<Void>,
    int, int, int, int, int);
typedef _ConvertUint32ToFloat32Dart = int Function(Pointer<Void>,
    Pointer<Void>, int, int, int, int, int);

// ========== Bindings Class ==========

abstract class NozzleBindings {
  int nozzle_sender_create(Pointer<NativeNozzleSenderDesc> desc,
      Pointer<Pointer<NozzleSender>> out_sender);
  void nozzle_sender_destroy(NozzleSenderPtr sender);
  int nozzle_sender_publish_texture(
      NozzleSenderPtr sender, NozzleTexturePtr texture);
  int nozzle_sender_acquire_writable_frame(NozzleSenderPtr sender, int width,
      int height, int format, Pointer<Pointer<NozzleFrame>> out_frame);
  int nozzle_sender_commit_frame(NozzleSenderPtr sender, NozzleFramePtr frame);
  int nozzle_sender_publish_gl_texture(NozzleSenderPtr sender, int glName,
      int glTarget, int width, int height, int format);
  int nozzle_sender_publish_native_texture(NozzleSenderPtr sender,
      Pointer<Void> nativeTexture, int width, int height, int format);
  int nozzle_sender_get_info(
      NozzleSenderPtr sender, Pointer<NativeNozzleSenderInfo> outInfo);
  int nozzle_receiver_create(Pointer<NativeNozzleReceiverDesc> desc,
      Pointer<Pointer<NozzleReceiver>> out_receiver);
  void nozzle_receiver_destroy(NozzleReceiverPtr receiver);
  int nozzle_receiver_acquire_frame(NozzleReceiverPtr receiver,
      Pointer<NativeNozzleAcquireDesc> desc, Pointer<Pointer<NozzleFrame>> out);
  int nozzle_receiver_get_connected_info(NozzleReceiverPtr receiver,
      Pointer<NativeNozzleConnectedSenderInfo> outInfo);
  void nozzle_frame_release(NozzleFramePtr frame);
  int nozzle_frame_get_info(
      NozzleFramePtr frame, Pointer<NativeNozzleFrameInfo> outInfo);
  int nozzle_frame_lock_pixels_with_origin(NozzleFramePtr frame, int origin,
      Pointer<NativeNozzleMappedPixels> outPixels);
  void nozzle_frame_unlock_pixels(NozzleFramePtr frame);
  int nozzle_frame_lock_writable_pixels_with_origin(NozzleFramePtr frame,
      int origin, Pointer<NativeNozzleMappedPixels> outPixels);
  void nozzle_frame_unlock_writable_pixels(NozzleFramePtr frame);
  int nozzle_frame_copy_to_gl_texture(NozzleFramePtr frame, int glName,
      int glTarget, int width, int height, int format);
  int nozzle_frame_copy_to_native_texture(NozzleFramePtr frame,
      Pointer<Void> nativeTexture, int width, int height, int format);
  int nozzle_frame_get_resolved_format(NozzleFramePtr frame,
      Pointer<NativeNozzleResolvedTextureFormat> outResolved);
  int nozzle_enumerate_senders(Pointer<NativeNozzleSenderInfoArray> outArray);
  void nozzle_free_sender_info_array(
      Pointer<NativeNozzleSenderInfoArray> array);
  int nozzle_device_get_default(Pointer<Pointer<NozzleDevice>> outDevice);
  void nozzle_device_destroy(NozzleDevicePtr device);
  int nozzle_texture_wrap(Pointer<NativeNozzleTextureWrapDesc> desc,
      Pointer<Pointer<NozzleTexture>> outTexture);
  void nozzle_texture_destroy(NozzleTexturePtr texture);
  int nozzle_swizzle_channels(Pointer<Void> src, Pointer<Void> dst, int width,
      int height, int srcRowBytes, int dstRowBytes, int format,
      Pointer<Uint8> permuteMap);
  int nozzle_widen_uint16_to_uint32(Pointer<Void> src, Pointer<Void> dst,
      int width, int height, int srcRowBytes, int dstRowBytes, int channels);
  int nozzle_convert_uint32_to_float32(Pointer<Void> src, Pointer<Void> dst,
      int width, int height, int srcRowBytes, int dstRowBytes, int channels);
}

// ========== DynamicLibrary Loader ==========

DynamicLibrary _openLibrary() {
  final libName = _libFileName();
  // Try .build/ relative to project root (pubspec.yaml location)
  final candidates = <String>[];
  final cwd = Directory.current.path;
  candidates.add('$cwd/.build/$libName');
  // When running tests, Platform.script is test/nozzle_test.dart
  try {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    candidates.add('${scriptDir.path}/../.build/$libName');
    candidates.add('${scriptDir.path}/.build/$libName');
  } catch (_) {}
  for (final path in candidates) {
    if (File(path).existsSync()) {
      return DynamicLibrary.open(path);
    }
  }
  return DynamicLibrary.open(libName);
}

String _libFileName() {
  if (Platform.isMacOS) return 'libnozzle.dylib';
  if (Platform.isWindows) return 'nozzle.dll';
  if (Platform.isLinux) return 'libnozzle.so';
  throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
}

NozzleBindings loadBindings() {
  final lib = _openLibrary();
  return _FfiBindings(lib);
}

class _FfiBindings implements NozzleBindings {
  _FfiBindings(DynamicLibrary lib) {
    _senderCreate = lib.lookupFunction<_SenderCreateNative, _SenderCreateDart>(
        'nozzle_sender_create');
    _senderDestroy = lib.lookupFunction<_SenderDestroyNative, _SenderDestroyDart>(
        'nozzle_sender_destroy');
    _senderPublishTexture = lib.lookupFunction<
        _SenderPublishTextureNative,
        _SenderPublishTextureDart>('nozzle_sender_publish_texture');
    _senderAcquireWritableFrame = lib.lookupFunction<
        _SenderAcquireWritableFrameNative,
        _SenderAcquireWritableFrameDart>(
        'nozzle_sender_acquire_writable_frame');
    _senderCommitFrame = lib.lookupFunction<_SenderCommitFrameNative,
        _SenderCommitFrameDart>('nozzle_sender_commit_frame');
    _senderPublishGlTexture = lib.lookupFunction<
        _SenderPublishGlTextureNative,
        _SenderPublishGlTextureDart>('nozzle_sender_publish_gl_texture');
    _senderPublishNativeTexture = lib.lookupFunction<
        _SenderPublishNativeTextureNative,
        _SenderPublishNativeTextureDart>('nozzle_sender_publish_native_texture');
    _senderGetInfo = lib.lookupFunction<_SenderGetInfoNative, _SenderGetInfoDart>(
        'nozzle_sender_get_info');
    _receiverCreate = lib.lookupFunction<_ReceiverCreateNative,
        _ReceiverCreateDart>('nozzle_receiver_create');
    _receiverDestroy = lib.lookupFunction<_ReceiverDestroyNative,
        _ReceiverDestroyDart>('nozzle_receiver_destroy');
    _receiverAcquireFrame = lib.lookupFunction<_ReceiverAcquireFrameNative,
        _ReceiverAcquireFrameDart>('nozzle_receiver_acquire_frame');
    _receiverGetConnectedInfo = lib.lookupFunction<
        _ReceiverGetConnectedInfoNative,
        _ReceiverGetConnectedInfoDart>('nozzle_receiver_get_connected_info');
    _frameRelease = lib.lookupFunction<_FrameReleaseNative, _FrameReleaseDart>(
        'nozzle_frame_release');
    _frameGetInfo = lib.lookupFunction<_FrameGetInfoNative, _FrameGetInfoDart>(
        'nozzle_frame_get_info');
    _frameLockPixels = lib.lookupFunction<_FrameLockPixelsNative,
        _FrameLockPixelsDart>('nozzle_frame_lock_pixels_with_origin');
    _frameUnlockPixels = lib.lookupFunction<_FrameUnlockPixelsNative,
        _FrameUnlockPixelsDart>('nozzle_frame_unlock_pixels');
    _frameLockWritablePixels = lib.lookupFunction<
        _FrameLockWritablePixelsNative,
        _FrameLockWritablePixelsDart>(
        'nozzle_frame_lock_writable_pixels_with_origin');
    _frameUnlockWritablePixels = lib.lookupFunction<
        _FrameUnlockWritablePixelsNative,
        _FrameUnlockWritablePixelsDart>('nozzle_frame_unlock_writable_pixels');
    _frameCopyToGlTexture = lib.lookupFunction<_FrameCopyToGlTextureNative,
        _FrameCopyToGlTextureDart>('nozzle_frame_copy_to_gl_texture');
    _frameCopyToNativeTexture = lib.lookupFunction<
        _FrameCopyToNativeTextureNative,
        _FrameCopyToNativeTextureDart>('nozzle_frame_copy_to_native_texture');
    _frameGetResolvedFormat = lib.lookupFunction<
        _FrameGetResolvedFormatNative,
        _FrameGetResolvedFormatDart>('nozzle_frame_get_resolved_format');
    _enumerateSenders = lib.lookupFunction<_EnumerateSendersNative,
        _EnumerateSendersDart>('nozzle_enumerate_senders');
    _freeSenderInfoArray = lib.lookupFunction<_FreeSenderInfoArrayNative,
        _FreeSenderInfoArrayDart>('nozzle_free_sender_info_array');
    _deviceGetDefault = lib.lookupFunction<_DeviceGetDefaultNative,
        _DeviceGetDefaultDart>('nozzle_device_get_default');
    _deviceDestroy = lib.lookupFunction<_DeviceDestroyNative,
        _DeviceDestroyDart>('nozzle_device_destroy');
    _textureWrap = lib.lookupFunction<_TextureWrapNative, _TextureWrapDart>(
        'nozzle_texture_wrap');
    _textureDestroy = lib.lookupFunction<_TextureDestroyNative,
        _TextureDestroyDart>('nozzle_texture_destroy');
    _swizzleChannels = lib.lookupFunction<_SwizzleChannelsNative,
        _SwizzleChannelsDart>('nozzle_swizzle_channels');
    _widenUint16ToUint32 = lib.lookupFunction<_WidenUint16ToUint32Native,
        _WidenUint16ToUint32Dart>('nozzle_widen_uint16_to_uint32');
    _convertUint32ToFloat32 = lib.lookupFunction<_ConvertUint32ToFloat32Native,
        _ConvertUint32ToFloat32Dart>('nozzle_convert_uint32_to_float32');
  }

  late final _SenderCreateDart _senderCreate;
  late final _SenderDestroyDart _senderDestroy;
  late final _SenderPublishTextureDart _senderPublishTexture;
  late final _SenderAcquireWritableFrameDart _senderAcquireWritableFrame;
  late final _SenderCommitFrameDart _senderCommitFrame;
  late final _SenderPublishGlTextureDart _senderPublishGlTexture;
  late final _SenderPublishNativeTextureDart _senderPublishNativeTexture;
  late final _SenderGetInfoDart _senderGetInfo;
  late final _ReceiverCreateDart _receiverCreate;
  late final _ReceiverDestroyDart _receiverDestroy;
  late final _ReceiverAcquireFrameDart _receiverAcquireFrame;
  late final _ReceiverGetConnectedInfoDart _receiverGetConnectedInfo;
  late final _FrameReleaseDart _frameRelease;
  late final _FrameGetInfoDart _frameGetInfo;
  late final _FrameLockPixelsDart _frameLockPixels;
  late final _FrameUnlockPixelsDart _frameUnlockPixels;
  late final _FrameLockWritablePixelsDart _frameLockWritablePixels;
  late final _FrameUnlockWritablePixelsDart _frameUnlockWritablePixels;
  late final _FrameCopyToGlTextureDart _frameCopyToGlTexture;
  late final _FrameCopyToNativeTextureDart _frameCopyToNativeTexture;
  late final _FrameGetResolvedFormatDart _frameGetResolvedFormat;
  late final _EnumerateSendersDart _enumerateSenders;
  late final _FreeSenderInfoArrayDart _freeSenderInfoArray;
  late final _DeviceGetDefaultDart _deviceGetDefault;
  late final _DeviceDestroyDart _deviceDestroy;
  late final _TextureWrapDart _textureWrap;
  late final _TextureDestroyDart _textureDestroy;
  late final _SwizzleChannelsDart _swizzleChannels;
  late final _WidenUint16ToUint32Dart _widenUint16ToUint32;
  late final _ConvertUint32ToFloat32Dart _convertUint32ToFloat32;

  @override
  int nozzle_sender_create(Pointer<NativeNozzleSenderDesc> desc,
          Pointer<Pointer<NozzleSender>> outSender) =>
      _senderCreate(desc, outSender);

  @override
  void nozzle_sender_destroy(NozzleSenderPtr sender) => _senderDestroy(sender);

  @override
  int nozzle_sender_publish_texture(
          NozzleSenderPtr sender, NozzleTexturePtr texture) =>
      _senderPublishTexture(sender, texture);

  @override
  int nozzle_sender_acquire_writable_frame(NozzleSenderPtr sender, int width,
          int height, int format, Pointer<Pointer<NozzleFrame>> outFrame) =>
      _senderAcquireWritableFrame(sender, width, height, format, outFrame);

  @override
  int nozzle_sender_commit_frame(
          NozzleSenderPtr sender, NozzleFramePtr frame) =>
      _senderCommitFrame(sender, frame);

  @override
  int nozzle_sender_publish_gl_texture(NozzleSenderPtr sender, int glName,
          int glTarget, int width, int height, int format) =>
      _senderPublishGlTexture(sender, glName, glTarget, width, height, format);

  @override
  int nozzle_sender_publish_native_texture(NozzleSenderPtr sender,
          Pointer<Void> nativeTexture, int width, int height, int format) =>
      _senderPublishNativeTexture(sender, nativeTexture, width, height, format);

  @override
  int nozzle_sender_get_info(NozzleSenderPtr sender,
          Pointer<NativeNozzleSenderInfo> outInfo) =>
      _senderGetInfo(sender, outInfo);

  @override
  int nozzle_receiver_create(Pointer<NativeNozzleReceiverDesc> desc,
          Pointer<Pointer<NozzleReceiver>> outReceiver) =>
      _receiverCreate(desc, outReceiver);

  @override
  void nozzle_receiver_destroy(NozzleReceiverPtr receiver) =>
      _receiverDestroy(receiver);

  @override
  int nozzle_receiver_acquire_frame(NozzleReceiverPtr receiver,
          Pointer<NativeNozzleAcquireDesc> desc,
          Pointer<Pointer<NozzleFrame>> out) =>
      _receiverAcquireFrame(receiver, desc, out);

  @override
  int nozzle_receiver_get_connected_info(NozzleReceiverPtr receiver,
          Pointer<NativeNozzleConnectedSenderInfo> outInfo) =>
      _receiverGetConnectedInfo(receiver, outInfo);

  @override
  void nozzle_frame_release(NozzleFramePtr frame) => _frameRelease(frame);

  @override
  int nozzle_frame_get_info(
          NozzleFramePtr frame, Pointer<NativeNozzleFrameInfo> outInfo) =>
      _frameGetInfo(frame, outInfo);

  @override
  int nozzle_frame_lock_pixels_with_origin(NozzleFramePtr frame, int origin,
          Pointer<NativeNozzleMappedPixels> outPixels) =>
      _frameLockPixels(frame, origin, outPixels);

  @override
  void nozzle_frame_unlock_pixels(NozzleFramePtr frame) =>
      _frameUnlockPixels(frame);

  @override
  int nozzle_frame_lock_writable_pixels_with_origin(NozzleFramePtr frame,
          int origin, Pointer<NativeNozzleMappedPixels> outPixels) =>
      _frameLockWritablePixels(frame, origin, outPixels);

  @override
  void nozzle_frame_unlock_writable_pixels(NozzleFramePtr frame) =>
      _frameUnlockWritablePixels(frame);

  @override
  int nozzle_frame_copy_to_gl_texture(NozzleFramePtr frame, int glName,
          int glTarget, int width, int height, int format) =>
      _frameCopyToGlTexture(frame, glName, glTarget, width, height, format);

  @override
  int nozzle_frame_copy_to_native_texture(NozzleFramePtr frame,
          Pointer<Void> nativeTexture, int width, int height, int format) =>
      _frameCopyToNativeTexture(frame, nativeTexture, width, height, format);

  @override
  int nozzle_frame_get_resolved_format(NozzleFramePtr frame,
          Pointer<NativeNozzleResolvedTextureFormat> outResolved) =>
      _frameGetResolvedFormat(frame, outResolved);

  @override
  int nozzle_enumerate_senders(
          Pointer<NativeNozzleSenderInfoArray> outArray) =>
      _enumerateSenders(outArray);

  @override
  void nozzle_free_sender_info_array(
          Pointer<NativeNozzleSenderInfoArray> array) =>
      _freeSenderInfoArray(array);

  @override
  int nozzle_device_get_default(Pointer<Pointer<NozzleDevice>> outDevice) =>
      _deviceGetDefault(outDevice);

  @override
  void nozzle_device_destroy(NozzleDevicePtr device) =>
      _deviceDestroy(device);

  @override
  int nozzle_texture_wrap(Pointer<NativeNozzleTextureWrapDesc> desc,
          Pointer<Pointer<NozzleTexture>> outTexture) =>
      _textureWrap(desc, outTexture);

  @override
  void nozzle_texture_destroy(NozzleTexturePtr texture) =>
      _textureDestroy(texture);

  @override
  int nozzle_swizzle_channels(Pointer<Void> src, Pointer<Void> dst, int width,
          int height, int srcRowBytes, int dstRowBytes, int format,
          Pointer<Uint8> permuteMap) =>
      _swizzleChannels(
          src, dst, width, height, srcRowBytes, dstRowBytes, format, permuteMap);

  @override
  int nozzle_widen_uint16_to_uint32(Pointer<Void> src, Pointer<Void> dst,
          int width, int height, int srcRowBytes, int dstRowBytes,
          int channels) =>
      _widenUint16ToUint32(
          src, dst, width, height, srcRowBytes, dstRowBytes, channels);

  @override
  int nozzle_convert_uint32_to_float32(Pointer<Void> src, Pointer<Void> dst,
          int width, int height, int srcRowBytes, int dstRowBytes,
          int channels) =>
      _convertUint32ToFloat32(
          src, dst, width, height, srcRowBytes, dstRowBytes, channels);
}
