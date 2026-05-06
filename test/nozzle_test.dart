import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:test/test.dart';
import 'package:nozzle/nozzle.dart';

const testWidth = 4;
const testHeight = 4;
const testRowStrideBytes = 16; // testWidth * 4 bytes for RGBA8
const defaultTimeoutMs = 5000;

bool _canLoadLibrary() {
  try {
    final _ = Nozzle.instance;
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  final hasLib = _canLoadLibrary();
  final hasGpu = hasLib &&
      (Platform.environment['CI'] == null &&
          Platform.environment['GITHUB_ACTIONS'] == null);

  group('ErrorCode', () {
    test('values match C enum', () {
      expect(ErrorCode.ok.value, 0);
      expect(ErrorCode.unknown.value, 1);
      expect(ErrorCode.invalidArgument.value, 2);
      expect(ErrorCode.unsupportedBackend.value, 3);
      expect(ErrorCode.unsupportedFormat.value, 4);
      expect(ErrorCode.deviceMismatch.value, 5);
      expect(ErrorCode.resourceCreationFailed.value, 6);
      expect(ErrorCode.sharedHandleFailed.value, 7);
      expect(ErrorCode.senderNotFound.value, 8);
      expect(ErrorCode.senderClosed.value, 9);
      expect(ErrorCode.timeout.value, 10);
      expect(ErrorCode.backendError.value, 11);
    });

    test('fromValue returns correct enum', () {
      expect(ErrorCode.fromValue(0), ErrorCode.ok);
      expect(ErrorCode.fromValue(1), ErrorCode.unknown);
      expect(ErrorCode.fromValue(11), ErrorCode.backendError);
      expect(ErrorCode.fromValue(999), ErrorCode.unknown);
    });

    test('messages are non-empty', () {
      for (final code in ErrorCode.values) {
        expect(code.message.isNotEmpty, true,
            reason: 'ErrorCode.${code.name} has empty message');
      }
    });

    test('NozzleException has correct fields', () {
      final ex = NozzleException(ErrorCode.timeout, 'timeout');
      expect(ex.code, ErrorCode.timeout);
      expect(ex.message, 'timeout');
      expect(ex.toString(), contains('timeout'));
    });
  });

  group('BackendType', () {
    test('values match C enum', () {
      expect(BackendType.unknown.value, 0);
      expect(BackendType.d3d11.value, 1);
      expect(BackendType.metal.value, 2);
      expect(BackendType.opengl.value, 3);
      expect(BackendType.dmaBuf.value, 4);
    });

    test('name returns correct string', () {
      expect(BackendType.metal.name, 'metal');
      expect(BackendType.d3d11.name, 'd3d11');
      expect(BackendType.opengl.name, 'opengl');
      expect(BackendType.dmaBuf.name, 'dma_buf');
      expect(BackendType.unknown.name, 'unknown');
    });
  });

  group('TextureFormat', () {
    test('values match C enum', () {
      expect(TextureFormat.unknown.value, 0);
      expect(TextureFormat.r8Unorm.value, 1);
      expect(TextureFormat.depth32Float.value, 18);
    });

    test('bytesPerPixel returns correct values', () {
      expect(TextureFormat.r8Unorm.bytesPerPixel, 1);
      expect(TextureFormat.rg8Unorm.bytesPerPixel, 2);
      expect(TextureFormat.r16Unorm.bytesPerPixel, 2);
      expect(TextureFormat.r16Float.bytesPerPixel, 2);
      expect(TextureFormat.rgba8Unorm.bytesPerPixel, 4);
      expect(TextureFormat.bgra8Unorm.bytesPerPixel, 4);
      expect(TextureFormat.rgba8Srgb.bytesPerPixel, 4);
      expect(TextureFormat.bgra8Srgb.bytesPerPixel, 4);
      expect(TextureFormat.rg16Unorm.bytesPerPixel, 4);
      expect(TextureFormat.rg16Float.bytesPerPixel, 4);
      expect(TextureFormat.r32Float.bytesPerPixel, 4);
      expect(TextureFormat.r32Uint.bytesPerPixel, 4);
      expect(TextureFormat.depth32Float.bytesPerPixel, 4);
      expect(TextureFormat.rgba16Unorm.bytesPerPixel, 8);
      expect(TextureFormat.rgba16Float.bytesPerPixel, 8);
      expect(TextureFormat.rg32Float.bytesPerPixel, 8);
      expect(TextureFormat.rgba32Float.bytesPerPixel, 16);
      expect(TextureFormat.rgba32Uint.bytesPerPixel, 16);
      expect(TextureFormat.unknown.bytesPerPixel, 0);
    });
  });

  group('ReceiveMode', () {
    test('values match C enum', () {
      expect(ReceiveMode.latestOnly.value, 0);
      expect(ReceiveMode.sequentialBestEffort.value, 1);
    });
  });

  group('FrameStatus', () {
    test('values match C enum', () {
      expect(FrameStatus.newFrame.value, 0);
      expect(FrameStatus.noNew.value, 1);
      expect(FrameStatus.dropped.value, 2);
      expect(FrameStatus.senderClosed.value, 3);
      expect(FrameStatus.error.value, 4);
    });
  });

  group('TextureOrigin', () {
    test('values match C enum', () {
      expect(TextureOrigin.topLeft.value, 0);
      expect(TextureOrigin.bottomLeft.value, 1);
    });
  });

  group('FormatSource', () {
    test('values match C enum', () {
      expect(FormatSource.unknown.value, 0);
      expect(FormatSource.requested.value, 1);
      expect(FormatSource.callerHint.value, 2);
      expect(FormatSource.nativeObserved.value, 3);
    });
  });

  group('NativeFormatKind', () {
    test('values match C enum', () {
      expect(NativeFormatKind.unknown.value, 0);
      expect(NativeFormatKind.mtlPixelFormat.value, 1);
      expect(NativeFormatKind.dxgiFormat.value, 2);
      expect(NativeFormatKind.drmFourcc.value, 3);
      expect(NativeFormatKind.glInternalFormat.value, 4);
    });
  });

  group('MappedPixels', () {
    test('row returns correct slice', () {
      final data = Uint8List.fromList(List.generate(32, (i) => i));
      final mp = MappedPixels(
        data: data,
        rowStrideBytes: 8,
        width: 8,
        height: 4,
        format: TextureFormat.rgba8Unorm,
        origin: TextureOrigin.topLeft,
      );

      final row0 = mp.row(0);
      expect(row0, [0, 1, 2, 3, 4, 5, 6, 7]);

      final row3 = mp.row(3);
      expect(row3, [24, 25, 26, 27, 28, 29, 30, 31]);
    });

    test('row throws RangeError for out of bounds', () {
      final mp = MappedPixels(
        data: Uint8List(32),
        rowStrideBytes: 8,
        width: 8,
        height: 4,
        format: TextureFormat.rgba8Unorm,
        origin: TextureOrigin.topLeft,
      );

      expect(() => mp.row(4), throwsRangeError);
      expect(() => mp.row(-1), throwsRangeError);
    });

    test('unmap is no-op without FFI handle', () {
      final mp = MappedPixels(
        data: Uint8List(4),
        rowStrideBytes: 4,
        width: 1,
        height: 1,
        format: TextureFormat.rgba8Unorm,
        origin: TextureOrigin.topLeft,
      );
      mp.unmap(); // should not throw
    });
  });

  group('CPU pixel functions', () {
    test('swizzleChannels swaps R and B', () {
      final src = malloc<Uint8>(4);
      final dst = malloc<Uint8>(4);
      try {
        src[0] = 255; // R
        src[1] = 0; // G
        src[2] = 0; // B
        src[3] = 255; // A
        swizzleChannels(src.cast(), dst.cast(), 1, 1, 4, 4,
            TextureFormat.rgba8Unorm, [2, 1, 0, 3]);
        expect(dst[0], 0); // B -> channel 0
        expect(dst[1], 0); // G -> channel 1
        expect(dst[2], 255); // R -> channel 2
        expect(dst[3], 255); // A -> channel 3
      } finally {
        malloc.free(src);
        malloc.free(dst);
      }
    }, skip: !hasLib ? 'library not available' : null);

    test('widenUint16ToUint32 zero-extends', () {
      final src = malloc<Uint8>(2);
      final dst = malloc<Uint8>(4);
      try {
        src[0] = 0x34; // uint16 0x1234 little-endian
        src[1] = 0x12;
        widenUint16ToUint32(src.cast(), dst.cast(), 1, 1, 2, 4, 1);
        expect(dst[0], 0x34); // uint32 0x00001234 little-endian
        expect(dst[1], 0x12);
        expect(dst[2], 0x00);
        expect(dst[3], 0x00);
      } finally {
        malloc.free(src);
        malloc.free(dst);
      }
    }, skip: !hasLib ? 'library not available' : null);

    test('convertUint32ToFloat32 converts 42 to 42.0', () {
      final src = malloc<Uint8>(4);
      final dst = malloc<Uint8>(4);
      try {
        src[0] = 42; // uint32 42 little-endian
        src[1] = 0;
        src[2] = 0;
        src[3] = 0;
        convertUint32ToFloat32(src.cast(), dst.cast(), 1, 1, 4, 4, 1);
        // 42.0 in IEEE 754 float32 = 0x42280000
        final bytes = Uint8List(4);
        for (var i = 0; i < 4; i++) {
          bytes[i] = dst[i];
        }
        final float = ByteData.view(bytes.buffer).getFloat32(0, Endian.little);
        expect(float, closeTo(42.0, 0.001));
      } finally {
        malloc.free(src);
        malloc.free(dst);
      }
    }, skip: !hasLib ? 'library not available' : null);
  });

  group('GPU', () {
    test('sender create/destroy', () {
      final sender = Sender.create(const SenderDesc(
        name: 'dart-test-sender',
        applicationName: 'nozzle-dart-test',
      ));
      final info = sender.info();
      expect(info.name, 'dart-test-sender');
      sender.close();
    }, skip: !hasGpu ? 'GPU not available' : null);

    test('empty name fails', () {
      expect(
        () => Sender.create(const SenderDesc(
          name: '',
          applicationName: 'nozzle-dart-test',
        )),
        throwsA(isA<NozzleException>()),
      );
    }, skip: !hasLib ? 'library not available' : null);

    test('receiver create/destroy', () {
      final sender = Sender.create(const SenderDesc(
        name: 'dart-test-recv',
        applicationName: 'nozzle-dart-test',
      ));
      final receiver = Receiver.create(const ReceiverDesc(
        name: 'dart-test-recv',
        applicationName: 'nozzle-dart-test',
      ));
      receiver.close();
      sender.close();
    }, skip: !hasGpu ? 'GPU not available' : null);

    test('enumerate senders', () {
      final senders = enumerateSenders();
      expect(senders, isA<List<SenderInfo>>());
    }, skip: !hasLib ? 'library not available' : null);

    test('writable frame with pixel data', () {
      final sender = Sender.create(const SenderDesc(
        name: 'dart-test-frame',
        applicationName: 'nozzle-dart-test',
      ));
      final frame = sender.acquireWritableFrame(
          testWidth, testHeight, TextureFormat.rgba8Unorm);
      final pixels = frame.lockWritablePixels(TextureOrigin.topLeft);
      expect(pixels.width, testWidth);
      expect(pixels.height, testHeight);
      expect(pixels.rowStrideBytes, greaterThanOrEqualTo(testRowStrideBytes));
      for (var y = 0; y < pixels.height; y++) {
        final row = pixels.row(y);
        for (var i = 0; i < row.length; i++) {
          row[i] = 0xFF;
        }
      }
      pixels.unmap();
      sender.commitFrame(frame);
      sender.close();
    }, skip: !hasGpu ? 'GPU not available' : null);

    test('gpu check', () {
      expect(isGpuAvailable(), isA<bool>());
    }, skip: !hasLib ? 'library not available' : null);
  });
}
