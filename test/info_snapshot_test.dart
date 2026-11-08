// Required real-native metadata cases on macOS, including CI. Other OSes are
// excluded by the test platform selector, not reported as runtime coverage.
@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:nozzle/nozzle.dart';
import 'package:test/test.dart';

const _application = 'dart-metadata-\u65e5\u672c\u{1f680}';

String _senderName(String label) {
  final name = 'dart193-$label-$pid-${DateTime.now().microsecondsSinceEpoch}'
      '-\u65e5\u{1f680}';
  expect(utf8.encode(name).length, lessThanOrEqualTo(63));
  return name;
}

void main() {
  setUpAll(() {
    final localLibrary = File('.build/libnozzle.dylib').absolute;
    expect(localLibrary.existsSync(), isTrue,
        reason: 'Required local core dylib missing: ${localLibrary.path}');
    // loadBindings prefers this exact cwd/.build path. Do not use the existing
    // optional-library/GPU skip helpers or accept only an installed library.
    final nozzle = Nozzle.instance;
    expect(nozzle, isA<Nozzle>());
    stdout.writeln('METADATA_NATIVE library=${localLibrary.path} '
        'os=${Platform.operatingSystem}');
  });

  test('native close observes senderClosed and disconnected retained identity',
      () {
    final name = _senderName('close');
    final sender = Sender.create(SenderDesc(
      name: name,
      applicationName: _application,
    ));
    addTearDown(sender.close);
    final receiver = Receiver.create(ReceiverDesc(
      name: name,
      applicationName: 'dart-metadata-reader',
    ));
    addTearDown(receiver.close);

    final senderInfo = sender.info();
    final before = receiver.connectedInfo();
    final initialSnapshot = receiver.connectionSnapshot();
    expect(senderInfo.name, name);
    expect(senderInfo.applicationName, _application);
    expect(senderInfo.id, isNotEmpty);
    expect(senderInfo.backend, BackendType.metal);
    expect(before.name, name);
    expect(before.applicationName, _application);
    expect(before.id, senderInfo.id);
    expect(before.backend, BackendType.metal);
    expect(receiver.isConnected, isTrue);
    expect(initialSnapshot.connected, isTrue);
    expect(initialSnapshot.info.name, before.name);
    expect(initialSnapshot.info.applicationName, before.applicationName);
    expect(initialSnapshot.info.id, before.id);
    expect(initialSnapshot.info.backend, before.backend);

    // No writable frames or mappings retain the sender after close.
    sender.close();
    expect(() {
      final unexpected = receiver.acquireFrame(timeoutMs: 0);
      unexpected.release();
    }, throwsA(isA<NozzleException>().having(
        (error) => error.code, 'code', ErrorCode.senderClosed)));
    final after = receiver.connectedInfo();
    expect(after.name, before.name);
    expect(after.applicationName, before.applicationName);
    expect(after.id, before.id);
    expect(after.backend, before.backend);
    final connected = receiver.isConnected;
    stdout.writeln('METADATA_NATIVE acquire=senderClosed '
        'retained_id=${after.id} connected=$connected');
    expect(connected, isFalse);
    final disconnected = receiver.connectionSnapshot();
    expect(disconnected.connected, isFalse);
    expect(disconnected.info.name, after.name);
    expect(disconnected.info.applicationName, after.applicationName);
    expect(disconnected.info.id, after.id);
    expect(disconnected.info.backend, after.backend);
    expect(initialSnapshot.connected, isTrue);
    expect(initialSnapshot.info.id, before.id);
  });

  test('native metadata owns UTF8 values after later calls and both closes', () {
    final name = _senderName('owned');
    final sender = Sender.create(SenderDesc(
      name: name,
      applicationName: _application,
    ));
    addTearDown(sender.close);
    final receiver = Receiver.create(ReceiverDesc(
      name: name,
      applicationName: 'dart-metadata-reader',
    ));
    addTearDown(receiver.close);

    final senderInfo = sender.info();
    final connectedInfo = receiver.connectedInfo();
    final snapshot = receiver.connectionSnapshot();
    expect(sender.info().id, senderInfo.id);
    expect(receiver.connectedInfo().id, connectedInfo.id);
    receiver.close();
    sender.close();

    // Only owned Dart values are read after close, never the closed handles.
    expect(senderInfo.name, name);
    expect(senderInfo.applicationName, _application);
    expect(senderInfo.id, isNotEmpty);
    expect(senderInfo.backend, BackendType.metal);
    expect(connectedInfo.name, name);
    expect(connectedInfo.applicationName, _application);
    expect(connectedInfo.id, senderInfo.id);
    expect(connectedInfo.backend, senderInfo.backend);
    expect(snapshot.connected, isTrue);
    expect(snapshot.info.name, name);
    expect(snapshot.info.applicationName, _application);
    expect(snapshot.info.id, senderInfo.id);
    expect(snapshot.info.backend, senderInfo.backend);
    stdout.writeln('METADATA_NATIVE owned_UTF8_after_close id=${senderInfo.id}');
  });
}
