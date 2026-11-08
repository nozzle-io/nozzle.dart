// Compiler-header ABI and synthetic conversion checks, not GPU/runtime evidence.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:nozzle/src/bindings.dart';
import 'package:nozzle/src/info_snapshot.dart';
import 'package:nozzle/src/types.dart';
import 'package:test/test.dart';

late DynamicLibrary _probe;
const _guard = 0xa5;
const _guardSize = 16;
const _name = 'camera-\u65e5\u672c\u{1f680}';
const _application = 'fixture-\u{1f680}';
const _id = '01234567-89ab-cdef-0123-456789abcdef';

int _measure(String field) => _probe
    .lookupFunction<Uint64 Function(), int Function()>('nozzle_test_$field')();

void _withStorage(String prefix, int dartSize,
    void Function(Pointer<Void>, Uint8List) body) {
  final nativeSize = _measure('${prefix}_size');
  final size = nativeSize > dartSize ? nativeSize : dartSize;
  final storage = calloc<Uint64>((size + _guardSize + 7) ~/ 8);
  try {
    final bytes = storage.cast<Uint8>().asTypedList(size + _guardSize);
    bytes.fillRange(size, bytes.length, _guard);
    body(storage.cast<Void>(), bytes);
    expect(bytes.sublist(size), everyElement(_guard));
  } finally {
    calloc.free(storage);
  }
}

void _checkBuffer(Uint8List bytes, String prefix, String field,
    Array<Uint8> buffer, int capacity, int seed) {
  expect(_measure('${prefix}_${field}_size'), capacity);
  final expected = List.generate(capacity, (i) => seed + i);
  for (var i = 0; i < capacity; i++) {
    buffer[i] = expected[i];
  }
  final offset = _measure('${prefix}_${field}_offset');
  expect(bytes.sublist(offset, offset + capacity), expected, reason: field);
}

void _checkInteger(Uint8List bytes, String prefix, String field,
    int width, int expected) {
  expect(_measure('${prefix}_${field}_size'), width);
  final offset = _measure('${prefix}_${field}_offset');
  final data = ByteData.sublistView(bytes);
  final actual = width == 4
      ? data.getUint32(offset, Endian.host)
      : data.getUint64(offset, Endian.host);
  expect(actual, expected, reason: field);
}

List<Object> _publicValues(ConnectedSenderInfo info) => [
      info.name, info.applicationName, info.id, info.backend,
      info.width, info.height, info.format, info.semanticFormat,
      info.estimatedFps, info.frameCounter, info.lastUpdateTimeNs,
      info.nativeFormatModifier,
    ];

void main() {
  setUpAll(() {
    final suffix = Platform.isWindows
        ? 'dll'
        : Platform.isMacOS ? 'dylib' : 'so';
    _probe = DynamicLibrary.open(
        File('.build/nozzle_info_abi.$suffix').absolute.path);
    stdout.writeln('SNAPSHOT_ABI abi=${Abi.current()} '
        'sender=${_measure('sender_snapshot_size')} '
        'connected=${_measure('connected_snapshot_size')}');
  });

  test('sender snapshot size capacities and field offsets match native header', () {
    const prefix = 'sender_snapshot';
    final dartSize = sizeOf<NativeNozzleSenderInfoSnapshot>();
    expect(dartSize, _measure('${prefix}_size'));
    _withStorage(prefix, dartSize, (storage, bytes) {
      final native = storage.cast<NativeNozzleSenderInfoSnapshot>().ref;
      _checkBuffer(bytes, prefix, 'name', native.name, senderNameCapacity, 17);
      _checkBuffer(bytes, prefix, 'application_name', native.application_name,
          applicationNameCapacity, 65);
      _checkBuffer(bytes, prefix, 'id', native.id, senderIdCapacity, 129);
      native.backend = 2;
      _checkInteger(bytes, prefix, 'backend', 4, 2);
    });
  });

  test('connected snapshot complete layout agrees with native header', () {
    const prefix = 'connected_snapshot';
    final dartSize = sizeOf<NativeNozzleConnectedSenderSnapshot>();
    expect(dartSize, _measure('${prefix}_size'));
    _withStorage(prefix, dartSize, (storage, bytes) {
      final native = storage.cast<NativeNozzleConnectedSenderSnapshot>().ref;
      _checkBuffer(bytes, prefix, 'name', native.name, senderNameCapacity, 17);
      _checkBuffer(bytes, prefix, 'application_name', native.application_name,
          applicationNameCapacity, 65);
      _checkBuffer(bytes, prefix, 'id', native.id, senderIdCapacity, 129);
      native
        ..connected = 7
        ..backend = 2
        ..width = 65
        ..height = 3
        ..format = 5
        ..semantic_format = 14
        ..estimated_fps = 59.9375
        ..frame_counter = 0x123456789ab
        ..last_update_time_ns = 0x23456789abc
        ..native_format_kind = 1
        ..native_format_value = 0x10203040
        ..native_format_modifier = 0x3456789abcd;
      for (final entry in {
        'connected': 7, 'backend': 2, 'width': 65, 'height': 3,
        'format': 5, 'semantic_format': 14, 'native_format_kind': 1,
        'native_format_value': 0x10203040,
      }.entries) {
        _checkInteger(bytes, prefix, entry.key, 4, entry.value);
      }
      for (final entry in {
        'frame_counter': 0x123456789ab,
        'last_update_time_ns': 0x23456789abc,
        'native_format_modifier': 0x3456789abcd,
      }.entries) {
        _checkInteger(bytes, prefix, entry.key, 8, entry.value);
      }
      expect(_measure('${prefix}_estimated_fps_size'), 8);
      expect(ByteData.sublistView(bytes).getFloat64(
          _measure('${prefix}_estimated_fps_offset'), Endian.host), 59.9375);
    });
  });

  test('bounded snapshot strings preserve strict UTF8 decoding', () {
    final storage = calloc<NativeNozzleSenderInfoSnapshot>();
    try {
      final name = storage.ref.name;
      void write(List<int> bytes) {
        for (var i = 0; i < senderNameCapacity; i++) {
          name[i] = i < bytes.length ? bytes[i] : 0;
        }
      }

      expect(decodeSnapshotString(name, senderNameCapacity), '');
      write([65, 0, 0xff]);
      expect(decodeSnapshotString(name, senderNameCapacity), 'A');
      write(utf8.encode(_name));
      expect(decodeSnapshotString(name, senderNameCapacity), _name);
      write(List.filled(senderNameCapacity, 65));
      storage.ref.application_name[0] = 66;
      expect(decodeSnapshotString(name, senderNameCapacity),
          List.filled(senderNameCapacity, 'A').join());
      write([0xff]);
      expect(() => decodeSnapshotString(name, senderNameCapacity),
          throwsFormatException);
      write([0xc3]);
      expect(() => decodeSnapshotString(name, senderNameCapacity),
          throwsFormatException);
    } finally {
      calloc.free(storage);
    }
  });

  test('synthetic header fill preserves all public values after storage is freed', () {
    late SenderInfo sender;
    late ConnectionSnapshot connected;
    late ConnectionSnapshot disconnected;
    late ConnectionSnapshot empty;
    _withStorage('sender_snapshot', sizeOf<NativeNozzleSenderInfoSnapshot>(),
        (storage, bytes) {
      _probe.lookupFunction<Void Function(Pointer<Void>),
          void Function(Pointer<Void>)>('nozzle_test_fill_sender_snapshot')(storage);
      sender = senderInfoFromSnapshot(
          storage.cast<NativeNozzleSenderInfoSnapshot>().ref);
      bytes.fillRange(0, _measure('sender_snapshot_size'), 0);
    });
    _withStorage('connected_snapshot', sizeOf<NativeNozzleConnectedSenderSnapshot>(),
        (storage, bytes) {
      _probe.lookupFunction<Void Function(Pointer<Void>),
          void Function(Pointer<Void>)>('nozzle_test_fill_connected_snapshot')(storage);
      final native = storage.cast<NativeNozzleConnectedSenderSnapshot>().ref;
      expect(native.native_format_kind, 1);
      expect(native.native_format_value, 0x10203040);
      connected = connectionSnapshotFromNative(native);
      native.connected = 0;
      disconnected = connectionSnapshotFromNative(native);
      bytes.fillRange(0, _measure('connected_snapshot_size'), 0);
      empty = connectionSnapshotFromNative(native);
    });

    expect(sender.name, _name);
    expect(sender.applicationName, _application);
    expect(sender.id, _id);
    expect(sender.backend, BackendType.metal);
    expect(connected.connected, isTrue);
    expect(disconnected.connected, isFalse);
    expect(_publicValues(connected.info), [
      _name, _application, _id, BackendType.metal, 65, 3,
      TextureFormat.bgra8Unorm, TextureFormat.rgb16Float, 59.9375,
      0x123456789ab, 0x23456789abc, 0x3456789abcd,
    ]);
    expect(_publicValues(disconnected.info), _publicValues(connected.info));
    expect(empty.connected, isFalse);
    expect(_publicValues(empty.info), [
      '', '', '', BackendType.unknown, 0, 0,
      TextureFormat.unknown, TextureFormat.unknown, 0.0, 0, 0, 0,
    ]);
  });
}
