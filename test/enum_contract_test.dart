import 'dart:convert';
import 'dart:io';

import 'package:nozzle/nozzle.dart';
import 'package:test/test.dart';

String normalized(String name) => name.replaceAll('_', '').toLowerCase();

void main() {
  test('public enums match the embedded C header manifest in both directions', () {
    final manifest = (jsonDecode(
      File('deps/nozzle/tools/enum_manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>);
    expect(manifest, isNotEmpty);
    final covered = <String>{};

    void check<T extends Enum>(String family, String prefix, List<T> cases,
        int Function(T) value, T Function(int) decode,
        {Map<String, String> renames = const {}}) {
      final members = Map<String, int>.from(manifest[family] as Map);
      expect(members, isNotEmpty, reason: family);
      final names = <String>{};
      for (final entry in cases) {
        // BackendType overrides .name with a display string.
        final name = EnumName(entry).name;
        final wanted = normalized(renames[name] ?? '$prefix$name');
        final matches = members.keys.where((key) => normalized(key) == wanted);
        expect(matches.length, 1, reason: '$family.$name has no unique C name');
        final cName = matches.single;
        expect(names.add(cName), isTrue, reason: 'duplicate mapping $cName');
        expect(value(entry), members[cName], reason: '$family.$name -> $cName');
        expect(decode(members[cName]!), entry,
            reason: '$family.$cName -> $name');
      }
      expect(names, members.keys.toSet(), reason: '$family missing member');
      expect(covered.add(family), isTrue);
    }

    check('NozzleErrorCode', 'NOZZLE_ERROR_', ErrorCode.values,
        (e) => e.value, ErrorCode.fromValue,
        renames: {'ok': 'NOZZLE_OK'});
    check('NozzleBackendType', 'NOZZLE_BACKEND_', BackendType.values,
        (e) => e.value, BackendType.fromValue);
    check('NozzleTextureFormat', 'NOZZLE_FORMAT_', TextureFormat.values,
        (e) => e.value, TextureFormat.fromValue);
    check('NozzleReceiveMode', 'NOZZLE_RECEIVE_', ReceiveMode.values,
        (e) => e.value, ReceiveMode.fromValue);
    check('NozzleFrameStatus', 'NOZZLE_FRAME_', FrameStatus.values,
        (e) => e.value, FrameStatus.fromValue,
        renames: {'newFrame': 'NOZZLE_FRAME_NEW'});
    check('NozzleTextureOrigin', 'NOZZLE_ORIGIN_', TextureOrigin.values,
        (e) => e.value, TextureOrigin.fromValue);
    check('NozzleTransferMode', 'NOZZLE_TRANSFER_', TransferMode.values,
        (e) => e.value, TransferMode.fromValue);
    check('NozzleSyncMode', 'NOZZLE_SYNC_', SyncMode.values,
        (e) => e.value, SyncMode.fromValue);
    check('NozzleFormatSource', 'NOZZLE_FORMAT_SOURCE_', FormatSource.values,
        (e) => e.value, FormatSource.fromValue);
    check('NozzleNativeFormatKind', 'NOZZLE_NATIVE_KIND_', NativeFormatKind.values,
        (e) => e.value, NativeFormatKind.fromValue);

    // No public Dart capability-query enums; these exact C members are unexposed.
    const unexposed = {
      'NozzleBackendSharingMechanism': [
        'NOZZLE_SHARING_NONE',
        'NOZZLE_SHARING_IOSURFACE',
        'NOZZLE_SHARING_D3D11_NT_HANDLE',
        'NOZZLE_SHARING_DMA_BUF',
        'NOZZLE_SHARING_OPENGL_TEXTURE',
      ],
      'NozzleBackendCapabilityFlags': [
        'NOZZLE_BACKEND_CAP_NONE',
        'NOZZLE_BACKEND_CAP_SENDER',
        'NOZZLE_BACKEND_CAP_RECEIVER',
        'NOZZLE_BACKEND_CAP_WRITABLE_FRAMES',
        'NOZZLE_BACKEND_CAP_NATIVE_TEXTURE_PUBLISH',
        'NOZZLE_BACKEND_CAP_DIRECT_EXTERNAL_PUBLISH',
        'NOZZLE_BACKEND_CAP_CPU_READ',
        'NOZZLE_BACKEND_CAP_CPU_WRITE',
        'NOZZLE_BACKEND_CAP_ZERO_COPY_RECEIVE',
        'NOZZLE_BACKEND_CAP_ZERO_COPY_PUBLISH',
        'NOZZLE_BACKEND_CAP_REQUIRES_MATCHING_BACKEND',
        'NOZZLE_BACKEND_CAP_SINGLE_SENDER_PER_PROCESS',
        'NOZZLE_BACKEND_CAP_MAY_REQUIRE_RUNTIME_PROBE',
      ],
      // No public Dart fallback-info category or swizzle enums.
      'NozzleFallbackCategory': [
        'NOZZLE_FALLBACK_CATEGORY_NONE',
        'NOZZLE_FALLBACK_CATEGORY_STORAGE_COMPATIBLE',
        'NOZZLE_FALLBACK_CATEGORY_CHANNEL_EXPANSION',
        'NOZZLE_FALLBACK_CATEGORY_QUALITY_LOSS',
      ],
      'NozzleChannelSwizzle': [
        'NOZZLE_CHANNEL_SWIZZLE_IDENTITY',
        'NOZZLE_CHANNEL_SWIZZLE_SWAP_RB',
      ],
    };
    for (final entry in unexposed.entries) {
      expect(covered.add(entry.key), isTrue);
      expect((manifest[entry.key] as Map).keys.toSet(), entry.value.toSet(),
          reason: '${entry.key} changed; review the unexposed list');
    }
    expect(covered, manifest.keys.toSet(), reason: 'unclassified C enum family');
  });
}
