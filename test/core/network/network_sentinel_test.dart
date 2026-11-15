import 'dart:async';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
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

class _MockAdapter implements HttpClientAdapter {
  final List<String> requestedPaths = [];
  bool shouldFail = false;
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestedPaths.add(options.uri.path);
    if (shouldFail) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no internet',
      );
    }
    return ResponseBody.fromString(
      '{"status":"UP"}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeConnectivity fakeConnectivity;
  late _MockAdapter adapter;
  late NetworkSentinel sentinel;

  Dio buildProbeDio() {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:5000/api/v1'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  setUp(() {
    fakeConnectivity = _FakeConnectivity();
    adapter = _MockAdapter();

    sentinel = NetworkSentinel(
      connectivity: fakeConnectivity,
      probeDio: buildProbeDio(),
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

    test('switches to offline immediately without probing when connectivity '
        'emits none', () async {
      sentinel = NetworkSentinel(
        connectivity: fakeConnectivity,
        probeDio: buildProbeDio(),
        initialStatus: NetworkStatus.online,
        syncCooldown: Duration.zero,
      );
      sentinel.initialize();

      fakeConnectivity.emit([ConnectivityResult.none]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(sentinel.isOnline, isFalse);
      expect(sentinel.status, NetworkStatus.offline);
      expect(adapter.requestedPaths, isEmpty);
    });

    test(
        'switches to online and triggers sync callbacks when interface has '
        'real internet access', () async {
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
      expect(adapter.requestedPaths, ['/api/health']);
    });

    test('stays offline when interface is up but internet is unreachable',
        () async {
      adapter.shouldFail = true;
      sentinel.initialize();

      var syncTriggeredCount = 0;
      sentinel.registerSyncCallback(() async {
        syncTriggeredCount++;
      });

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentinel.isOnline, isFalse);
      expect(sentinel.status, NetworkStatus.offline);
      expect(syncTriggeredCount, 0);
      expect(adapter.requestedPaths, ['/api/health']);
    });

    test('treats any HTTP response as online even when server errors',
        () async {
      adapter.statusCode = 503;
      sentinel.initialize();

      fakeConnectivity.emit([ConnectivityResult.wifi]);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentinel.isOnline, isTrue);
      expect(sentinel.status, NetworkStatus.online);
      expect(adapter.requestedPaths, ['/api/health']);
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

    test('checkStatus probes internet before reporting online', () async {
      fakeConnectivity.current = [ConnectivityResult.wifi];

      final status = await sentinel.checkStatus();

      expect(status, NetworkStatus.online);
      expect(adapter.requestedPaths, ['/api/health']);

      adapter.shouldFail = true;
      final offlineStatus = await sentinel.checkStatus();

      expect(offlineStatus, NetworkStatus.offline);
    });
  });
}
