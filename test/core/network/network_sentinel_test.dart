import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roomee/core/network/network_sentinel.dart';

class _FakeConnectivity implements Connectivity {
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();
  List<ConnectivityResult> current = [ConnectivityResult.none];

  void emit(List<ConnectivityResult> results) {
    current = results;
    _controller.add(results);
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => current;
}

void main() {
  late _FakeConnectivity fakeConnectivity;
  late NetworkSentinel sentinel;

  setUp(() {
    fakeConnectivity = _FakeConnectivity();

    sentinel = NetworkSentinel(
      connectivity: fakeConnectivity,
      initialStatus: NetworkStatus.offline,
      syncCooldown: Duration.zero,
    );
  });

  tearDown(() {
    sentinel.dispose();
  });

  group('NetworkSentinel', () {
    test('initializes and reports initial status', () {
      expect(sentinel.isOnline, isFalse);
      expect(sentinel.status, NetworkStatus.offline);
    });

    test('switches to offline immediately when connectivity emits none',
        () async {
      sentinel = NetworkSentinel(
        connectivity: fakeConnectivity,
        initialStatus: NetworkStatus.online,
      );
      sentinel.initialize();

      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sentinel.isOnline, isFalse);
      expect(sentinel.status, NetworkStatus.offline);
    });

    test(
        'switches to online and triggers sync callbacks when connectivity emits wifi',
        () async {
      sentinel.initialize();

      var syncTriggeredCount = 0;
      sentinel.registerSyncCallback(() async {
        syncTriggeredCount++;
      });

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentinel.isOnline, isTrue);
      expect(sentinel.status, NetworkStatus.online);
      expect(syncTriggeredCount, 1);
    });

    test('unregisters sync callback properly', () async {
      sentinel.initialize();

      var syncTriggeredCount = 0;
      Future<void> callback() async {
        syncTriggeredCount++;
      }

      sentinel.registerSyncCallback(callback);
      sentinel.unregisterSyncCallback(callback);

      fakeConnectivity.emit([ConnectivityResult.mobile]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentinel.isOnline, isTrue);
      expect(syncTriggeredCount, 0);
    });
  });
}
