// Tests the production FFI declaration against the compiled public C header.
// The C fill is a layout fixture, not a real getter or GPU runtime test.
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:nozzle/src/bindings.dart';
import 'package:test/test.dart';

const _modifier = 0x123456789abcdef;
const _guard = 0xa5;
const _guardSize = 16;

void main() {
  late int nativeSize;
  late int modifierOffset;
  late void Function(Pointer<Void>, int) fill;
  final dartSize = sizeOf<NativeNozzleConnectedSenderInfo>();

  setUpAll(() {
    final suffix = Platform.isWindows
        ? 'dll'
        : Platform.isMacOS
            ? 'dylib'
            : 'so';
    final path = File('.build/nozzle_info_abi.$suffix').absolute.path;
    // Missing or unloadable probes are failures, including on CI.
    final probe = DynamicLibrary.open(path);
    nativeSize = probe.lookupFunction<Uint64 Function(), int Function()>(
      'nozzle_test_connected_info_size',
    )();
    modifierOffset = probe.lookupFunction<Uint64 Function(), int Function()>(
      'nozzle_test_modifier_offset',
    )();
    fill = probe.lookupFunction<Void Function(Pointer<Void>, Uint64),
        void Function(Pointer<Void>, int)>('nozzle_test_fill_connected_info');
    stdout.writeln('CONNECTED_INFO_ABI os=${Platform.operatingSystem} '
        'abi=${Abi.current()} dart_size=$dartSize native_size=$nativeSize '
        'native_modifier_offset=$modifierOffset');
  });

  test('connected info size matches the compiled native header', () {
    expect(dartSize, nativeSize,
        reason: 'FFI allocation must cover the complete native result');
  });

  test('Dart modifier write lands at the native header offset', () {
    final size = nativeSize > dartSize ? nativeSize : dartSize;
    final storage = calloc<Uint64>((size + _guardSize + 7) ~/ 8);
    try {
      final bytes = storage.cast<Uint8>().asTypedList(size + _guardSize);
      bytes.fillRange(size, bytes.length, _guard);
      storage.cast<NativeNozzleConnectedSenderInfo>().ref.native_format_modifier =
          _modifier;
      final atNativeOffset =
          ByteData.sublistView(bytes).getUint64(modifierOffset, Endian.host);
      expect(bytes.sublist(size), everyElement(_guard));
      expect(atNativeOffset, _modifier,
          reason: 'Dart modifier storage must agree with native offsetof');
    } finally {
      calloc.free(storage);
    }
  });

  test('header-typed native fill decodes through the production FFI struct', () {
    final size = nativeSize > dartSize ? nativeSize : dartSize;
    // Allocate for both layouts, not the undersized production declaration.
    final storage = calloc<Uint64>((size + _guardSize + 7) ~/ 8);
    try {
      final bytes = storage.cast<Uint8>().asTypedList(size + _guardSize);
      bytes.fillRange(size, bytes.length, _guard);
      fill(storage.cast<Void>(), _modifier);
      final decoded = storage
          .cast<NativeNozzleConnectedSenderInfo>()
          .ref
          .native_format_modifier;
      stdout.writeln('CONNECTED_INFO_ABI fixture_modifier=$_modifier '
          'dart_decoded=$decoded');
      expect(bytes.sublist(size), everyElement(_guard),
          reason: 'Native fixture must stay inside the full backing allocation');
      expect(ByteData.sublistView(bytes).getUint64(modifierOffset, Endian.host),
          _modifier,
          reason: 'Native fixture control at the header-derived offset');
      expect(decoded, _modifier,
          reason: 'Native kind/value bytes must not be decoded as the modifier');
    } finally {
      calloc.free(storage);
    }
  });
}
