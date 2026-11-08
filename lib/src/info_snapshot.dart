import 'dart:convert';
import 'dart:ffi';

import 'bindings.dart';
import 'types.dart';

// Internal conversion surface, not exported by package:nozzle/nozzle.dart.
// Call while the complete native snapshot allocation is still alive.
String decodeSnapshotString(Array<Uint8> bytes, int capacity) {
  final owned = <int>[];
  for (var i = 0; i < capacity; i++) {
    final byte = bytes[i];
    if (byte == 0) break;
    owned.add(byte);
  }
  return utf8.decode(owned);
}

SenderInfo senderInfoFromSnapshot(NativeNozzleSenderInfoSnapshot native) {
  return SenderInfo(
    name: decodeSnapshotString(native.name, senderNameCapacity),
    applicationName:
        decodeSnapshotString(native.application_name, applicationNameCapacity),
    id: decodeSnapshotString(native.id, senderIdCapacity),
    backend: BackendType.fromValue(native.backend),
  );
}

ConnectionSnapshot connectionSnapshotFromNative(
    NativeNozzleConnectedSenderSnapshot native) {
  return ConnectionSnapshot(
    connected: native.connected != 0,
    info: ConnectedSenderInfo(
      name: decodeSnapshotString(native.name, senderNameCapacity),
      applicationName:
          decodeSnapshotString(native.application_name, applicationNameCapacity),
      id: decodeSnapshotString(native.id, senderIdCapacity),
      backend: BackendType.fromValue(native.backend),
      width: native.width,
      height: native.height,
      format: TextureFormat.fromValue(native.format),
      semanticFormat: TextureFormat.fromValue(native.semantic_format),
      estimatedFps: native.estimated_fps,
      frameCounter: native.frame_counter,
      lastUpdateTimeNs: native.last_update_time_ns,
      nativeFormatModifier: native.native_format_modifier,
    ),
  );
}
